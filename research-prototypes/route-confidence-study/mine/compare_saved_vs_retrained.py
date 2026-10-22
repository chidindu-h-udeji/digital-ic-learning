"""Compare the retrained threshold-500 model with the saved one, then check the saved model against the key."""
import numpy as np
from my_metrics import ece_top_label, brier, nll, accuracy, mcc

D = ("../artifact/MLCAD24_paper87_risk_management/src_and_data/"
     "Table2_Table3_Figure3/")
a = np.load(D + "preds_500.npz")        # predictions from the retrained model
b = np.load(D + "preds_500_saved.npz")  # predictions from the saved model in ml_models

for split in ("train", "test"):
    pa, pb = a[f"p_{split}"], b[f"p_{split}"]
    print(f"[{split}] labels equal: {np.array_equal(a[f'y_{split}'], b[f'y_{split}'])}"
          f"   max |p_retrained - p_saved| = {np.abs(pa - pb).max():.6f}")

# Key row for threshold 500 (table2_table3.xlsx, sheet test_regular_threshold, row 13).
KEY = dict(ece=0.03589054, brier=0.135924022249819, nll=0.41550749905356099,
           acc=0.79640277322088404, mcc=0.60620056860785598)
p, y = b["p_test"], b["y_test"]
mine = dict(ece=ece_top_label(p, y), brier=brier(p, y), nll=nll(p, y),
            acc=accuracy(p, y), mcc=mcc(p, y))
print("\nsaved model on test vs the key's threshold-500 row:")
for k in KEY:
    print(f"  {k:6s} mine {mine[k]:.6f}  key {KEY[k]:.6f}  diff {mine[k] - KEY[k]:+.6f}")