"""Regression checks for the Python examples, without rendering or network."""
import ast
from pathlib import Path
import re
import unittest

import numpy as np
import pandas as pd

SOURCE = Path(__file__).resolve().parents[1] / "index.qmd"
namespace = {}
for block in re.findall(r"```\{python\}\n(.*?)```", SOURCE.read_text(), re.S):
    tree = ast.parse(block)
    # Load definitions and imports only; skip printed examples and file I/O.
    nodes = [node for node in tree.body if isinstance(
        node, (ast.FunctionDef, ast.Import, ast.ImportFrom)
    )]
    nodes = [node for node in nodes if not (
        isinstance(node, ast.Import)
        and any(alias.name.startswith("matplotlib") for alias in node.names)
    )]
    exec(compile(ast.Module(body=nodes, type_ignores=[]), str(SOURCE), "exec"),
         namespace)

bs_price = namespace["bs_price"]
implied_vol = namespace["implied_vol"]
compare_snapshot = namespace["compare_snapshot"]


class PricingTests(unittest.TestCase):
    def test_reference_prices_and_dividend_parity(self):
        self.assertAlmostEqual(bs_price(100, 100, 1, .05, .2),
                               10.450583572185565)
        for q in (0, .02):
            strikes = np.array([80, 100, 120])
            call = bs_price(100, strikes, .5, .04, .3, q=q)
            put = bs_price(100, strikes, .5, .04, .3, "put", q=q)
            np.testing.assert_allclose(
                call - put, 100 * np.exp(-q * .5)
                - strikes * np.exp(-.04 * .5), atol=1e-12)

    def test_boundary_limits_and_mixed_arrays(self):
        with np.errstate(all="raise"):
            self.assertEqual(bs_price(100, 100, 0, .04, .2), 0)
            self.assertEqual(bs_price(100, 100, 1, 0, 0), 0)
            self.assertEqual(bs_price(90, 100, 0, .04, .2, "put"), 10)
            self.assertAlmostEqual(bs_price(100, 100, 1, .04, 0, q=.02),
                                   100 * (np.exp(-.02) - np.exp(-.04)))
            prices = bs_price(100, 100, [0, 1, 1], 0, [0, 0, .2])
            np.testing.assert_allclose(prices[:2], [0, 0])
            self.assertGreater(prices[2], 0)

    def test_invalid_inputs(self):
        for key, value in ((0, 0), (1, -1), (2, -1), (3, np.nan),
                           (4, -.2), (5, np.inf)):
            args = [100, 100, 1, .04, .2, 0]
            args[key] = value
            with self.assertRaises(ValueError):
                bs_price(*args[:5], q=args[5])
        with self.assertRaises(ValueError):
            bs_price(100, 100, 1, .04, .2, "invalid")

    def test_iv_round_trip_and_bounds(self):
        for kind in ("call", "put"):
            for vol in (.01, .2, 6):
                price = bs_price(100, 100, 1, .02, vol, kind, q=.02)
                self.assertAlmostEqual(
                    implied_vol(price, 100, 100, 1, .02, kind, q=.02),
                    vol, places=8)
        self.assertEqual(implied_vol(0, 100, 100, 1, 0), 0)
        for price in (-1, 100, 101, np.nan):
            with self.assertRaises(ValueError):
                implied_vol(price, 100, 100, 1, 0)
        with self.assertRaises(ValueError):
            implied_vol(0, 100, 100, 0, 0)

    def test_snapshot_timing_and_row_isolation(self):
        base = dict(contract="synthetic test only", kind="call", strike=100,
                    bid=1, ask=2, spot=100, r=.04, q=.02, sigma_hist=.2,
                    quote_time="2026-11-12T15:00:00-05:00",
                    valuation_time="2026-11-12T15:00:00-05:00",
                    settlement_time="2026-11-12T16:00:00-05:00")
        rows = [base, dict(base, ask=.5), dict(base, bid=np.nan),
                dict(base, bid=101, ask=102),
                dict(base, settlement_time="2026-11-12T16:00:00"),
                dict(base, settlement_time=base["valuation_time"]),
                dict(base, quote_time="2026-11-12T14:00:00-05:00")]
        result = compare_snapshot(pd.DataFrame(rows))
        self.assertEqual(result.iloc[0]["status"], "ok")
        self.assertAlmostEqual(result.iloc[0]["tau"], 1 / (365 * 24))
        self.assertTrue((result.iloc[1:]["status"] != "ok").all())
        self.assertTrue(result.iloc[1:]["iv"].isna().all())


if __name__ == "__main__":
    unittest.main()
