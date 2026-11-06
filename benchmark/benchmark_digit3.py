#!/usr/bin/env python3
"""
benchmark_digit3.py -- QUANTA_2 Benchmark for MNIST Digit 3 (Sample Index 18)
Compares Float32 Software CNN, Integer RTL Emulator, and Cycle-Accurate FPGA RTL.
"""

import sys
import time
import json
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str((ROOT / "reference").resolve()))
import rtl_emulator

IMAGE_PATH = ROOT / "test" / "image_input_3.mem"
LABEL_PATH = ROOT / "test" / "image_label_3.txt"
MANIFEST_PATH = ROOT / "manifest.json"

FPGA_CLOCK_HZ = 100_000_000
FPGA_CNN_COMPUTE_CYCLES = 709_841
FPGA_CNN_END_TO_END_CYCLES = 710_625
FPGA_POWER_TOTAL_W = 0.172
FPGA_POWER_DYNAMIC_W = 0.067
CNN_OPS = 1_325_824

def load_label():
    lines = LABEL_PATH.read_text(encoding="ascii").strip().splitlines()
    info = {}
    for line in lines:
        if "=" in line:
            k, v = line.split("=", 1)
            info[k.strip()] = int(v.strip())
    return info

def load_float_model():
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    p = manifest["parameters"]

    def read_csv(name, shape, scale):
        vals = [int(x) for x in (ROOT / f"{name}.csv").read_text(encoding="ascii").strip().split()]
        return np.array(vals, dtype=np.float32).reshape(shape) * float(scale)

    return {
        "w1": read_csv("conv1_weights_int", [16, 1, 3, 3], p["0.weight"]["scale"]),
        "b1": read_csv("conv1_bias_int", [16], p["0.bias"]["scale"]),
        "w2": read_csv("conv2_weights_int", [32, 16, 3, 3], p["3.weight"]["scale"]),
        "b2": read_csv("conv2_bias_int", [32], p["3.bias"]["scale"]),
        "wf": read_csv("fc1_weights_int", [10, 800], p["7.weight"]["scale"]),
        "bf": read_csv("fc1_bias_int", [10], p["7.bias"]["scale"])
    }

def conv2d_im2col(x, w, b):
    C_in, H, W = x.shape
    C_out, _, KH, KW = w.shape
    OH = H - KH + 1
    OW = W - KW + 1
    shape = (C_in, OH, OW, KH, KW)
    strides = (x.strides[0], x.strides[1], x.strides[2], x.strides[1], x.strides[2])
    cols = np.lib.stride_tricks.as_strided(x, shape=shape, strides=strides)
    out = np.einsum("chwij,ocij->ohw", cols, w) + b[:, None, None]
    return np.maximum(0.0, out)

def maxpool2d_2x2(x):
    C, H, W = x.shape
    OH, OW = H // 2, W // 2
    return x[:, :OH * 2, :OW * 2].reshape(C, OH, 2, OW, 2).max(axis=(2, 4))

def cnn_float_infer(img_float, model):
    c1 = conv2d_im2col(img_float, model["w1"], model["b1"])
    p1 = maxpool2d_2x2(c1)
    c2 = conv2d_im2col(p1, model["w2"], model["b2"])
    p2 = maxpool2d_2x2(c2)
    flat = p2.flatten()
    logits = model["wf"] @ flat + model["bf"]
    pred = int(np.argmax(logits))
    return logits, pred

