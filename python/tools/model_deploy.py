#!/usr/bin/env python3
# ==============================================================================
#
# Copyright (C) 2022 Sophgo Technologies Inc.  All rights reserved.
#
# TPU-MLIR is licensed under the 2-Clause BSD License except for the
# third-party components.
#
# ==============================================================================

import abc
import numpy as np
import argparse
from utils.mlir_shell import *
from utils.mlir_parser import *
from utils.preprocess import preprocess, supported_customization_format
from tools.model_runner import mlir_inference, model_inference, show_fake_cmd
import pymlir


def str2list(v):
    files = v.split(',')
    files = [s.strip() for s in files]
    while files.count('') > 0:
        files.remove('')
    return files


class DeployTool:

    def __init__(self, args):
        self.mlir_file = args.mlir
        self.chip = args.chip.lower()
        self.excepts = args.excepts
        self.tolerance = args.tolerance
        self.test_input = args.test_input
        self.quantize = args.quantize.lower()
        self.asymmetric = args.asymmetric
        self.cali_table = args.calibration_table
        self.quant_input = args.quant_input
        self.quant_output = args.quant_output
        self.quantize_table = args.quantize_table
        self.model = args.model
        self.test_input = args.test_input
        self.ref_npz = args.test_reference
        self.customization_format = args.customization_format
        self.image = args.image
        self.fuse_preprocess = args.fuse_preprocess
        self.aligned_input = args.aligned_input
        self.module = MlirParser(args.mlir)
        self.module_name = self.module.module_name
        self.state = self.module.module_state
        self.disable_layer_group = args.disable_layer_group
        self.correctness = "0.99,0.90"
        if self.quantize_table:
            self.correctness = "0.99,0.85"
        self.in_f32_npz = self.module_name + "_in_f32.npz"
        self.in_f32_pre_npz = self.module_name + "_in_f32_pre.npz"
        self.prefix = "{}_{}_{}".format(
            self.module_name, self.chip, self.quantize)
        self.dynamic = args.dynamic
        if self.quantize == "int8":
            if self.asymmetric:
                self.prefix += "_asym"
            else:
                self.prefix += "_sym"
        self._prepare_input_npz()

    def lowering(self):
        self.tpu_mlir = "{}_tpu.mlir".format(self.prefix)
        self.final_mlir = "{}_final.mlir".format(self.prefix)
        mlir_lowering(self.mlir_file, self.tpu_mlir, self.quantize, self.chip, self.cali_table,
                      self.asymmetric, self.quantize_table, False, self.customization_format, self.fuse_preprocess)
        if self.do_validate:
            tool.validate_tpu_mlir()

    def _prepare_input_npz(self):
        num_inputs = len(self.test_input)
        self.do_validate = (0 < num_inputs)
        if not self.do_validate:
            return
        self.inputs = {}
        self.pre_inputs = {}
        if num_inputs == 1 and self.test_input[0].endswith(".npz"):
            x = np.load(self.test_input[0])
            for name in x.files:
                self.inputs[name] = x[name]
        else:
            assert (len(self.test_input) == len(self.module.inputs))
            for infile, op in zip(self.test_input, self.module.inputs):
                assert (infile.endswith(".npy"))
                data = np.load(infile)
                self.inputs[op.name] = data
        if self.fuse_preprocess:
            # fuse_preprocess should input origin image format
            assert (self.image[0].endswith(('.jpg', '.jpeg', '.png')))
            # module_parsered = MlirParser(self.mlir_file)
            ppa = preprocess()
            input_shapes = []
            for i in range(0, len(self.image)):
                print("Load config from {}, get the following preprocess args:".format(
                    self.mlir_file))
                input_op = self.module.inputs[i].op
                if i == 0:
                    # use the first input_op's shape as input_shapes
                    input_shapes.append(Operation.shape(input_op))
                ppa.load_config(input_op)
                config = {
                    'input_shapes': input_shapes,
                    'resize_dims': ppa.resize_dims,
                    'fuse_pre': True,
                    'keep_aspect_ratio': ppa.keep_aspect_ratio,
                    "pixel_format": ppa.pixel_format,
                    'customization_format': self.customization_format,
                    'aligned': self.aligned_input,
                    'chip': self.chip,
                }
                print("Add preprocess, set the following params:")
                ppb = preprocess()
                ppb.config(**config)
                self.pre_inputs[self.module.inputs[i].name +
                                "_raw"] = ppb.run(self.image[i])
            np.savez(self.in_f32_pre_npz, **self.pre_inputs)
        np.savez(self.in_f32_npz, **self.inputs)
        if len(self.ref_npz) == 0:
            self.ref_npz = self.module_name + "_top_outputs.npz"
            show_fake_cmd(self.in_f32_npz, self.mlir_file, self.ref_npz)
            top_outputs = mlir_inference(self.inputs, self.mlir_file)
            np.savez(self.ref_npz, **top_outputs)
        self.tpu_npz = "{}_tpu_outputs.npz".format(self.prefix)

    def validate_tpu_mlir(self):
        if self.fuse_preprocess:
            show_fake_cmd(self.in_f32_pre_npz, self.tpu_mlir, self.tpu_npz)
            tpu_outputs = mlir_inference(self.pre_inputs, self.tpu_mlir)
        else:
            show_fake_cmd(self.in_f32_npz, self.tpu_mlir, self.tpu_npz)
            tpu_outputs = mlir_inference(self.inputs, self.tpu_mlir)
        np.savez(self.tpu_npz, **tpu_outputs)
        # compare fp32 blobs and quantized tensors with tolerance similarity
        f32_blobs_compare(self.tpu_npz, self.ref_npz,
                          self.tolerance, self.excepts)

    def build_model(self):
        mlir_to_model(
            self.tpu_mlir,
            self.model,
            self.final_mlir,
            self.dynamic,
            self.quant_input,
            self.quant_output,
            self.disable_layer_group,
        )
        if self.do_validate:
            tool.validate_model()

    def validate_model(self):
        self.model_npz = "{}_model_outputs.npz".format(self.prefix)
        if self.fuse_preprocess:
            show_fake_cmd(self.in_f32_pre_npz, self.model, self.model_npz)
            model_outputs = model_inference(self.pre_inputs, self.model)
        else:
            show_fake_cmd(self.in_f32_npz, self.model, self.model_npz)
            model_outputs = model_inference(self.inputs, self.model)
        np.savez(self.model_npz, **model_outputs)
        if self.state == "TOP_QUANTIZED":
            f32_blobs_compare(self.model_npz, self.ref_npz,
                              self.correctness, self.excepts)
        else:
            f32_blobs_compare(self.model_npz, self.tpu_npz,
                              self.correctness, self.excepts)


