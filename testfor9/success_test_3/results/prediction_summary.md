# QUANTA_2 Digit 9 Verification Report -- success_test_3

## 1. Environment Summary
- **Test Environment:** `F:/QUANTA_2/testfor9/`
- **Vivado Project:** `F:/QUANTA_2/testfor9/vivado_project/cnn_accelerator.xpr`
- **Target Part:** Xilinx Zynq-7000 (`xc7z020clg484-1`, Digilent ZedBoard)
- **Input Test Vector:** `F:/QUANTA_2/testfor9/test/image_input_9.mem`
- **Ground Truth Label:** `9` (MNIST Test sample index 7)
- **Parameter Directory:** `F:/QUANTA_2/testfor9/parameters/`

---

## 2. Simulation Results
| Testbench | Simulator | Predicted Digit | Ground Truth | Status | Compute Cycles | Top Logit (Digit 9) | Runner-up (Digit 4) | Margin |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `tb_vivado_mnist.v` | Vivado XSim (2026.1) | **9** | 9 | **PASS** | 709,841 | +24 | +3 | +21 |
| `tb_vivado_mnist.v` | Icarus Verilog | **9** | 9 | **PASS** | 709,841 | +24 | +3 | +21 |
| `tb_system_digit9.v`| Icarus Verilog | **9** | 9 | **PASS** | 709,841 | +24 | +3 | +21 |
| Python RTL Emulator | NumPy Reference | **9** | 9 | **PASS** | 709,841 | +24 | +3 | +21 |

---

## 3. Logit Comparison Matrix (Bit-Exact Agreement)
| Class (Digit) | RTL Output (XSim) | RTL Output (Iverilog) | Python Emulator | Bit-Exact Match? |
| :---: | :---: | :---: | :---: | :---: |
| 0 | -57 | -57 | -57 | YES |
| 1 | -30 | -30 | -30 | YES |
| 2 | -19 | -19 | -19 | YES |
| 3 | -11 | -11 | -11 | YES |
| 4 | +3 | +3 | +3 | YES |
| 5 | -9 | -9 | -9 | YES |
| 6 | -65 | -65 | -65 | YES |
| 7 | -24 | -24 | -24 | YES |
| 8 | -1 | -1 | -1 | YES |
| **9** | **+24** | **+24** | **+24** | **YES (Winner)** |

---

## 4. Waveforms and Logs Generated
- **Vivado Native Waveform:** `F:/QUANTA_2/testfor9/success_test_3/waveforms/tb_vivado_mnist_behav.wdb`
- **VCD Waveform (Unit):** `F:/QUANTA_2/testfor9/success_test_3/waveforms/tb_vivado_mnist_digit9.vcd`
- **VCD Waveform (System):** `F:/QUANTA_2/testfor9/success_test_3/waveforms/tb_system_digit9.vcd`
- **Vivado XSim Execution Log:** `F:/QUANTA_2/testfor9/success_test_3/simulation_logs/vivado_xsim_simulate.log`
- **Unit Simulation Log:** `F:/QUANTA_2/testfor9/success_test_3/simulation_logs/tb_vivado_mnist_digit9.log`
- **System Simulation Log:** `F:/QUANTA_2/testfor9/success_test_3/simulation_logs/tb_system_digit9.log`

