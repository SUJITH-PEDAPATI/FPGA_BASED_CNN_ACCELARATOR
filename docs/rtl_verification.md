# QUANTA_2 RTL Verification Report

Date: 2026-10-23
Simulator: Icarus Verilog (iverilog + vvp, -g2001)
Result: 5 / 5 PASS

---

## Architecture Verified

Layer          | Module           | Parameters
---------------|------------------|------------------------------------------
Input buffer   | cnn_top internal | 784 x uint8
Conv1          | conv_layer       | IN=1x28x28, OUT=16x26x26, 3x3, MULT=201, SHIFT=18
Pool1          | cnn_top T_POOL1  | 16x26x26 -> 16x13x13, 2x2 max
Conv2          | conv_layer       | IN=16x13x13, OUT=32x11x11, 3x3, MULT=2637, SHIFT=21
Pool2          | cnn_top T_POOL2  | 32x11x11 -> 32x5x5, 2x2 max
FC             | fully_connected  | IN=800, OUT=10, MULT=1965, SHIFT=21
Argmax         | argmax           | 10-class, lowest-index tie-break

---

## Test Results

Test | Image              | RTL Logits                                  | Pred | Status
-----|--------------------|---------------------------------------------|------|-------
1    | all-zero           | [-3,5,4,-4,-4,2,-6,3,-7,-3]                | 1    | PASS
2    | all-max (255)      | [-10,-23,-30,-34,-6,-59,5,-43,-9,-50]       | 6    | PASS
3    | random seed=42     | [-19,-42,-11,-14,-25,-42,-14,-43,7,-43]     | 8    | PASS
4    | all-127            | [-5,-10,-16,-19,-2,-31,3,-22,-5,-26]        | 6    | PASS
5    | consecutive zero   | [-3,5,4,-4,-4,2,-6,3,-7,-3]                | 1    | PASS

NOTE: Tests 2 and 4 logits differ by +-1 from the exact rational reference for some
channels. This is inherent to the fixed-point MULT/SHIFT approximation (max error
< 0.5 LSB per element at quantization output, accumulates < +-1.5 at logit scale).
All PREDICTIONS match the rational reference.

---

## Bugs Found and Fixed During Verification

### Bug 1: Testbench pixel-loading off-by-one (tb/tb_cnn_top.v)

Root cause: The run_cur_image task iterated j=1..783 and set pixel_i = cur_img[j]
at the negedge, but the DUT sampled pixel_i one posedge later. This caused
img_buf[k+1] = cur_img[k] (duplicated pixel 0, missed pixel 783) for non-uniform images.

Fix: Changed loop to j=2..783 and explicitly set pixel_i = cur_img[1] before the
loop, so each negedge value is sampled at the correct subsequent posedge.

### Bug 2: Non-blocking assignment timing in S_IDLE (conv_layer + fully_connected)

Root cause: In S_IDLE on start_i=1, both modules executed:
    r_oc <= 0;          // non-blocking: r_oc not yet 0 at RHS evaluation
    acc  <= bias_cur;   // reads bias_a[r_oc] with OLD r_oc!

After the first inference, r_oc holds its final value (15 for Conv1, 9 for FC).
The second inference started with the wrong channel bias in the accumulator,
corrupting the first output pixel of every subsequent run.

Fix: Replaced acc <= bias_cur with acc <= {{...bias_a[0]...}} in S_IDLE, explicitly
loading channel-0 bias since r_oc is always being reset to 0.

### Bug 3: Tab character in quantization.v header

Root cause: PowerShell Set-Content prepended a tab before `timescale, causing an
iverilog syntax error at line 1.

Fix: Rewrote the file using [System.IO.File]::WriteAllText() with explicit UTF-8
no-BOM encoding.

### Bug 4: VCD path mismatch

Root cause: $dumpfile("sim/waves.vcd") was relative to the VVP launch directory
(already sim/), causing a path error.

Fix: Changed to $dumpfile("waves.vcd").

---

## Numeric Error Analysis

Layer       | MULT/SHIFT approx error (max) | Effect at logit
------------|-------------------------------|------------------------
Conv1 quant | <0.28 LSB per output pixel    | cascades Conv2 -> FC
Conv2 quant | <0.24 LSB per output pixel    | cascades to FC
FC quant    | <0.15 LSB per logit           | <=+-1 logit unit total

Observed logit error vs. exact rational: 0 or +-1 unit across all 5 test vectors.
All 5 predictions match the rational floating-point reference.

---

## Waveform

Generated: sim/waves.vcd
Open with: gtkwave sim/waves.vcd

Key signals: state, c1_done, c2_done, fc_done, done_o, prediction_o, logit0_o..logit9_o

---

## File Manifest

File                           | Role
-------------------------------|----------------------------------------------
rtl/cnn_top.v                  | Top-level integration + master FSM
rtl/conv_layer.v               | Sequential 3x3 conv, write-port interface
rtl/fully_connected.v          | Sequential FC layer, write-port interface
rtl/quantization.v             | Round-nearest MULT/SHIFT requantizer
rtl/relu.v                     | Parameterized signed ReLU
rtl/maxpool.v                  | 2x2 max-pool window
rtl/argmax.v                   | 10-class signed argmax
tb/tb_cnn_top.v                | System testbench, 5 test vectors
sim/run_sim.bat                | Compile + simulate script
params/conv1_bias_acc.mem      | Conv1 bias in accumulator units (16 entries, 20-bit)
params/conv2_bias_acc.mem      | Conv2 bias in accumulator units (32 entries, 16-bit)
params/fc_bias_acc.mem         | FC bias in accumulator units (10 entries, 12-bit)
params/img_rnd42.mem           | Random test image (Python random.seed(42))
reference/rtl_emulator.py      | Bit-exact Python RTL emulator
reference/int_ref.py           | Exact rational reference implementation
docs/numeric_contract.md       | Quantization parameters and scale derivation
docs/rtl_verification.md       | This document
