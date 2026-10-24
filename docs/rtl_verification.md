# QUANTA_2 — RTL Numerical Verification Contract
**Date:** 2026-10-24  
**Status:** Verified against rtl_emulator.py and Icarus simulation

---

## 1. Input Pixel Representation

- Format: unsigned 8-bit integer (uint8), range [0, 255]
- Source file: `test/image_input.mem` — one hex byte per line (e.g., `00`, `FE`)
- Pixel layout: row-major, left-to-right, top-to-bottom (28 rows × 28 cols = 784 total)
- In RTL: loaded into `img_buf[0:783]` as `reg [7:0]`
- In Conv1: zero-extended to 9 bits: `in_ext = {1'b0, pixel}` (FIRST_LAYER=1 parameter)
- Unsigned pixels are NOT sign-extended — this is intentional to represent [0, 255]

## 2. Weight Representation

All weights are signed INT8, two's-complement, stored as 2-digit hex per line.

| Layer | File | Count | Shape |
|-------|------|-------|-------|
| Conv1 | `conv1_weights_int.mem` | 144 | [16, 1, 3, 3] |
| Conv2 | `conv2_weights_int.mem` | 4608 | [32, 16, 3, 3] |
| FC | `fc1_weights_int.mem` | 8000 | [10, 800] |

**Weight index formula** (conv_layer.v):
```
widx = (r_oc * IN_CH + r_ic) * 9 + r_ky * 3 + r_kx
```
This is `[out_channel][in_channel][kernel_row][kernel_col]` — matches PyTorch OIHW.

**FC weight index:**
```
widx = r_oc * IN_FEATURES + r_i   (i.e., [out_neuron][in_feature])
```

## 3. Bias Representation (Accumulator-Domain)

Biases are stored pre-scaled into the accumulator integer domain.  
They are NOT raw INT8 weights — they are wider integers.

| Layer | File | Count | Width (bits) |
|-------|------|-------|-------------|
| Conv1 | `params/conv1_bias_acc.mem` | 16 | 20 |
| Conv2 | `params/conv2_bias_acc.mem` | 32 | 16 |
| FC | `params/fc_bias_acc.mem` | 10 | 12 |

In RTL, these are sign-extended to 32 bits and used directly as the initial accumulator value:
```verilog
acc <= {{(32-BIAS_WIDTH){bias_a[0][BIAS_WIDTH-1]}}, bias_a[0]};
```

> **Do NOT confuse** `params/conv1_bias_acc.mem` (20-bit, used by RTL) with  
> `conv1_bias_int.mem` (8-bit, used by `int_ref.py`). They are different representations.

## 4. Accumulator

- Width: 32 bits, signed
- Initialized to: sign-extended bias value for each output channel
- Accumulated: `acc += in_ext * weight[widx]`  (17-bit product, added to 32-bit acc)
- Maximum magnitude (Conv1): `19356 + 9 * 255 * 127 = 19356 + 290,835 = 310,191` — fits in 32-bit

## 5. Requantization

After all taps are accumulated for one output pixel:

```
product_rounded = (acc * MULT) + (1 << (SHIFT-1))
shifted         = product_rounded >>> SHIFT    (arithmetic right shift)
sat_val         = clamp(shifted, -127, 127)
q_out           = RELU ? max(sat_val, 0) : sat_val
```

Parameters per layer:

| Layer | MULT | SHIFT | RELU |
|-------|------|-------|------|
| Conv1 | 201 | 18 | Yes |
| Conv2 | 2637 | 21 | Yes |
| FC | 1965 | 21 | No (logits not clamped) |

The MULT/SHIFT pair implements a fixed-point approximation of the float requantization scale:
- Conv1: `201 / 2^18 ≈ 7.629e-4` 
- Conv2: `2637 / 2^21 ≈ 1.258e-3`
- FC: `1965 / 2^21 ≈ 9.37e-4`

## 6. Activation Representation

All intermediate activations stored as signed INT8 [-127, 127].
After ReLU, activations are in [0, 127].
Max pooling compares signed INT8 values.

## 7. FC Output (Logits)

FC layer computes raw 32-bit signed integer logits — no saturation, no ReLU.  
The requantization MULT/SHIFT still applies (scales the logit), but the result is stored as a full 32-bit signed integer.

## 8. Tensor Layout / Flatten Order

All activation tensors are channel-major (NCHW) stored in a 1-D array:

```
index = (channel * height + row) * width + col
```

Pool2 output (32×5×5 = 800) is flattened in this same NCHW order into FC input.

This matches PyTorch's default `Flatten(start_dim=1)` on a NCHW tensor.

## 9. Argmax

```verilog
// Lowest class index wins on ties
prediction = argmax(logits[0:9])
```

Implemented combinationally in `rtl/argmax.v`.

## 10. Reference Implementations

### `reference/rtl_emulator.py` — RTL mirror (USE FOR RTL VALIDATION)

Mirrors the Verilog fixed-point arithmetic exactly using Python integer arithmetic.  
Same MULT/SHIFT parameters, same bias representation, same index formulas.  
Produces identical results to RTL for all tested images.

**Verified results on `test/image_input.mem` (MNIST label=7):**
```python
logits = [-21, -21, 2, -1, -46, -33, -77, 49, -30, -8]
prediction = 7  ✅ CORRECT
```

### `reference/int_ref.py` — Float-scale study (NOT for RTL bit-exact comparison)

Uses manifest floating-point scales as Python `Fraction` objects.  
Different bias arithmetic (converts INT8 bias through float scales).  
Produces slightly different logits for some images (e.g., logit[2]=3 vs RTL's 2).  
Cannot be used to validate RTL bit-exact correctness.

---

## 11. Verified RTL Behavior

### Test image: `test/image_input.mem` (MNIST index 0, label=7)

| Check | Result |
|-------|--------|
| Image loaded correctly | ✅ 784 pixels, first=0x00, last=0x00 |
| Conv1 weights loaded | ✅ weights[0]=0xDA, bias_a[0]=0x04B9C |
| Conv1 completed | ✅ after ~108,160 cycles |
| Pool1 correct | ✅ (verified via logit match) |
| Conv2 completed | ✅ after ~423,776 more cycles |
| Pool2 correct | ✅ |
| FC completed | ✅ after ~8,010 more cycles |
| Total cycles | ✅ 677,624 = 6,784,240 ns |
| Predicted digit | ✅ 7 (correct) |
| Logit[7] = 49 | ✅ (clear argmax winner) |
| All 10 logits match `rtl_emulator.py` | ✅ bit-exact |

### Conv1 all-zero image (unit test, verified separately)

```
c1_act[0]    (oc=0, oy=0, ox=0) = 15
c1_act[676]  (oc=1, oy=0, ox=0) =  4
c1_act[1352] (oc=2, oy=0, ox=0) =  0
(13 remaining channels follow expected pattern)
```

---

## 12. Unresolved Items

1. **Multi-image accuracy** — only one MNIST image verified. Batch testing not performed.
2. **int_ref.py discrepancy** — logit[2] differs by 1 from RTL. Root cause is different bias arithmetic contract. Not a bug in RTL; int_ref uses float manifest scales.
3. **Synthesis** — not attempted. This report covers behavioral simulation only.
4. **FPGA hardware** — not deployed. Simulation ≠ hardware success.
