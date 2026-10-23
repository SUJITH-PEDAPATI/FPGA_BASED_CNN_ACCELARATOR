# QUANTA_2 RTL Numeric Contract

Date: 2026-10-23

## Summary of Layer Parameters

| Layer      | In Scale (Sa)      | Weight Scale (Sw)  | Bias Scale (Sb)    | Out Scale (So)     |
|------------|--------------------|--------------------|--------------------|--------------------|
| Conv1      | 1/255              | 0.006273853497...  | 0.003749847646...  | 4.070276/127       |
| Conv2      | 4.070276/127       | 0.003860192740...  | 0.001009500402...  | 12.494443/127      |
| FC         | 12.494443/127      | 0.002475735240...  | 0.000405684993...  | 33.013672/127      |

Scales are parsed as exact rationals (Python Fraction(str(...))); see manifest.json.

## Requantization Parameters

| Layer | RQUANT_MULT | RQUANT_SHIFT | Max error at max acc |
|-------|-------------|--------------|----------------------|
| Conv1 |         201 |           18 |               ~0.284 |
| Conv2 |        2637 |           21 |               ~0.240 |
| FC    |        1965 |           21 |               ~0.150 |

All < 0.5 LSB.  Errors measured against exact rational computation at worst-case accumulator.

## Accumulator Widths

| Layer | Max MAC before bias | Width needed |
|-------|--------------------:|:-------------|
| Conv1 | 9 x 255 x 127 = 291465 | 20-bit signed |
| Conv2 | 144 x 127 x 127 = 2,322,576 | 23-bit signed |
| FC    | 800 x 127 x 127 = 12,903,200 | 25-bit signed |

RTL uses 32-bit signed accumulators throughout (comfortable margin).

## Bias Conversion

Bias bytes are stored in INT8 at each layer's own Sb scale.
Conversion to accumulator units: bias_acc = round_away(b_code * Sb / (Sa * Sw))
This is precomputed in Python (reference/int_ref.py) and stored in:
- params/conv1_bias_acc.mem  (20-bit signed, 16 entries)
- params/conv2_bias_acc.mem  (16-bit signed, 32 entries)
- params/fc_bias_acc.mem     (12-bit signed, 10 entries)

The RTL loads these precomputed values with $readmemh.

## Activation Scales

Candidate scales based on observed floating-point ranges (not proven optimal):
- Pool1 output: 4.070276/127  (range measured 0..4.070276 over some batches)
- Pool2 output: 12.494443/127 (range measured 0..12.494443)
- FC logits:    33.013672/127 (range measured -33.01..17.53)

These are candidates.  If the actual network has activations outside these
ranges, clipping will occur and accuracy will degrade.  A full calibration
over the MNIST test set is required to confirm scale quality.

## Input Handling

Input pixels are UNSIGNED 8-bit (0-255), representing float value p/255.
In Conv1, the pixel byte is ZERO-EXTENDED to 9 bits before multiplying by
the signed INT8 weight.  This correctly represents the positive-only input
range while allowing the weight to be signed.

## Saturation and ReLU

- Convolution output: saturation to [-127, 127] then ReLU (max(q, 0))
- FC output logits: NO saturation, NO ReLU. 32-bit signed result.

## Rounding

All rounding is round-nearest, ties-away-from-zero, implemented via:
  round = (acc * MULT + 2^(SHIFT-1)) >> SHIFT

## Max Pooling

2x2, stride 2, no padding.  Non-overlapping windows.  Signed comparison.
After ReLU all activations are non-negative, so signed/unsigned max agree,
but the RTL compares as signed for correctness in all cases.

## Argmax

Strictly-greater-than scan: running max updated only when new value > current.
This gives lowest-class-index win on ties, matching the Python reference.

## Flatten Order

Pool2 output (32x5x5) is stored in channel-major (NCHW-flat) order:
  index = (channel * 5 + row) * 5 + col
This matches PyTorch Flatten(start_dim=1) on NCHW tensors.
