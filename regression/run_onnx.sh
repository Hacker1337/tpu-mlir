#!/bin/bash
set -ex

INPUT=../resnet18_in_f32_b4.npz
mkdir -p tmp
pushd tmp
model_transform.py \
    --model_type onnx \
    --model_name resnet18 \
    --input_shapes [[4,3,224,224]] \
    --model_def  ../resnet18.onnx \
    --input $INPUT \
    --mlir resnet18.mlir

# do calibration
mkdir -p dataset
cp $INPUT dataset/
run_calibration.py resnet18.mlir \
    --dataset dataset \
    --input_num 1 \
    -o resnet18_cali_table

#########################
# BM1684
#########################
# convert to f32
sophgo-opt resnet18.mlir \
    --lowering="mode=F32 chip=bm1684" \
    --save-weight \
    -o resnet18_f32_1684.mlir

model_runner.py \
    --model resnet18_f32_1684.mlir \
    --input $INPUT \
    --dump_all_tensors \
    --output resnet18_f32_outputs_1684.npz

npz_tool.py compare \
    resnet18_f32_outputs_1684.npz \
    resnet18_ref_outputs.npz \
    --tolerance 0.99,0.99 -v

# import calibration
sophgo-opt resnet18.mlir \
    --import-calibration-table='file=resnet18_cali_table asymmetric=false' \
    --save-weight \
    -o resnet18_cali_1684.mlir

# quantize mlir
sophgo-opt resnet18_cali_1684.mlir \
    --lowering="mode=INT8 asymmetric=false chip=bm1684" \
    --save-weight \
    -o resnet18_int8_1684.mlir

model_runner.py \
    --model resnet18_int8_1684.mlir \
    --input $INPUT \
    --dump_all_tensors \
    --output resnet18_int8_outputs_1684.npz

npz_tool.py compare \
    resnet18_int8_outputs_1684.npz \
    resnet18_ref_outputs.npz \
    --tolerance 0.85,0.42 -v

sophgo-opt resnet18_int8_1684.mlir \
    --weight-reorder \
    --subnet-divide \
    --address-asign \
    --save-weight \
    --codegen="model_file=resnet18_int8_1684.bmodel" \
    -o resnet18_int8_addr_1684.mlir

#########################
# BM1686
#########################
# convert f32
sophgo-opt resnet18.mlir \
    '--lowering=mode=F32 chip=bm1686' \
    --save-weight \
    -o resnet18_f32_1686.mlir

model_runner.py \
    --model resnet18_f32_1686.mlir \
    --input $INPUT \
    --dump_all_tensors \
    --output resnet18_f32_outputs_1686.npz

npz_tool.py compare \
    resnet18_f32_outputs_1686.npz \
    resnet18_ref_outputs.npz \
    --tolerance 0.99,0.99 -v

sophgo-opt resnet18_f32_1686.mlir \
    --weight-reorder \
    --subnet-divide \
    --address-asign \
    --save-weight \
    --codegen="model_file=resnet18_f32_1686.bmodel" \
    -o resnet18_f32_addr_1686.mlir

# convert to int8
sophgo-opt resnet18.mlir \
    --import-calibration-table='file=resnet18_cali_table asymmetric=true' \
    --save-weight \
    -o resnet18_cali_1686.mlir

# quantize mlir for 1686 asymmetric
sophgo-opt resnet18_cali_1686.mlir \
    --lowering="mode=INT8 asymmetric=true chip=bm1686" \
    --save-weight \
    -o resnet18_int8_1686.mlir

model_runner.py \
    --model resnet18_int8_1686.mlir \
    --input $INPUT \
    --dump_all_tensors \
    --output resnet18_int8_outputs_1686.npz

npz_tool.py compare \
    resnet18_int8_outputs_1686.npz \
    resnet18_ref_outputs.npz \
    --tolerance 0.90,0.54 -v

# with layer-group
sophgo-opt resnet18_int8_1686.mlir \
    --weight-reorder \
    --subnet-divide \
    --layer-group \
    --address-asign \
    --save-weight \
    --codegen="model_file=resnet18_int8_1686_lg.bmodel" \
    -o resnet18_int8_lg_1686.mlir

# no layer-group
sophgo-opt resnet18_int8_1686.mlir \
    --weight-reorder \
    --subnet-divide \
    --address-asign \
    --save-weight \
    --codegen="model_file=resnet18_int8_1686.bmodel" \
    -o resnet18_int8_addr_1686.mlir

popd
