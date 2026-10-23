"""Bit-exact integer reference for QUANTA_2's proposed fixed-point contract.

Pure Python/stdlib so it does not depend on NumPy or PyTorch. Activations are
channel-major NCHW-flat lists. Pixel input is uint8 and represents pixel/255.
"""
from __future__ import annotations

import json
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
P = MANIFEST["parameters"]
S_INPUT = Fraction(1, 255)
S_POOL1 = Fraction(4070276, 1000000 * 127)
S_POOL2 = Fraction(12494443, 1000000 * 127)
S_LOGIT = Fraction(33013672, 1000000 * 127)


def round_away(n: int, d: int) -> int:
    """Round n/d to nearest integer, with exact ties away from zero."""
    if d <= 0:
        raise ValueError("denominator must be positive")
    sign = -1 if n < 0 else 1
    q, r = divmod(abs(n), d)
    return sign * (q + (2 * r >= d))


def round_fraction(value: Fraction) -> int:
    return round_away(value.numerator, value.denominator)


def saturate_int8(value: int) -> int:
    return min(127, max(-127, value))


def quantize_acc(acc: int, source_scale: Fraction, target_scale: Fraction,
                 relu: bool = False) -> int:
    q = saturate_int8(round_fraction(Fraction(acc) * source_scale / target_scale))
    return max(0, q) if relu else q


def read_signed_mem(name: str, expected: int) -> list[int]:
    lines = (ROOT / name).read_text(encoding="ascii").splitlines()
    if len(lines) != expected or any(len(s.strip()) != 2 for s in lines):
        raise ValueError(f"{name}: expected {expected} two-hex-digit lines")
    vals = [int(s.strip(), 16) for s in lines]
    return [v - 256 if v >= 128 else v for v in vals]


def load_params() -> dict[str, list[int]]:
    out = {}
    for item in P.values():
        out[item["file_base"]] = read_signed_mem(
            item["file_base"] + ".mem", item["count"])
    return out


def scale(name: str) -> Fraction:
    # Decimal spelling in manifest is the reference's exact rational constant.
    return Fraction(str(P[name]["scale"]))


def bias_in_acc_units(bias_code: int, bias_scale: Fraction,
                      activation_scale: Fraction,
                      weight_scale: Fraction) -> int:
    return round_fraction(Fraction(bias_code) * bias_scale /
                          (activation_scale * weight_scale))


def conv_layer(inp: list[int], in_ch: int, in_h: int, in_w: int,
               out_ch: int, weights: list[int], biases: list[int],
               sw: Fraction, sb: Fraction, sin: Fraction,
               sout: Fraction) -> list[int]:
    kh = kw = 3
    oh, ow = in_h - 2, in_w - 2
    out = [0] * (out_ch * oh * ow)
    for oc in range(out_ch):
        bacc = bias_in_acc_units(biases[oc], sb, sin, sw)
        for oy in range(oh):
            for ox in range(ow):
                acc = bacc
                for ic in range(in_ch):
                    for ky in range(kh):
                        for kx in range(kw):
                            iv = inp[ic * in_h * in_w + (oy + ky) * in_w + ox + kx]
                            wi = (((oc * in_ch + ic) * kh + ky) * kw + kx)
                            acc += iv * weights[wi]
                out[(oc * oh + oy) * ow + ox] = quantize_acc(
                    acc, sin * sw, sout, relu=True)
    return out


def maxpool2(inp: list[int], channels: int, height: int, width: int) -> list[int]:
    oh, ow = height // 2, width // 2
    out = [0] * (channels * oh * ow)
    for c in range(channels):
        for y in range(oh):
            for x in range(ow):
                base = c * height * width + (2 * y) * width + 2 * x
                out[(c * oh + y) * ow + x] = max(
                    inp[base], inp[base + 1],
                    inp[base + width], inp[base + width + 1])
    return out


def infer(image: list[int], params: dict[str, list[int]] | None = None) -> tuple[list[int], int]:
    if len(image) != 28 * 28 or any(not isinstance(v, int) or not 0 <= v <= 255 for v in image):
        raise ValueError("image must contain 784 unsigned pixel bytes")
    p = params if params is not None else load_params()
    w1, b1 = p["conv1_weights_int"], p["conv1_bias_int"]
    w2, b2 = p["conv2_weights_int"], p["conv2_bias_int"]
    wf, bf = p["fc1_weights_int"], p["fc1_bias_int"]
    c1 = conv_layer(image, 1, 28, 28, 16, w1, b1,
                    scale("0.weight"), scale("0.bias"), S_INPUT, S_POOL1)
    p1 = maxpool2(c1, 16, 26, 26)
    c2 = conv_layer(p1, 16, 13, 13, 32, w2, b2,
                    scale("3.weight"), scale("3.bias"), S_POOL1, S_POOL2)
    p2 = maxpool2(c2, 32, 11, 11)
    # PyTorch Flatten(NCHW) order is already channel-major in p2.
    logits = []
    for oc in range(10):
        acc = bias_in_acc_units(bf[oc], scale("7.bias"), S_POOL2,
                                scale("7.weight"))
        base = oc * 800
        for i, a in enumerate(p2):
            acc += a * wf[base + i]
        logits.append(round_fraction(Fraction(acc) * S_POOL2 *
                                     scale("7.weight") / S_LOGIT))
    # Stable first-index tie break.
    pred = max(range(10), key=lambda i: logits[i])
    return logits, pred


if __name__ == "__main__":
    logits, prediction = infer([0] * 784)
    print(f"all-zero image: logits={logits} prediction={prediction}")
