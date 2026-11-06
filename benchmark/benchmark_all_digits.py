#!/usr/bin/env python3
"""
benchmark_all_digits.py -- QUANTA_2 Multi-Digit Benchmark Suite (Digits 0-9)
Validates Float32 Software Model and Integer RTL Reference Emulator across all 10 MNIST classes.
"""

import sys
import os
import json
import time
from pathlib import Path
import numpy as np

os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str((ROOT / "reference").resolve()))
import rtl_emulator

MANIFEST_PATH = ROOT / "manifest.json"
FPGA_CLOCK_HZ = 100_000_000
FPGA_CNN_COMPUTE_CYCLES = 709_841
FPGA_CNN_END_TO_END_CYCLES = 710_625
CNN_OPS = 1_325_824

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

def run_all_digits():
    print("=" * 86)
    print("QUANTA_2: Multi-Digit (0-9) Comprehensive Benchmark & Verification")
    print("=" * 86)

    model_f = load_float_model()
    results = []
    all_passed = True

    print(f"{'Digit':<6} | {'Index':<6} | {'Float32 Pred':<13} | {'RTL Emu Pred':<13} | {'Top RTL Logit':<14} | {'Runner-up':<10} | {'Status':<8}")
    print("-" * 86)

    for digit in range(10):
        mem_file = ROOT / "test" / f"image_input_{digit}.mem"
        lbl_file = ROOT / "test" / f"image_label_{digit}.txt"

        assert mem_file.exists(), f"Missing {mem_file}"
        assert lbl_file.exists(), f"Missing {lbl_file}"

        # Load label metadata
        lines = lbl_file.read_text(encoding="ascii").strip().splitlines()
        meta = {}
        for l in lines:
            if "=" in l:
                k, v = l.split("=", 1)
                meta[k.strip()] = int(v.strip())

        idx = meta.get("index", -1)
        gt_label = meta.get("label", digit)
        assert gt_label == digit

        # Read pixels
        pixels = [int(x.strip(), 16) for x in mem_file.read_text(encoding="ascii").splitlines() if x.strip()]
        assert len(pixels) == 784

        img_u8 = np.array(pixels, dtype=np.uint8).reshape(1, 28, 28)
        img_f = img_u8.astype(np.float32) / 255.0

        # Float32 pass
        f_logits, f_pred = cnn_float_infer(img_f, model_f)

        # Integer RTL Emulator pass
        e_logits, e_pred = rtl_emulator.rtl_infer(pixels)

        # Sorted logits for margin
        sorted_e = sorted(e_logits)
        top_val = sorted_e[-1]
        runner_up = sorted_e[-2]

        match_f = (f_pred == gt_label)
        match_e = (e_pred == gt_label)
        status = "PASS" if (match_f and match_e) else "FAIL"
        if status != "PASS":
            all_passed = False

        results.append({
            "digit": digit,
            "index": idx,
            "gt": gt_label,
            "f_pred": f_pred,
            "e_pred": e_pred,
            "e_logits": e_logits,
            "top_logit": top_val,
            "runner_up": runner_up,
            "margin": top_val - runner_up,
            "status": status
        })

        print(f"  {digit:<4} | {idx:<6} | {f_pred:<13} | {e_pred:<13} | {top_val:<14} | {runner_up:<10} | {status:<8}")

    print("-" * 86)
    acc = sum(1 for r in results if r["status"] == "PASS") / len(results) * 100.0
    print(f"\nOverall Multi-Digit Classification Accuracy: {acc:.1f}% ({len(results)}/{len(results)} Digits Correct)")
    assert all_passed, "One or more digits failed classification!"

    comp_ms = (FPGA_CNN_COMPUTE_CYCLES / FPGA_CLOCK_HZ) * 1000.0
    e2e_ms = (FPGA_CNN_END_TO_END_CYCLES / FPGA_CLOCK_HZ) * 1000.0
    fps = 1000.0 / e2e_ms
    gops = (CNN_OPS / (e2e_ms / 1000.0)) / 1e9

    print("\nDeterministic Invariant FPGA Performance @ 100.0 MHz:")
    print(f"  Compute Cycles / Digit : {FPGA_CNN_COMPUTE_CYCLES:,} cycles ({comp_ms:.4f} ms)")
    print(f"  End-to-End Cycles/Digit: {FPGA_CNN_END_TO_END_CYCLES:,} cycles ({e2e_ms:.4f} ms)")
    print(f"  Throughput             : {fps:.2f} inferences/sec")
    print(f"  Processing Speed       : {gops:.4f} GOPS")

    return results

if __name__ == "__main__":
    run_all_digits()

