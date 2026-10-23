# QUANTA_2 Phase A/B Audit and Numeric Contract

Date: 2026-10-23

## Phase A: parameter audit and verified model facts

The workspace contains `manifest.json` and six CSV/MEM parameter pairs. Counts equal the manifest shapes: Conv1 weights/bias `144/16`, Conv2 `4608/32`, and FC `8000/10`. Every MEM line is exactly one two-digit hexadecimal byte. Signed two's-complement MEM decoding matches the CSV sequence for every value, and observed ranges match manifest extrema. Parameter files were not changed.

The user confirmed the original data path: torchvision MNIST `ToTensor()`, input tensor `N x 1 x 28 x 28`, float32 values in `[0,1]`, exactly `pixel_uint8 / 255.0`, with no extra normalization or target transform. The user also confirmed the model sequence: Conv2d(1,16,3,stride=1,padding=0), ReLU, MaxPool2d(2,2,0), Conv2d(16,32,3,stride=1,padding=0), ReLU, MaxPool2d(2,2,0), Flatten(start_dim=1) in NCHW order, Linear(800,10).

These facts are treated as user-confirmed. The actual PyTorch source, checkpoint, loader, and MNIST test files are still absent locally, so I could not independently inspect the source, reproduce floating-point inference, or measure accuracy. The given 98.44% is only the established floating-point baseline. Icarus Verilog, VVP, and GTKWave are available; Vivado is not. A usable Python 3.14 runtime is available via `py` (the `python` command on PATH remains broken).

## Candidate activation scales

The supplied observed ranges came from up to 100 batches and do not establish optimality or prove no outliers exist on the full test set. Symmetric INT8 activation candidates use denominator 127:

| Tensor | Candidate scale | Range used |
|---|---:|---:|
| Input pixels | `1/255 = 0.00392156862745098` | `[0,1]`, represented by unsigned source byte `p` with real value `p/255` |
| Pool1 output | `4.070276/127 = 0.03204941732283465` | observed `[0,4.070276]` |
| Pool2 output | `12.494443/127 = 0.09838144094488189` | observed `[0,12.494443]` |
| FC logits | `33.013672/127 = 0.25994938582677165` | observed `[-33.013672,17.527523]` |

Input bytes are unsigned. They are not signed INT8 activations: unsigned `p` at scale `1/255` represents `p/255` exactly in the input conversion, including `255 -> 1.0`. Conv1 consumes unsigned pixels and signed weights. Conv1/2 outputs are stored as signed INT8 in `[-127,127]` (the symmetric manifest convention); ReLU outputs are nonnegative. FC logits are signed 32-bit integer codes at the candidate logit scale and are not saturated to INT8.

## Numeric contract implemented by `reference/int_ref.py`

All manifest parameter scales are kept independent. The exact decimal spelling in the JSON manifest is parsed as a rational number by Python's `Fraction`; candidate activation scales are also represented as rational numbers. No weight or bias bytes are rewritten.

For a layer with input code scale `Sa`, weight tensor scale `Sw`, bias tensor scale `Sb`, and target activation scale `So`:

1. Decode each parameter byte as signed two's-complement. Products are signed integer products. The raw MAC accumulator has real scale `Sa*Sw`.
2. Convert a stored INT8 bias code `b` into MAC accumulator units as `round_away(b*Sb/(Sa*Sw))`, then add it to the wide signed sum. This uses the bias's own manifest scale and never reinterprets its byte as INT32. The chosen rounding is nearest, exact ties away from zero.
3. Requantize with `round_away(acc*Sa*Sw/So)`, saturate to symmetric INT8 `[-127,127]`, and apply ReLU (`max(q,0)`). Max pooling selects the maximum of the four signed activation codes. Since activation codes after ReLU are nonnegative, signed/unsigned max agree, but the reference compares signed values.
4. Conv weight indexing is `[out_channel][in_channel][kernel_row][kernel_col]`. Input and intermediate maps are channel-major, row-major, column-major, matching NCHW. Pooling is non-overlapping 2x2 with stride 2. Conv1 output is 16x26x26, Pool1 16x13x13, Conv2 32x11x11, Pool2 32x5x5; the 800 FC inputs are channel-major NCHW flatten order. FC weights are `[output_neuron][input_feature]`.
5. FC accumulation uses `Sa=S_POOL2`, `Sw=manifest FC scale`, and bias conversion as in step 2. Its integer result is rounded into the common candidate logit scale `S_LOGIT`, without INT8 saturation. Argmax compares these common-scale signed integer logits and chooses the lowest class index on ties.

The current candidate bias-to-accumulator ratios, in bias-code units per MAC unit, are approximately Conv1 `152.406`, Conv2 `8.152`, and FC `1.667`. Thus bias bytes must be converted; direct addition to raw MAC sums is incorrect. Export rounding is not recorded in the manifest, so the conventional half-LSB bias quantization error bound is conditional on round-to-nearest export.

The reference uses Python arbitrary-precision integers, so it cannot overflow. Before RTL, equivalent widths need explicit proof. Conservative pre-bias MAC magnitudes are bounded by fan-in times the maximum operand product: Conv1 `9*255*127`, Conv2 `144*127*127`, FC `800*127*127`. Converted bias bounds must be added using the selected scales. RTL will use signed widths large enough for those bounds and the conversion intermediates.

## Phase B implementation and results

Created `reference/int_ref.py`, a pure standard-library integer inference implementation, and `reference/test_int_ref.py`, helper tests for signed tie rounding, saturation, requantization/ReLU, bias conversion, and pooling. The contract intentionally treats the supplied activation scales as candidates; only helper behavior and an all-zero smoke inference have been evaluated so far.

Executed from `reference/`:

```text
py -m unittest -v test_int_ref.py
Ran 5 tests ... OK
py int_ref.py
all-zero image: logits=[-3, 5, 4, -4, -4, 2, -6, 3, -7, -3] prediction=1
all-maximum image (all pixels 255): logits=[-10, -23, -30, -34, -7, -59, 5, -43, -9, -50] prediction=6
repeated all-zero inference: identical logits and prediction
```

No MNIST image files, checkpoint, or PyTorch model are available in the workspace. Quantized accuracy, prediction agreement, and bias-induced accuracy loss therefore remain unmeasured; the integer reference must not be described as validated against PyTorch. The next useful step is to supply the original model/checkpoint and MNIST test set (or export representative calibrated image tensors/logits) so candidate scales and INT8 bias effects can be evaluated. Only after that comparison should RTL be implemented.
