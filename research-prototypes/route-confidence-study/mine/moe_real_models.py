"""Check Equation 4 on real models: blend the saved 450 and 500 models at limit 475.

Compares the blended predictions' metrics with the answer key's row for 475
(table2_table3.xlsx, sheet test_intermediate_threshold).
"""
import joblib
from my_metrics import (two_col, moe_interpolate, ece_top_label, brier, nll,
                        accuracy, mcc)
from baseline_expectation import load_xy, ROOT, TEST

M = ROOT + "ml_models/ml_models_class_6_30_numpy_1_22/"
f450 = joblib.load(M + "mvto-450-1_gradb_class_6d30t")
f500 = joblib.load(M + "mvto-500-1_gradb_class_6d30t")

X, y = load_xy(TEST, 475)
print("rows:", len(y))

# Expert i (0-based) answers for threshold 50 * (i + 1), so 450 is index 8 and 500 is index 9.
experts = [None] * 20
experts[8] = f450.predict_proba(X)[:, 1]
experts[9] = f500.predict_proba(X)[:, 1]
p = two_col(moe_interpolate(experts, 475))

# Key row for threshold 475, copied from the answer-key spreadsheet.
KEY = dict(acc=0.79058766848796003, mcc=0.60847467477213402,
           ece=0.055009080, brier=0.139458643448921, nll=0.419691940044082)
mine = dict(acc=accuracy(p, y), mcc=mcc(p, y), ece=ece_top_label(p, y),
            brier=brier(p, y), nll=nll(p, y))
for k in KEY:
    print(f"{k:6s} mine {mine[k]:.6f}  key {KEY[k]:.6f}  diff {mine[k] - KEY[k]:+.6f}")