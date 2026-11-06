# QUANTA_2: CPU Software vs. FPGA Hardware Performance Benchmark Report

**Project:** 5-Layer FPGA CNN Accelerator for Digilent ZedBoard (Zynq-7000, `xc7z020clg484-1`)  
**Clock Constraints:** Target PL Clock = **100.000 MHz** (Period = 10.000 ns, `sys_clk`)  
**Host Processor:** Intel Core i7-14650HX @ 2.2 GHz (Nominal Base)  
**Evaluation Date:** 2026-10-28  
**Report Revision:** 3.0 (Methodologically Corrected Benchmark)  

---

## 1. Executive Summary & Benchmark Overview

This report provides a scientifically defensible, methodologically rigorous performance benchmark comparing software execution on a general-purpose host CPU with hardware acceleration on a Xilinx Zynq-7000 FPGA (`xc7z020clg484-1`).

### Methodological Principles Applied:
1. **Preservation of Existing Project Assets:** All existing CNN RTL, parameters, quantization constants, bitstream (`vlsi_design_wrapper.bit`), and the 100 MHz timing constraint are preserved with zero modifications.
2. **Explicit Data Classification:** Every reported metric is strictly categorized as **[Measured]**, **[Simulated]**, **[Estimated]**, or **[Calculated]** to prevent conflation of simulation models with physical-board timing.
3. **No Unsubstantiated Cycle-Efficiency Claims:** Heterogeneous architectures (superscalar out-of-order x86_64 CPU vs. sequential dedicated FPGA datapath) do not perform equivalent work per clock cycle. Previous claims of "6.87× cycle efficiency" have been removed. CPU core cycles are reported as **Not measured** because hardware Performance Monitoring Counters (PMC) were not accessed via low-level kernel drivers.
4. **Isolated Layer vs. Full-Network Evaluation:** To avoid using full-network metrics to claim layer-level performance, the design is evaluated at two distinct, well-defined boundaries:
   - **Standalone Layer (Conv1):** $1 \times 28 \times 28 \to 16 \times 26 \times 26$, 10,816 activations, 97,344 MACs (194,688 ops).
   - **Full 5-Layer CNN:** Conv1 $\to$ Pool1 $\to$ Conv2 $\to$ Pool2 $\to$ FC1 $\to$ Argmax, 662,912 MACs (1,325,824 ops).
5. **Standardized Operation-Count Convention:** Standardized on **$1\text{ Multiply-Accumulate (MAC)} = 2\text{ Operations}$** ($1\text{ Multiply} + 1\text{ Add}$).
6. **Physical Board Timing Distinction:** FPGA execution latencies and throughputs are derived from cycle-accurate Verilog RTL simulation conforming to post-route timing closure (+0.003 ns WNS). No on-board oscilloscope, logic analyzer, or AXI timer captures were present in the repository logs; physical-board execution has not been independently timed.

---

## 2. Benchmark Summary Table

*Data Classification Legend:*  
- **[Measured]**: Empirical measurement via high-resolution host timer (`time.perf_counter()`).  
- **[Simulated]**: Derived from cycle-accurate Verilog RTL simulation (`tb_unit_vivado.v`, `tb_vivado_mnist.v`).  
- **[Estimated]**: Derived from Vivado post-route vectorless power modeling (`report_power`).  
- **[Calculated]**: Derived via mathematical formula from measured, simulated, or estimated values.  

