// RUN: tpuc-opt --core-parallel -split-input-file %s

// CHECK-LABEL: module @Conv2d_2
// CHECK:        %[[CONV0:.*]] = "tpu.Conv2D"(%[[InputSplit:.*]]#0, %[[FilterSplit:.*]]#0, %[[BiasSplit:.*]]#0) {coeff_merged = false, dilations = [1, 1], do_relu = false, dynweight_reorderd = false, group = 1 : i64, kernel_shape = [3, 3], kernel_zp = 0 : i64, pads = [1, 1, 1, 1], quant_mode = #tpu<rq_mode MultiplierShift>, relu_limit = -1.000000e+00 : f64, strides = [1, 1], use_3ic_optimize = 0 : i64, weight_is_coeff = 1 : i64, with_bias = true} : (tensor<1x16x100x100xf32>, tensor<1x33x16x9xf32>, tensor<1x33x1x1xf32>) -> tensor<1x33x100x100xf32> loc({{.*}})
// CHECK:        %[[CONV1:.*]] = "tpu.Conv2D"(%[[InputSplit]]#0, %[[FilterSplit]]#1, %[[BiasSplit]]#1) {coeff_merged = false, dilations = [1, 1], do_relu = false, dynweight_reorderd = false, group = 1 : i64, kernel_shape = [3, 3], kernel_zp = 0 : i64, pads = [1, 1, 1, 1], quant_mode = #tpu<rq_mode MultiplierShift>, relu_limit = -1.000000e+00 : f64, strides = [1, 1], use_3ic_optimize = 0 : i64, weight_is_coeff = 1 : i64, with_bias = true} : (tensor<1x16x100x100xf32>, tensor<1x32x16x9xf32>, tensor<1x32x1x1xf32>) -> tensor<1x32x100x100xf32> loc({{.*}})
// CHECK:        %[[CONV2:.*]] = "tpu.Conv2D"(%[[InputSplit]]#1, %[[FilterSplit]]#0, %[[BiasSplit]]#0) {coeff_merged = false, dilations = [1, 1], do_relu = false, dynweight_reorderd = false, group = 1 : i64, kernel_shape = [3, 3], kernel_zp = 0 : i64, pads = [1, 1, 1, 1], quant_mode = #tpu<rq_mode MultiplierShift>, relu_limit = -1.000000e+00 : f64, strides = [1, 1], use_3ic_optimize = 0 : i64, weight_is_coeff = 1 : i64, with_bias = true} : (tensor<1x16x100x100xf32>, tensor<1x33x16x9xf32>, tensor<1x33x1x1xf32>) -> tensor<1x33x100x100xf32> loc({{.*}})
// CHECK:        %[[CONV3:.*]] = "tpu.Conv2D"(%[[InputSplit]]#1, %[[FilterSplit]]#1, %[[BiasSplit]]#1) {coeff_merged = false, dilations = [1, 1], do_relu = false, dynweight_reorderd = false, group = 1 : i64, kernel_shape = [3, 3], kernel_zp = 0 : i64, pads = [1, 1, 1, 1], quant_mode = #tpu<rq_mode MultiplierShift>, relu_limit = -1.000000e+00 : f64, strides = [1, 1], use_3ic_optimize = 0 : i64, weight_is_coeff = 1 : i64, with_bias = true} : (tensor<1x16x100x100xf32>, tensor<1x32x16x9xf32>, tensor<1x32x1x1xf32>) -> tensor<1x32x100x100xf32> loc({{.*}})
// CHECK:        %[[CONV4:.*]] = "tpu.Conv2D"(%[[InputSplit]]#2, %[[FilterSplit]]#0, %[[BiasSplit]]#0) {coeff_merged = false, dilations = [1, 1], do_relu = false, dynweight_reorderd = false, group = 1 : i64, kernel_shape = [3, 3], kernel_zp = 0 : i64, pads = [1, 1, 1, 1], quant_mode = #tpu<rq_mode MultiplierShift>, relu_limit = -1.000000e+00 : f64, strides = [1, 1], use_3ic_optimize = 0 : i64, weight_is_coeff = 1 : i64, with_bias = true} : (tensor<1x16x100x100xf32>, tensor<1x33x16x9xf32>, tensor<1x33x1x1xf32>) -> tensor<1x33x100x100xf32> loc({{.*}})
// CHECK:        %[[CONV5:.*]] = "tpu.Conv2D"(%[[InputSplit]]#2, %[[FilterSplit]]#1, %[[BiasSplit]]#1) {coeff_merged = false, dilations = [1, 1], do_relu = false, dynweight_reorderd = false, group = 1 : i64, kernel_shape = [3, 3], kernel_zp = 0 : i64, pads = [1, 1, 1, 1], quant_mode = #tpu<rq_mode MultiplierShift>, relu_limit = -1.000000e+00 : f64, strides = [1, 1], use_3ic_optimize = 0 : i64, weight_is_coeff = 1 : i64, with_bias = true} : (tensor<1x16x100x100xf32>, tensor<1x32x16x9xf32>, tensor<1x32x1x1xf32>) -> tensor<1x32x100x100xf32> loc({{.*}})
// CHECK:        %[[CONV6:.*]] = "tpu.Conv2D"(%[[InputSplit]]#3, %[[FilterSplit]]#0, %[[BiasSplit]]#0) {coeff_merged = false, dilations = [1, 1], do_relu = false, dynweight_reorderd = false, group = 1 : i64, kernel_shape = [3, 3], kernel_zp = 0 : i64, pads = [1, 1, 1, 1], quant_mode = #tpu<rq_mode MultiplierShift>, relu_limit = -1.000000e+00 : f64, strides = [1, 1], use_3ic_optimize = 0 : i64, weight_is_coeff = 1 : i64, with_bias = true} : (tensor<1x16x100x100xf32>, tensor<1x33x16x9xf32>, tensor<1x33x1x1xf32>) -> tensor<1x33x100x100xf32> loc({{.*}})
// CHECK:        %[[CONV7:.*]] = "tpu.Conv2D"(%[[InputSplit]]#3, %[[FilterSplit]]#1, %[[BiasSplit]]#1) {coeff_merged = false, dilations = [1, 1], do_relu = false, dynweight_reorderd = false, group = 1 : i64, kernel_shape = [3, 3], kernel_zp = 0 : i64, pads = [1, 1, 1, 1], quant_mode = #tpu<rq_mode MultiplierShift>, relu_limit = -1.000000e+00 : f64, strides = [1, 1], use_3ic_optimize = 0 : i64, weight_is_coeff = 1 : i64, with_bias = true} : (tensor<1x16x100x100xf32>, tensor<1x32x16x9xf32>, tensor<1x32x1x1xf32>) -> tensor<1x32x100x100xf32> loc({{.*}})
// CHECK:        %[[JOIN:.*]] = "tpu.Join"(%[[CONV0]], %[[CONV1]], %[[CONV2]], %[[CONV3]], %[[CONV4]], %[[CONV5]], %[[CONV6]], %[[CONV7]]) : (tensor<1x33x100x100xf32>, tensor<1x32x100x100xf32>, tensor<1x33x100x100xf32>, tensor<1x32x100x100xf32>, tensor<1x33x100x100xf32>, tensor<1x32x100x100xf32>, tensor<1x33x100x100xf32>, tensor<1x32x100x100xf32>) -> tensor<4x65x100x100xf32, 687197327360 : i64> loc({{.*}})
#loc = loc(unknown)
module @Conv2d_2 attributes {module.FLOPs = 751400000 : i64, module.asymmetric = false, module.chip = "bm1688", module.cores = 8 : i64, module.devices = 1 : i64, module.inputs = ["input"], module.mode = "F32", module.outputs = ["output_Conv"], module.platform = "ONNX", module.q_group_size = 0 : i64, module.state = "TPU_ADDRESSED", module.weight_file = "conv2d_2_tpu_addressed_bm1688_f32_weight.npz"} {
  module @Conv2d_2 attributes {module.coeff_addr = 618475290624 : i64, module.coeff_size = 45056 : i64, module.device_id = 0 : i64, module.neuron_addr = 687194767360 : i64, module.neuron_size = 12963840 : i64, module.step = 0 : i64} {
    func.func @_0(%arg0: tensor<4x16x100x100xf32, 687194767360 : i64> loc("input")) -> tensor<4x65x100x100xf32, 687197327360 : i64> attributes {id = 0 : i64, mode = #tpu<run_mode TPU_STATIC>, next_index = array<i32: -1>} {
      %0 = "top.Weight"() : () -> tensor<1x65x16x9xf32, 618475290624 : i64> loc(#loc2)
      %1 = "top.Weight"() : () -> tensor<1x65x1x1xf32, 618475331584 : i64> loc(#loc3)
      %2 = "tpu.Conv2D"(%arg0, %0, %1) {coeff_merged = false, dilations = [1, 1], do_relu = false, dynweight_reorderd = false, group = 1 : i64, kernel_shape = [3, 3], kernel_zp = 0 : i64, pads = [1, 1, 1, 1], quant_mode = #tpu<rq_mode MultiplierShift>, relu_limit = -1.000000e+00 : f64, strides = [1, 1], use_3ic_optimize = 0 : i64, weight_is_coeff = 1 : i64, with_bias = true} : (tensor<4x16x100x100xf32, 687194767360 : i64>, tensor<1x65x16x9xf32, 618475290624 : i64>, tensor<1x65x1x1xf32, 618475331584 : i64>) -> tensor<4x65x100x100xf32, 687197327360 : i64> loc(#loc4)
      return %2 : tensor<4x65x100x100xf32, 687197327360 : i64> loc(#loc)
    } loc(#loc)
  } loc(#loc)
} loc(#loc)
#loc2 = loc("weight")
#loc3 = loc("bias")
#loc4 = loc("output_Conv")