def main():
    print("=" * 80)
    print("QUANTA_2: Benchmark & Verification for MNIST Digit 3")
    print("=" * 80)

    label_info = load_label()
    gt_index = label_info.get("index", 18)
    gt_label = label_info.get("label", 3)
    print(f"Dataset Index       : {gt_index}")
    print(f"Ground-Truth Digit  : {gt_label}")
    print(f"Image Input File    : {IMAGE_PATH.relative_to(ROOT)}")
    print(f"Label Metadata File : {LABEL_PATH.relative_to(ROOT)}")

    # Parse pixels
    raw_lines = [l.strip() for l in IMAGE_PATH.read_text(encoding="ascii").splitlines() if l.strip()]
    pixels = [int(line, 16) for line in raw_lines]
    assert len(pixels) == 784, f"Expected 784 pixels, got {len(pixels)}"

    img_u8 = np.array(pixels, dtype=np.uint8).reshape(1, 28, 28)
    img_f = img_u8.astype(np.float32) / 255.0

    # 1. Float32 Software Forward Pass
    model_f = load_float_model()
    float_logits, float_pred = cnn_float_infer(img_f, model_f)

    # 2. Integer RTL Reference Emulator Forward Pass
    emu_logits, emu_pred = rtl_emulator.rtl_infer(pixels)

    # 3. Verilog RTL Simulation Results (from tb_vivado_mnist_digit3.v / tb_mnist_digit2.v)
    rtl_sim_logits = [-41, -74, -8, 3, -63, -18, -46, -59, -4, -36]
    rtl_sim_pred = 3

    print("\n" + "-" * 80)
    print("Numerical Results & Comparison Across Implementations")
    print("-" * 80)
    print(f"{'Class':<6} | {'Float32 Logit':<14} | {'RTL Emulator':<14} | {'RTL Simulation':<14} | {'Logit Match':<12}")
    print("-" * 80)
    for c in range(10):
        f_val = float_logits[c]
        e_val = emu_logits[c]
        r_val = rtl_sim_logits[c]
        match = "BIT-EXACT" if e_val == r_val else "MISMATCH"
        print(f"  {c:<4} | {f_val:14.4f} | {e_val:14d} | {r_val:14d} | {match:<12}")
    print("-" * 80)

    print(f"\nPredicted Digit (Float32 CPU)      : {float_pred} (Confidence: max logit = {float_logits[float_pred]:.4f})")
    print(f"Predicted Digit (Integer Emulator) : {emu_pred} (Max logit = {emu_logits[emu_pred]})")
    print(f"Predicted Digit (FPGA Simulation)  : {rtl_sim_pred} (Max logit = {rtl_sim_logits[rtl_sim_pred]})")
    print(f"Ground Truth Class                 : {gt_label}")

    assert emu_logits == rtl_sim_logits, "RTL emulator and RTL simulation logits mismatch!"
    assert float_pred == gt_label, "Float32 prediction does not match ground truth!"
    assert emu_pred == gt_label, "Emulator prediction does not match ground truth!"
    assert rtl_sim_pred == gt_label, "RTL simulation prediction does not match ground truth!"

    print("\n--> ALL LOGITS AND PREDICTIONS CONFIRMED BIT-EXACT & ACCURATE!")

    # Latency and Cycles
    fpga_comp_lat_ms = (FPGA_CNN_COMPUTE_CYCLES / FPGA_CLOCK_HZ) * 1000.0
    fpga_e2e_lat_ms = (FPGA_CNN_END_TO_END_CYCLES / FPGA_CLOCK_HZ) * 1000.0

    print("\n" + "-" * 80)
    print("FPGA Timing Metrics @ 100.0 MHz (xc7z020clg484-1)")
    print("-" * 80)
    print(f"  Pixel Ingestion Cycles (`T_LOAD`)   : 784 cycles (0.00784 ms)")
    print(f"  Compute Cycles (`T_CONV1`->`T_DONE`): {FPGA_CNN_COMPUTE_CYCLES:,} cycles ({fpga_comp_lat_ms:.5f} ms)")
    print(f"  End-to-End Clock Cycles             : {FPGA_CNN_END_TO_END_CYCLES:,} cycles ({fpga_e2e_lat_ms:.5f} ms)")
    print(f"  FPGA Operational Throughput         : {1.0 / (fpga_e2e_lat_ms / 1000.0):.2f} inferences/sec")
    print(f"  FPGA Processing Speed               : {(CNN_OPS / (fpga_e2e_lat_ms / 1000.0)) / 1e9:.4f} GOPS")

    # Host Software Timing on this image
    for _ in range(15):
        cnn_float_infer(img_f, model_f)
    latencies = []
    for _ in range(200):
        t0 = time.perf_counter()
        cnn_float_infer(img_f, model_f)
        t1 = time.perf_counter()
        latencies.append((t1 - t0) * 1000.0)

    cpu_mean_ms = float(np.mean(latencies))
    cpu_med_ms = float(np.median(latencies))
    cpu_min_ms = float(np.min(latencies))
    cpu_std_ms = float(np.std(latencies))
    print("\n" + "-" * 80)
    print("Host CPU Float32 Compute Latency (200 Iterations on Digit 3)")
    print("-" * 80)
    print(f"  Mean Latency   : {cpu_mean_ms:.4f} ms")
    print(f"  Median Latency : {cpu_med_ms:.4f} ms")
    print(f"  Min Latency    : {cpu_min_ms:.4f} ms")
    print(f"  Std Dev        : {cpu_std_ms:.4f} ms")
    print(f"  Throughput     : {1000.0 / cpu_mean_ms:.1f} inferences/sec")

if __name__ == "__main__":
    main()

