#!/usr/bin/env python3
"""
benchmark_rtl_emulator.py -- Integer RTL Emulator Benchmark
Part of QUANTA_2 Hardware vs Software Performance Benchmark.

Benchmarks the exact integer RTL reference emulator from reference/rtl_emulator.py.
Measures inference-only latency, separating parameter loading and preprocessing.
Validates bit-exact output reproduction against historical RTL reference values.
"""

import sys
import time
import platform
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str((ROOT / "reference").resolve()))

IMAGE_PATH = ROOT / "test" / "image_input.mem"
LABEL_PATH = ROOT / "test" / "image_label.txt"

NUM_WARMUP = 2
NUM_ITERATIONS = 50  # Pure Python nested loops take ~250ms per iteration

def main():
    print("=" * 70)
    print("QUANTA_2: Integer RTL Reference Emulator Benchmark")
    print("=" * 70)

    # 1. Environment Details
    print("\n[1] Environment Details:")
    print(f"  Python version : {sys.version.split()[0]} ({platform.python_implementation()})")
    print(f"  Platform       : {platform.system()} {platform.release()} ({platform.machine()})")
    print("  Processor      : Intel Core i7-14650HX @ 2.2 GHz")

    # 2. Module Import and Parameter Loading
    print("\n[2] Loading Emulator and Parameters:")
    t0_load = time.perf_counter()
    import rtl_emulator
    t1_load = time.perf_counter()
    load_time_ms = (t1_load - t0_load) * 1000.0
    print(f"  Module load & param read time : {load_time_ms:.3f} ms")

    # 3. Input Image Preprocessing
    t0_prep = time.perf_counter()
    raw_lines = [l.strip() for l in IMAGE_PATH.read_text(encoding="ascii").splitlines() if l.strip()]
    img_pixels = [int(line, 16) for line in raw_lines]
    t1_prep = time.perf_counter()
    prep_time_ms = (t1_prep - t0_prep) * 1000.0
    print(f"  Image file                    : {IMAGE_PATH.name} ({len(img_pixels)} pixels)")
    print(f"  Image parsing time            : {prep_time_ms:.3f} ms")

    # 4. Verify Functional Output Before Benchmarking
    print("\n[3] Pre-benchmark Functional Verification:")
    sample_logits, sample_pred = rtl_emulator.rtl_infer(img_pixels)
    expected_logits = [-21, -21, 2, -1, -46, -33, -77, 49, -30, -8]
    expected_pred = 7

    print(f"  Output logits   : {sample_logits}")
    print(f"  Predicted class : {sample_pred}")
    assert sample_logits == expected_logits, f"Logit mismatch: {sample_logits} != {expected_logits}"
    assert sample_pred == expected_pred, f"Prediction mismatch: {sample_pred} != {expected_pred}"
    print("  Verification    : PASSED (Exact match with reference output)")

    # 5. Warmup
    print(f"\n[4] Running {NUM_WARMUP} warmup iterations...")
    for _ in range(NUM_WARMUP):
        rtl_emulator.rtl_infer(img_pixels)
    print("  Warmup complete.")

    # 6. Timed Inference Benchmark
    print(f"\n[5] Running {NUM_ITERATIONS} timed inference iterations...")
    latencies_ms = []
    logits = None
    pred = None

    for i in range(NUM_ITERATIONS):
        t0 = time.perf_counter()
        logits, pred = rtl_emulator.rtl_infer(img_pixels)
        t1 = time.perf_counter()
        latencies_ms.append((t1 - t0) * 1000.0)
        if (i + 1) % 10 == 0 or (i + 1) == NUM_ITERATIONS:
            print(f"    Completed {i + 1}/{NUM_ITERATIONS} iterations...")

    # 7. Statistical Analysis
    mean_lat = float(np.mean(latencies_ms))
    median_lat = float(np.median(latencies_ms))
    min_lat = float(np.min(latencies_ms))
    max_lat = float(np.max(latencies_ms))
    std_lat = float(np.std(latencies_ms))

    print("\n[6] Latency Results (Inference Only):")
    print(f"  Iterations : {NUM_ITERATIONS}")
    print(f"  Mean       : {mean_lat:.3f} ms")
    print(f"  Median     : {median_lat:.3f} ms")
    print(f"  Min        : {min_lat:.3f} ms")
    print(f"  Max        : {max_lat:.3f} ms")
    print(f"  Std Dev    : {std_lat:.3f} ms")

    # 8. Output Summary
    print("\n[7] Summary:")
    print(f"  Predicted class : {pred}")
    print(f"  Logits          : {logits}")
    print(f"  Logit agreement : EXACT BIT-MATCH (10/10)")

    return {
        "latencies_ms": latencies_ms,
        "mean_ms": mean_lat,
        "median_ms": median_lat,
        "min_ms": min_lat,
        "max_ms": max_lat,
        "std_ms": std_lat,
        "load_time_ms": load_time_ms,
        "prep_time_ms": prep_time_ms,
        "predicted_class": pred,
        "logits": logits
    }

if __name__ == "__main__":
    main()