if __name__ == '__main__':
    print("SOPHGO Toolchain {}".format(pymlir.module().version))
    parser = argparse.ArgumentParser()
    # yapf: disable
    parser.add_argument("--mlir", required=True,
                        help="optimized mlir fp32 model")
    parser.add_argument("--calibration_table",
                        help="calibration table for int8 quantization")
    parser.add_argument("--quantize_table",
                        help="table of OPs that quantized to specific mode")
    parser.add_argument("--quantize", default="F32", type=str, choices=['F32', 'BF16', 'F16', 'INT8', 'QDQ'],
                        help="set default qauntization type: F32/BF16/F16/INT8")
    parser.add_argument("--asymmetric", action='store_true',
                        help="do INT8 asymmetric quantization")
    parser.add_argument("--excepts", default='-', help="excepts")
    parser.add_argument("--tolerance", default='0.8,0.5', help="tolerance")
    parser.add_argument("--chip", required=True, type=str,
                        choices=['bm1686', 'bm1684x', 'bm1684',
                                 'cv183x', 'cv182x', 'cv181x'],
                        help="chip platform name")
    parser.add_argument("--test_input", default="", type=str2list,
                        help="input npy/npz file for inference, "
                        "if has more than one input, join npy with semicolon")
    parser.add_argument("--test_reference", default="",
                        help="reference npz file; if none, will run inner")
    parser.add_argument("--model", required=True, help='output model')
    parser.add_argument("--quant_input", action="store_true",
                        help="strip input type cast in bmodel, need outside type conversion")
    parser.add_argument("--quant_output", action="store_true",
                        help="strip output type cast in bmodel, need outside type conversion")

    parser.add_argument("--dynamic", action='store_true',
                        help="do compile dynamic")
    parser.add_argument("--customization_format", default=None, type=str,
                        choices=supported_customization_format,
                        help="pixel format of input frame to the cvimodel")
    parser.add_argument("--image", default=None, type=str2list,
                        help="origin input image file of the test_input for fuse_preprocess, "
                        "if has more than one input images, join images with semicolon")
    parser.add_argument("--fuse_preprocess", action='store_true', default=False,
                        help="add tpu preprocesses (mean/scale/channel_swap) in the front of cvimodel")
    parser.add_argument("--aligned_input", action='store_true', default=False,
                        help='if the input frame is width/channel aligned')
    parser.add_argument("--disable_layer_group", action="store_true", default=False,
                        help="Decide whether to enable layer group pass")

    # yapf: enable
    args = parser.parse_args()
    tool = DeployTool(args)
    if args.aligned_input:
        args.fuse_preprocess = True
    if args.fuse_preprocess:
        assert (args.chip.find("cv18") >= 0)
        assert (args.image is not None)
        assert (args.customization_format is not None)
    # lowering to tpu
    tool.lowering()
    # generate model
    tool.build_model()