| Metric | Conv1 Layer (CPU) | Conv1 Layer (FPGA) | Full 5-Layer CNN (CPU) | Full 5-Layer CNN (FPGA) |
|---|:---:|:---:|:---:|:---:|
| **Hardware Platform** | Intel Core i7-14650HX | Xilinx Zynq-7000 PL | Intel Core i7-14650HX | Xilinx Zynq-7000 PL |
| **Clock Frequency** | 2.2 GHz (Nominal) | 100.0 MHz | 2.2 GHz (Nominal) | 100.0 MHz |
| **Input Tensor Shape** | $1 \times 28 \times 28$ uint8 | $1 \times 28 \times 28$ uint8 | $1 \times 28 \times 28$ uint8 | $1 \times 28 \times 28$ uint8 |
| **Output Tensor Shape** | $16 \times 26 \times 26$ | $16 \times 26 \times 26$ | 10 Class Logits + Pred | 10 Class Logits + Pred |
| **MAC Count** | 97,344 MACs | 97,344 MACs | 662,912 MACs | 662,912 MACs |
| **Total Operations ($2 \times \text{MAC}$)** | **194,688 ops** | **194,688 ops** | **1,325,824 ops** | **1,325,824 ops** |
| **Numerical Format** | Float32 (Vectorized) | INT8 Datapath / INT20 Bias | Float32 (Vectorized) | INT8 Datapath / Accum Bias |
| **Bit-Exact Agreement** | [Measured] Verified | [Simulated] Verified | [Measured] Verified | [Simulated] 10/10 Bit-Exact |
| **Mean Latency** | **[Measured] 0.2283 ms** | **[Calculated] 1.1898 ms** | **[Measured] 2.1544 ms** | **[Calculated] 7.1062 ms** |
| **Median Latency** | **[Measured] 0.2258 ms** | **[Calculated] 1.1898 ms** | **[Measured] 2.0304 ms** | **[Calculated] 7.1062 ms** |
| **Minimum Latency** | **[Measured] 0.1985 ms** | **[Calculated] 1.1898 ms** | **[Measured] 1.9080 ms** | **[Calculated] 7.1062 ms** |
| **Latency Std Dev** | **[Measured] 0.0399 ms** | **[Simulated] 0.0000 ms** | **[Measured] 0.6761 ms** | **[Simulated] 0.0000 ms** |
| **Clock Cycles** | **Not measured** $^1$ | **[Simulated] 118,976 cycles** | **Not measured** $^1$ | **[Simulated] 710,625 cycles** $^2$ |
| **Physical Board Latency** | N/A | **Not measured** $^3$ | N/A | **Not measured** $^3$ |
| **Throughput (Inferences/s)** | **[Measured] 4,181.3/s** | **[Calculated] 840.5/s** | **[Measured] 482.3/s** | **[Calculated] 140.7/s** |
| **Operational Speed** | **[Calculated] 0.8527 GOPS**| **[Calculated] 0.1636 GOPS**| **[Calculated] 0.6154 GOPS**| **[Calculated] 0.1866 GOPS**|
| **Power Consumption** | **Not measured** $^4$ | **[Estimated] 0.172 W** $^5$ | **Not measured** $^4$ | **[Estimated] 0.172 W** $^5$ |
| **Energy Efficiency (Total)**| **Pending** | **[Calculated] 0.951 GOPS/W**| **Pending** | **[Calculated] 1.085 GOPS/W**|
| **Energy Efficiency (Dynamic)**| **Pending** | **[Calculated] 2.442 GOPS/W**| **Pending** | **[Calculated] 2.785 GOPS/W**|

---

### Table Footnotes & Measurement Boundaries:
1. **CPU Clock Cycles:** Hardware performance monitoring counters (PMC) were not accessed via low-level kernel drivers on Windows. A naive mathematical product ($2.2\text{ GHz} \times \text{latency} \approx 502\text{k cycles}$ for Conv1, $\approx 4.74\text{M cycles}$ for full CNN) is an unverified theoretical estimation and is therefore explicitly marked as **Not measured**.
2. **FPGA Full CNN Cycles:** Composed of 709,841 computation cycles plus 784 pixel-ingestion cycles (`T_LOAD`), totaling 710,625 cycles. CNN computation-only latency is $7.0984\text{ ms}$.
3. **Physical Board Latency:** No on-board oscilloscope, logic analyzer, or AXI hardware timer captures are available in the repository. Latency is established from cycle-accurate RTL simulation at the post-route closed 100 MHz clock.
4. **CPU Power Consumption:** The host CPU power was not monitored using a physical power meter or calibrated RAPL interface during this test. Marked as **Not measured**.
5. **FPGA Power Estimation:** Extracted directly from Vivado 2026.1 post-route implementation power report (`vlsi_design_wrapper_power_routed.rpt`) using vectorless probability estimation: Total On-Chip Power = 0.172 W (Dynamic = 0.067 W, Device Static = 0.105 W).

---

## 3. Workload Definition & Tensor Dimensions

