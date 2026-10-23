import unittest
from fractions import Fraction

from int_ref import (bias_in_acc_units, maxpool2, quantize_acc, round_away,
                     saturate_int8)


class QuantizationHelpersTest(unittest.TestCase):
    def test_round_away_signed_and_ties(self):
        self.assertEqual(round_away(5, 2), 3)
        self.assertEqual(round_away(-5, 2), -3)
        self.assertEqual(round_away(4, 2), 2)
        self.assertEqual(round_away(-4, 2), -2)

    def test_saturation(self):
        self.assertEqual(saturate_int8(1000), 127)
        self.assertEqual(saturate_int8(-1000), -127)
        self.assertEqual(saturate_int8(-128), -127)

    def test_requantization_relu_and_saturation(self):
        self.assertEqual(quantize_acc(-3, Fraction(1), Fraction(2)), -2)
        self.assertEqual(quantize_acc(-9, Fraction(1), Fraction(1)), -9)
        self.assertEqual(quantize_acc(-3, Fraction(1), Fraction(2), relu=True), 0)
        self.assertEqual(quantize_acc(1000, Fraction(1), Fraction(1)), 127)

    def test_bias_conversion_is_signed_and_rounded(self):
        self.assertEqual(bias_in_acc_units(3, Fraction(1), Fraction(2), Fraction(1)), 2)
        self.assertEqual(bias_in_acc_units(-3, Fraction(1), Fraction(2), Fraction(1)), -2)

    def test_pooling_corner_cases(self):
        # 1 channel, 2x4: signed values and max from each non-overlapping window.
        self.assertEqual(maxpool2([-8, -2, -7, -9, -3, -4, -1, -6], 1, 2, 4), [-2, -1])


if __name__ == "__main__":
    unittest.main()
