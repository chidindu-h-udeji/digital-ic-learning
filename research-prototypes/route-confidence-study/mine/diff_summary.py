"""Summarize how the retrained and saved threshold-500 models differ on the test set."""
import numpy as np

D = ("../artifact/MLCAD24_paper87_risk_management/src_and_data/"
     "Table2_Table3_Figure3/")
a = np.load(D + "preds_500.npz")
b = np.load(D + "preds_500_saved.npz")

pa, pb = a["p_test"], b["p_test"]
d = np.abs(pa[:, 1] - pb[:, 1])  # difference in P(class 1) per sample
n = len(d)
print("test samples:", n)
for t in (1e-6, 1e-3, 1e-2, 5e-2, 1e-1):
    print(f"  |diff| > {t:g}: {(d > t).sum():7d}  ({(d > t).mean() * 100:.2f}%)")
flips = int((pa.argmax(1) != pb.argmax(1)).sum())
print("predicted class differs on", flips, "samples")
print("mean |diff| over all samples: %.6f" % d.mean())