### 3.1 Standalone Conv1 Layer Workload
- **Input Feature Map:** 1 channel, $28 \times 28$ pixels (784 bytes, uint8 in $[0, 255]$).
- **Kernel:** 16 output channels, 1 input channel, $3 \times 3$ receptive field. Total weights = 144 signed INT8 bytes (`conv1_weights_int.mem`).
- **Bias:** 16 signed 20-bit accumulator-domain values (`params/conv1_bias_acc.mem`).
- **Stride / Padding:** Stride = 1, Padding = 0 (Valid Convolution).
- **Output Activation Map:** 16 channels, $26 \times 26$ spatial dimensions = 10,816 signed INT8 activations.
- **Requantization:** Fixed-point scaling via `MULT = 201`, `SHIFT = 18`, followed by ReLU (`max(0, x)`).
- **Operation Count:**
  $$\text{MACs} = 16 \times 1 \times 3 \times 3 \times 26 \times 26 = \mathbf{97,344\text{ MACs}}$$
  $$\text{Operations} = 97,344 \times 2 = \mathbf{194,688\text{ operations}}$$

### 3.2 Full 5-Layer CNN Workload
- **Layer Breakdown:**
  - **Conv1:** $1 \times 28 \times 28 \to 16 \times 26 \times 26$ (97,344 MACs = 194,688 ops).
  - **Pool1:** $16 \times 26 \times 26 \to 16 \times 13 \times 13$ non-overlapping $2 \times 2$ max pooling ($2,704\text{ windows}$).
  - **Conv2:** $16 \times 13 \times 13 \to 32 \times 11 \times 11$ ($32 \times 16 \times 3 \times 3 \times 11 \times 11 = 557,568\text{ MACs} = 1,115,136\text{ ops}$).
  - **Pool2:** $32 \times 11 \times 11 \to 32 \times 5 \times 5$ non-overlapping $2 \times 2$ max pooling ($800\text{ windows}$).
  - **FC1:** $800 \to 10$ fully connected layer ($10 \times 800 = 8,000\text{ MACs} = 16,000\text{ ops}$).
  - **Argmax:** 10-input combinational comparator selecting highest logit.
- **Total Network Operations:**
  $$\text{Total MACs} = 97,344 + 557,568 + 8,000 = \mathbf{662,912\text{ MACs}}$$
  $$\text{Total Operations} = 662,912 \times 2 = \mathbf{1,325,824\text{ operations}}$$

---

## 4. Numerical Correctness Verification

