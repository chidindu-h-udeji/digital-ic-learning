"""Print a reliability table (confidence vs accuracy per bin) for the threshold-500 predictions."""
import numpy as np

d = np.load("../artifact/MLCAD24_paper87_risk_management/src_and_data/"
            "Table2_Table3_Figure3/preds_500.npz")
edges = np.linspace(0.0, 1.0, 21)  # 20 bins, as in the authors' ECE

for split in ("train", "test"):
    p, y = d[f"p_{split}"], d[f"y_{split}"]
    conf = p.max(axis=1)  # top-label confidence is never below 0.5
    correct = (p.argmax(axis=1) == y).astype(float)
    print(f"\n[{split}] mean confidence {conf.mean():.4f}   accuracy {correct.mean():.4f}"
          f"   difference {conf.mean() - correct.mean():+.4f}")
    print("   bin               n   share   conf    acc    gap(conf-acc)")
    for lo, hi in zip(edges[:-1], edges[1:]):
        m = (conf > lo) & (conf <= hi)  # (lower, upper], as in the authors' code
        if m.any():
            print(f"   ({lo:.2f},{hi:.2f}] {m.sum():8d} {m.mean():7.3f} "
                  f"{conf[m].mean():6.3f} {correct[m].mean():6.3f} "
                  f"{conf[m].mean() - correct[m].mean():+9.3f}")