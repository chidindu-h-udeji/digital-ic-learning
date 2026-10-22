"""Compare my metrics on the retrained threshold-500 test predictions with the answer key."""
import numpy as np
from my_metrics import ece_top_label, brier, nll, accuracy, mcc

d = np.load("../artifact/MLCAD24_paper87_risk_management/src_and_data/"
            "Table2_Table3_Figure3/preds_500.npz")
# Key row for threshold 500 (table2_table3.xlsx, sheet test_regular_threshold, row 13).
key = dict(ece=0.03589054, brier=0.135924022249819, nll=0.41550749905356099,
           acc=0.79640277322088404, mcc=0.60620056860785598)
p, y = d["p_test"], d["y_test"]
mine = dict(ece=ece_top_label(p, y), brier=brier(p, y), nll=nll(p, y),
            acc=accuracy(p, y), mcc=mcc(p, y))
for k in key:
    print(f"{k:6s} mine {mine[k]:.6f}  key {key[k]:.6f}  diff {mine[k]-key[k]:+.6f}")