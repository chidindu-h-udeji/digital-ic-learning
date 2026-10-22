"""Compare top-label and positive-class ECE on the threshold-500 predictions at several bin counts."""
import numpy as np
from my_metrics import ece_top_label, ece_positive_class

d = np.load("../artifact/MLCAD24_paper87_risk_management/src_and_data/"
            "Table2_Table3_Figure3/preds_500.npz")

for split in ("train", "test"):
    p, y = d[f"p_{split}"], d[f"y_{split}"]
    print(f"[{split}]")
    for bins in (10, 20, 50):  # the authors use 20
        print("  bins=%2d   top-label %.4f   positive-class %.4f"
              % (bins, ece_top_label(p, y, bins), ece_positive_class(p[:, 1], y, bins)))