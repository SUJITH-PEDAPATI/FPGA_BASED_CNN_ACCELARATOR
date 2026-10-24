"""Bit-exact RTL emulator: mirrors the Verilog integer arithmetic exactly."""
import sys, json, random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def sext(v, width):
    v = v & ((1 << width) - 1)
    if v >> (width - 1):
        v -= (1 << width)
    return v

def rtl_quant(acc, MULT, SHIFT, relu=False):
    product = sext(acc, 32) * MULT
    product_rounded = product + (1 << (SHIFT - 1))
    shifted = product_rounded >> SHIFT
    if shifted > 127:  shifted = 127
    if shifted < -127: shifted = -127
    if relu and shifted < 0: shifted = 0
    return shifted

def read_mem_signed(path, n, width):
    lines = [l.strip() for l in Path(path).read_text().splitlines() if l.strip()]
    return [sext(int(l, 16), width) for l in lines[:n]]

def read_weights(path, n):
    return read_mem_signed(path, n, 8)

w1 = read_weights(ROOT / "conv1_weights_int.mem", 144)
w2 = read_weights(ROOT / "conv2_weights_int.mem", 4608)
wf = read_weights(ROOT / "fc1_weights_int.mem", 8000)
b1 = read_mem_signed(ROOT / "params/conv1_bias_acc.mem", 16, 20)
b2 = read_mem_signed(ROOT / "params/conv2_bias_acc.mem", 32, 16)
bf = read_mem_signed(ROOT / "params/fc_bias_acc.mem", 10, 12)


def rtl_conv(inp, in_ch, in_h, in_w, out_ch, weights, bias_acc,
             MULT, SHIFT, first_layer=False):
    oh, ow = in_h - 2, in_w - 2
    out = [0] * (out_ch * oh * ow)
    for oc in range(out_ch):
        for oy in range(oh):
            for ox in range(ow):
                acc = bias_acc[oc]
                for ic in range(in_ch):
                    for ky in range(3):
                        for kx in range(3):
                            pix = inp[ic * (in_h * in_w) + (oy + ky) * in_w + (ox + kx)]
                            in_ext = (pix & 0xFF) if first_layer else sext(pix, 8)
                            wi = (oc * in_ch + ic) * 9 + ky * 3 + kx
                            acc += in_ext * sext(weights[wi], 8)
                out[(oc * oh + oy) * ow + ox] = rtl_quant(acc, MULT, SHIFT, relu=True)
    return out


def rtl_pool(inp, ch, h, w):
    oh, ow = h // 2, w // 2
    out = [0] * (ch * oh * ow)
    for c in range(ch):
        for y in range(oh):
            for x in range(ow):
                vals = [sext(inp[(c * h + y * 2 + dy) * w + x * 2 + dx], 8)
                        for dy in range(2) for dx in range(2)]
                out[(c * oh + y) * ow + x] = max(vals)
    return out


def rtl_infer(img):
    c1 = rtl_conv(img, 1, 28, 28, 16, w1, b1, 201, 18, first_layer=True)
    p1 = rtl_pool(c1, 16, 26, 26)
    c2 = rtl_conv(p1, 16, 13, 13, 32, w2, b2, 2637, 21)
    p2 = rtl_pool(c2, 32, 11, 11)
    logits = []
    for oc in range(10):
        acc = bf[oc]
        for i in range(800):
            acc += sext(p2[i], 8) * sext(wf[oc * 800 + i], 8)
        prod = acc * 1965
        logits.append((prod + (1 << 20)) >> 21)
    pred = max(range(10), key=lambda i: logits[i])
    return logits, pred


if __name__ == "__main__":
    tests = [
        ("all_zero", [0] * 784,         [-3, 5, 4, -4, -4, 2, -6, 3, -7, -3], 1),
        ("all_max",  [255] * 784,       [-10, -23, -30, -34, -7, -59, 5, -43, -9, -50], 6),
        ("all_127",  [127] * 784,       [-5, -10, -16, -20, -1, -32, 3, -21, -5, -26], 6),
    ]
    random.seed(42)
    rnd = [random.randint(0, 255) for _ in range(784)]
    tests.append(("rnd42", rnd, [-19, -42, -11, -14, -25, -42, -14, -43, 7, -43], 8))

    all_pass = True
    for name, img, exp_l, exp_p in tests:
        logits, pred = rtl_infer(img)
        ok = (logits == exp_l) and (pred == exp_p)
        if ok:
            print(f"  PASS [{name}] logits={logits} pred={pred}")
        else:
            print(f"  FAIL [{name}] logits={logits} pred={pred}")
            print(f"         exp    {exp_l}      exp_pred={exp_p}")
            all_pass = False
    print()
    print("ALL PASS" if all_pass else "SOME FAILURES")