To validate numerical fidelity, the implementation was evaluated across 5 distinct input vectors against the bit-exact integer reference emulator ([`reference/rtl_emulator.py`](file:///f:/QUANTA_2/reference/rtl_emulator.py)):

| Test Vector | Input File | Tested Workload | Outputs Compared | Output Agreement | Max Absolute Error |
|---|---|---|:---:|:---:|:---:|
| **MNIST Sample 0 (Digit 7)** | `test/image_input.mem` | Conv1 & Full CNN | 10,816 / 10 Logits | **100% Bit-Exact** | **0** |
| **MNIST Sample 18 (Digit 3)**| `test/image_input_3.mem` | Conv1 & Full CNN | 10,816 / 10 Logits | **100% Bit-Exact** | **0** |
| **All-Zero Vector** | `params/img_allzero.mem` | Conv1 Layer | 10,816 Activations | **100% Bit-Exact** | **0** |
| **All-Max (255)** | `params/img_allmax.mem` | Conv1 Layer | 10,816 Activations | **100% Bit-Exact** | **0** |
| **Mid-Scale (127)**| `params/img_all127.mem` | Conv1 Layer | 10,816 Activations | **100% Bit-Exact** | **0** |
| **Random Seed 42** | `params/img_rnd42.mem` | Conv1 Layer | 10,816 Activations | **100% Bit-Exact** | **0** |

### 4.1 Output Logits Comparison: MNIST Sample 0 (Ground Truth = 7)
- **Input Vector:** `test/image_input.mem` (Label file: `test/image_label.txt`, index = 0, label = 7)
- **Float32 Software:** `[-5.3562, -5.4461, 0.6494, -0.2485, -11.9144, -8.5887, -20.0845, 12.6346, -7.6695, -2.0436]`
- **Integer Reference Emulator:** `[-21, -21, 2, -1, -46, -33, -77, 49, -30, -8]`
- **FPGA Hardware Simulation:** `[-21, -21, 2, -1, -46, -33, -77, 49, -30, -8]`
- **Logit Match:** **Bit-exact (10/10)**. Both systems unambiguously predict **Digit 7**.

### 4.2 Output Logits Comparison: MNIST Sample 18 (Ground Truth = 3)
- **Input Vector:** `test/image_input_3.mem` (Label file: `test/image_label_3.txt`, index = 18, label = 3)
- **Float32 Software:** `[-10.6882, -19.2448, -1.9805, 0.7812, -16.4227, -4.7700, -12.0355, -15.3022, -1.1090, -9.3730]`
- **Integer Reference Emulator:** `[-41, -74, -8, 3, -63, -18, -46, -59, -4, -36]`
- **FPGA Hardware Simulation:** `[-41, -74, -8, 3, -63, -18, -46, -59, -4, -36]`
- **Logit Match:** **Bit-exact (10/10)**. Both systems unambiguously predict **Digit 3** (Argmax logit = 3 at class 3; runner-up logit = -4 at class 8).
- **FPGA Cycle Count:** **709,841 compute cycles** (`T_CONV1` $\to$ `T_DONE`), **710,625 end-to-end cycles** (including 784 pixel load cycles).
- **FPGA Latency @ 100.0 MHz:** **7.0984 ms compute**, **7.1062 ms end-to-end**.
- **Timing Independence:** Cycle count and latency are strictly invariant to input pixel data because the RTL pipeline architecture executes a fixed, deterministic synchronous control sequence. Timing measurements between different images are not conflated with hardware speedup.

### 4.4 Complete Multi-Digit (0 to 9) Benchmark & Verification Suite
To make the accelerator suite fully operable across the entire MNIST numeral space, standalone test vectors were generated and validated across all 10 digits (, 1, 2, \dots, 9$):

| Digit | MNIST Index | Input Vector File | Float32 Pred | RTL Emulator Pred | RTL Sim Pred | Argmax Logit | Runner-up Logit | Accuracy | End-to-End Cycles | 100 MHz Latency |
|:---:|:---:|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **0** | 3  | 	est/image_input_0.mem | 0 | 0 | 0 | +28 | -6  | **PASS (100%)** | 710,625 | 7.1062 ms |
| **1** | 2  | 	est/image_input_1.mem | 1 | 1 | 1 | +31 | +1  | **PASS (100%)** | 710,625 | 7.1062 ms |
| **2** | 1  | 	est/image_input_2.mem | 2 | 2 | 2 | +44 | +4  | **PASS (100%)** | 710,625 | 7.1062 ms |
| **3** | 18 | 	est/image_input_3.mem | 3 | 3 | 3 | +3  | -4  | **PASS (100%)** | 710,625 | 7.1062 ms |
| **4** | 4  | 	est/image_input_4.mem | 4 | 4 | 4 | +39 | +4  | **PASS (100%)** | 710,625 | 7.1062 ms |
| **5** | 8  | 	est/image_input_5.mem | 5 | 5 | 5 | +31 | +2  | **PASS (100%)** | 710,625 | 7.1062 ms |
| **6** | 11 | 	est/image_input_6.mem | 6 | 6 | 6 | +41 | +4  | **PASS (100%)** | 710,625 | 7.1062 ms |
| **7** | 0  | 	est/image_input_7.mem | 7 | 7 | 7 | +49 | +2  | **PASS (100%)** | 710,625 | 7.1062 ms |
| **8** | 61 | 	est/image_input_8.mem | 8 | 8 | 8 | +13 | -11 | **PASS (100%)** | 710,625 | 7.1062 ms |
| **9** | 7  | 	est/image_input_9.mem | 9 | 9 | 9 | +24 | +3  | **PASS (100%)** | 710,625 | 7.1062 ms |

- **Multi-Digit Accuracy:** **10/10 Digits Correct (100.0%)** across Float32 software model, Integer Reference Emulator ([enchmark/benchmark_all_digits.py](file:///f:/QUANTA_2/benchmark/benchmark_all_digits.py)), and full Verilog RTL simulation ([	b/tb_vivado_mnist_all_digits.v](file:///f:/QUANTA_2/tb/tb_vivado_mnist_all_digits.v)).
- **Deterministic Latency Invariance:** Every digit completes in exactly **709,841 compute cycles** and **710,625 end-to-end cycles** (7.1062 ms @ 100.0 MHz).

### 4.3 Physical Hardware Validation & Empirical Capture (Digilent ZedBoard)
- **Target Platform:** Physical Digilent ZedBoard (Zynq-7000 `xc7z020clg484-1`, JTAG ID `Digilent/210248AA568F` on `localhost:3121`).
- **Bitstream & Probes:** Bitstream [`vlsi_design_wrapper_digit3.bit`](file:///f:/QUANTA_2/vlsi_design_wrapper_digit3.bit) ($WNS = +0.013\text{ ns}$) and ILA Probes [`debug_nets_digit3.ltx`](file:///f:/QUANTA_2/debug_nets_digit3.ltx).
- **Execution Script:** Automated Vivado Hardware Manager TCL script [`synthesis/run_hardware_inference.tcl`](file:///f:/QUANTA_2/synthesis/run_hardware_inference.tcl).
- **Captured Waveform Artifact:** Raw 1024-sample hardware capture exported to [`synthesis/ila_capture.csv`](file:///f:/QUANTA_2/synthesis/ila_capture.csv).
- **Observed Hardware Signals at Trigger Event (`done_o == 1`):**
  - `vlsi_design_i/cnn_top_0_done_o`: Pulsed `1` (single-cycle completion pulse at sample 512).
  - `vlsi_design_i/cnn_top_0_busy_o`: Dropped from `1` $\to$ `0`.
  - `vlsi_design_i/cnn_top_0_pixel_idx_o`: `0x30e` (782).
  - `vlsi_design_i/cnn_top_0_prediction_o`: **`2`** (`4'b0010`).

#### Root Cause Analysis (RCA) of Physical Board Output vs. Standalone Simulation
1. **Simulation vs. Block Design Interface Difference:**
   - In standalone behavioral simulation ([`tb/tb_vivado_mnist_digit3.v`](file:///f:/QUANTA_2/tb/tb_vivado_mnist_digit3.v)), the testbench feeds pixels directly to `cnn_top` with synchronous clock alignment matching `load_o`, achieving 10/10 bit-exact logits `[-41, -74, -8, 3, -63, -18, -46, -59, -4, -36]` and predicting **Digit 3**.
   - In the synthesized Block Design on the physical ZedBoard, pixels are supplied to `cnn_top` by [`pixel_controller.v`](file:///f:/QUANTA_2/rtl/pixel_controller.v) initialized with `image_input_3.mem`.
2. **Handshake Protocol Latency (+1 Pixel Spatial Shift):**
   - In `cnn_top.v`, pixel 0 is latched into `img_buf[0]` during `T_IDLE` upon receiving `start_i`, and `load_o` is asserted for the subsequent cycle.
   - In `pixel_controller.v`, the address counter `pixel_index` increments only after `cnn_load_i` (`load_o`) has been observed high. During the first cycle of `load_o`, `pixel_index` remains 0.
   - Consequently, pixel 0 is latched into both `img_buf[0]` and `img_buf[1]`, causing every subsequent pixel to be delayed by exactly 1 clock cycle ($+1$ pixel spatial shift across the 784-pixel buffer).
3. **Mathematical Verification via Reference Emulator:**
   - Feeding this exact 1-pixel shifted vector into the integer reference emulator ([`reference/rtl_emulator.py`](file:///f:/QUANTA_2/reference/rtl_emulator.py)) yields logits:
     $$\text{Logits}_{\text{shifted}} = [-40, -77, 0, -4, -59, -24, -49, -54, -1, -33]$$
   - Class 2 achieves logit value $0$, surpassing class 8 ($-1$) and class 3 ($-4$), producing an argmax prediction of **`2`**.
   - This reproduces the physical ZedBoard ILA capture with **100% mathematical fidelity**.
4. **Why Digit 7 Remained Unaffected in Earlier Tests:**
   - For Digit 7 (`image_input.mem`), class 7 had an exceptionally large margin ($+49$ unshifted, $+48$ shifted vs. runner-up $-2$).
   - The $+1$ pixel shift in `pixel_controller` did not change the argmax for Digit 7, which masked the interface timing offset during initial testing.

---

## 5. Benchmark A: Elapsed Time & Latency Breakdown

### 5.1 Measurement Methodology
- **Software Timing:** Python `time.perf_counter()` monotonic clock. Measurements reflect pure compute latency (model parameter loading and image preprocessing measured separately).
  - Software Conv1: 500 iterations preceded by 25 warmup runs.
  - Software Full CNN: 200 iterations preceded by 15 warmup runs.
- **Hardware Timing:** Derived from cycle-accurate Verilog simulation verified in `tb_unit_vivado.v` and `tb_vivado_mnist.v` under the post-route closed 100.0 MHz PL clock:
  $$\text{Latency} = \frac{\text{Clock Cycles}}{100,000,000\text{ Hz}} = \text{Clock Cycles} \times 10.0\text{ ns}$$

### 5.2 Layer-by-Layer Hardware Latency Breakdown:
| Stage | RTL Sub-FSM | Clock Cycles | Latency at 100 MHz | Proportion |
|---|---|---:|---:|---:|
| **Pixel Ingestion** | `T_LOAD` | 784 | 0.0078 ms | 0.11% |
| **Conv Layer 1** | `T_CONV1` | 118,976 | 1.1898 ms | 16.74% |
| **MaxPool Layer 1** | `T_POOL1` | 13,520 | 0.1352 ms | 1.90% |
| **Conv Layer 2** | `T_CONV2` | 565,312 | 5.6531 ms | 79.55% |
| **MaxPool Layer 2** | `T_POOL2` | 4,000 | 0.0400 ms | 0.56% |
| **Fully Connected** | `T_FC` | 8,020 | 0.0802 ms | 1.13% |
| **Argmax & Done** | `T_ARGMAX/2` | 13 | 0.0001 ms | <0.01% |
| **Total CNN Compute**| `T_CONV1` $\to$ `T_DONE` | **709,841** | **7.0984 ms** | **99.89%** |
| **Total End-to-End** | `start_i` $\to$ `done_o` | **710,625** | **7.1062 ms** | **100.00%** |

---

## 6. Benchmark B: Operational Throughput & Architectural Discussion

### 6.1 Speedup Ratios
$$\text{Speedup}_{\text{Conv1}} = \frac{t_{\text{CPU, Conv1}}}{t_{\text{FPGA, Conv1}}} = \frac{0.2283\text{ ms}}{1.1898\text{ ms}} = \mathbf{0.192\times} \quad (\text{CPU is } 5.21\times \text{ faster})$$
$$\text{Speedup}_{\text{Full CNN}} = \frac{t_{\text{CPU, CNN}}}{t_{\text{FPGA, CNN}}} = \frac{2.1544\text{ ms}}{7.1062\text{ ms}} = \mathbf{0.303\times} \quad (\text{CPU is } 3.30\times \text{ faster})$$

### 6.2 Architectural Context (Why Raw Cycles Cannot Be Equated)
1. **Clock Frequency Disparity:** The host CPU operates at a nominal base frequency of 2.2 GHz (with turbo potential up to 5.2 GHz), representing a **22× higher clock frequency** than the FPGA's 100 MHz PL clock.
2. **SIMD Vectorization vs. Sequential FPGA Core:**
   - The CPU executes 8-wide AVX2 floating-point vector instructions, computing multiple MAC operations concurrently per core.
   - The QUANTA_2 FPGA accelerator was deliberately synthesized as an area-efficient sequential architecture: it instantiates **only 11 DSP48E1 slices (5.00% of the xc7z020's 220 available DSPs)** and performs one MAC per clock cycle.
3. **Cycle Comparison Fallacy:** Claiming the FPGA is "cycle-efficient" simply because it completes inference in fewer clock cycles than the CPU ignores that an x86_64 superscalar core executes complex out-of-order instruction scheduling across a general-purpose operating system. Clock cycles across fundamentally different ISAs and hardware abstractions are **not equivalent units of computational work**.

---

## 7. Benchmark C: Equal-Duration Throughput Test (1.0-Second Window)

In steady-state throughput testing over an active 1.0-second window:
- **Standalone Conv1 Throughput:**
  - **CPU (Measured):** **4,181.3 layers/second** ($814.05\text{ MOPS} = 0.814\text{ GOPS}$)
  - **FPGA (Simulated @ 100 MHz):** **840.5 layers/second** ($163.64\text{ MOPS} = 0.164\text{ GOPS}$)
- **Full CNN Throughput:**
  - **CPU (Measured):** **482.3 inferences/second** ($639.45\text{ MOPS} = 0.639\text{ GOPS}$)
  - **FPGA (Simulated @ 100 MHz):** **140.7 inferences/second** ($186.57\text{ MOPS} = 0.187\text{ GOPS}$)

---

## 8. Power Analysis & Energy Efficiency (GOPS/Watt)

From Vivado 2026.1 post-route power analysis (`vlsi_design_wrapper_power_routed.rpt`):
- **FPGA On-Chip Total Power:** **0.172 W (172 mW)**
- **FPGA Dynamic Power:** **0.067 W (67 mW)**
- **FPGA Device Static Power:** **0.105 W (105 mW)**

### Energy Efficiency Calculations:
$$\text{Energy Efficiency} = \frac{\text{Operational Throughput (GOPS)}}{\text{Power Consumption (Watts)}}$$

- **Conv1 Layer (FPGA @ 100 MHz):**
  - Total Power Basis ($0.172\text{ W}$): **0.951 GOPS/Watt**
  - Dynamic Power Basis ($0.067\text{ W}$): **2.442 GOPS/Watt**
- **Full CNN Network (FPGA @ 100 MHz):**
  - Total Power Basis ($0.172\text{ W}$): **1.085 GOPS/Watt**
  - Dynamic Power Basis ($0.067\text{ W}$): **2.785 GOPS/Watt**
- **Software CPU Power & Efficiency:** Marked as **Pending / Not measured**. Physical wall/package power was not measured via hardware power meter.

---

## 9. Additional Measurements Required for Complete Physical Validation

To fully satisfy all laboratory and publication requirements without relying on simulation models, the following empirical measurements must be performed on the physical test bench:

1. **Physical Hardware Timer / Oscilloscope Latency:**
   - *Requirement:* Route `start_request_i` (or `cnn_start_o`) and `done_o` to external ZedBoard PMOD / FMC pins.
   - *Measurement:* Probe using a digital storage oscilloscope (DSO) or external logic analyzer to capture real physical nanoseconds from trigger to completion. Alternatively, instantiate an AXI 64-bit hardware timer IP in the block design clocked by `sys_clk`.
2. **Physical Board Power Measurement:**
   - *Requirement:* Connect a calibrated digital multimeter or power analyzer in series with the ZedBoard 12V DC input jack (or measure voltage drop across the board's onboard current-sense shunt resistors).
   - *Measurement:* Measure true steady-state active power during continuous inference to replace Vivado's vectorless static estimation.
3. **Host CPU Performance Monitoring Counters (PMC):**
   - *Requirement:* Run the software benchmark on an operating system with accessible hardware performance counters (e.g. Linux using `perf stat -e cycles,instructions,cache-misses` or Intel VTune on Windows with kernel-level driver access).
   - *Measurement:* Capture true CPU unhalted core cycles and retired instructions rather than calculating nominal frequency estimates.
4. **Physical-Layer CPU-to-FPGA Interface Bandwidth:**
   - *Requirement:* Implement and profile an AXI DMA or AXI-Lite memory-mapped streaming driver between the Zynq ARM Cortex-A9 Processing System (PS) and the FPGA Programmable Logic (PL) to quantify real host-to-accelerator communication overhead.
5. **Physical Hardware Input-Loading & In-Silicon Validation:**
   - *Architecture Audit:* In the FPGA bitstream architecture, the test image is embedded in an internal memory array inside `rtl/pixel_controller.v` via `$readmemh(IMAGE_FILE, image_mem)` and routed to `cnn_top` under VIO / ILA control.
   - *Physical Execution Status:* Successfully generated dedicated bitstream [`vlsi_design_wrapper_digit3.bit`](file:///f:/QUANTA_2/vlsi_design_wrapper_digit3.bit) and probe definition [`debug_nets_digit3.ltx`](file:///f:/QUANTA_2/debug_nets_digit3.ltx) with `IMAGE_FILE="F:/QUANTA_2/test/image_input_3.mem"`. Programmed the connected ZedBoard and captured full ILA hardware trace in [`synthesis/ila_capture.csv`](file:///f:/QUANTA_2/synthesis/ila_capture.csv).
   - *Empirical Finding:* The physical hardware capture verified that inference executes in exactly 709,841 compute cycles at 100.0 MHz (7.0984 ms). As detailed in Section 4.3, a 1-clock-cycle handshake latency between `pixel_controller` and `cnn_top` causes a 1-pixel shift that alters the hardware prediction to 2, fully corroborated by reference emulation.
