"""Re-implement the prior-work (expectation-based) predictors from the artifact.

Reproduces the 4+4 and 10+10 systems of table2-table3-part3.py and
table2-table-3-part4.py on the intermediate test thresholds (75, 125, ..., 975).
The decision logic is the authors'; each model is loaded once and applied to all
samples instead of one row at a time, which is much faster.

Usage: python baseline_expectation.py [threshold ...]
Each result row is appended to baseline_rows.txt, so an interrupted run resumes.
"""
import glob
import os
import sys
import numpy as np
import joblib
from my_metrics import ece_top_label, brier, nll, accuracy, mcc, confusion

# Paths are relative to mine/; the artifact is unpacked one level up.
ROOT = "../artifact/MLCAD24_paper87_risk_management/src_and_data/"
TEST = ROOT + "input_data/ttnkoi_class_75-975_by_name/"
CLS = ROOT + "ml_models/ml_models_class_default/"
REG = ROOT + "ml_models/ml_models_reg_default/"
OUT = "baseline_rows.txt"
DPS = [75 + 50 * i for i in range(19)]  # intermediate thresholds 75, 125, ..., 975

# Averages over the 19 thresholds, from table2_table3.xlsx (sheet test_intermediate_threshold).
KEY = {
    "4+4": dict(acc=0.79194507246384616, mcc=0.59864911225905748,
                ece=0.20805492789473684, brier=0.20805492753615284,
                nll=7.1859626200305398),
    "10+10": dict(acc=0.79088400435898232, mcc=0.60157272654822302,
                  ece=0.20911599526315791, brier=0.20911599564101702,
                  nll=7.2226106140442123),
}


def thr_4_4(dp):
    """Return the classifier thresholds the 4+4 system tries, in order."""
    if dp <= 150:
        return [150]
    if dp <= 250:
        return [150, 250]
    if dp <= 400:
        return [150, 250, 400]
    return [150, 250, 400, 1000]


def thr_10_10(dp):
    """Return the thresholds the 10+10 system tries: 100, 200, ... up to dp rounded up to 100."""
    limit = dp + 1 if dp % 100 == 0 else 100 * (dp // 100 + 1) + 1
    return list(range(100, limit, 100))


def load_xy(folder, dp):
    """Load features X and labels y for every circuit at decision point dp."""
    # Sorting keeps each circuit's X and y files in the same order.
    xs = sorted(glob.glob(folder + "*-%d-1_train_X.csv" % dp))
    ys = sorted(glob.glob(folder + "*-%d-1_train_y.csv" % dp))
    if not xs or len(xs) != len(ys):
        raise RuntimeError("bad file list at %d: %d X, %d y" % (dp, len(xs), len(ys)))
    # atleast_2d/atleast_1d keep a one-row file from collapsing to 1-D (numpy 1.22 has no ndmin).
    X = np.concatenate([np.atleast_2d(np.genfromtxt(f, delimiter=",", dtype=float)) for f in xs])
    y = np.concatenate([np.atleast_1d(np.genfromtxt(f, delimiter=",", dtype=int, usecols=0)) for f in ys])
    return X, y


def load_models(ts):
    """Load the default classifier and regressor for each threshold, keyed by threshold."""
    c, r = {}, {}
    for t in ts:
        c[t] = joblib.load(f"{CLS}mvto-{t}-1_gradb_class_default")
        r[t] = joblib.load(f"{REG}mvto-{t}-1_gradb_reg_default")
    return c, r


def expectation_predict(X, dp, thresholds, c, r):
    """Return an (n, 2) array of hard 0/1 class probabilities, one row per sample."""
    n = len(X)
    chosen = np.zeros(n, dtype=int)
    for t in thresholds:  # the first classifier that says "routable" wins
        take = (chosen == 0) & (c[t].predict(X) == 1)
        chosen[take] = t
    cls = np.zeros(n, dtype=int)  # samples no classifier selected stay class 0
    for t in sorted(set(chosen[chosen > 0].tolist())):
        idx = chosen == t
        remain = np.round(r[t].predict(X[idx]))
        # As in the original script, column 0 is added to the predicted remaining iterations.
        cls[idx] = ((remain + X[idx, 0]) <= dp).astype(int)
    p = np.zeros((n, 2))
    p[np.arange(n), cls] = 1.0  # one-hot: these systems output no real probabilities
    return p


def done_pairs():
    """Return the (threshold, system) pairs already written to the output file."""
    s = set()
    if os.path.exists(OUT):
        for line in open(OUT):
            f = line.strip().split(",")
            if len(f) == 11:
                s.add((int(f[0]), f[1]))
    return s


def summary():
    """Print each metric's average over finished thresholds next to the answer key."""
    rows = {"4+4": [], "10+10": []}
    for line in open(OUT):
        f = line.strip().split(",")
        if len(f) == 11:
            rows[f[1]].append([float(v) for v in f[6:11]])  # accuracy, MCC, ECE, Brier, NLL
    for name, rs in rows.items():
        if not rs:
            continue
        m = np.mean(rs, axis=0)
        print(f"\n{name}: average over {len(rs)} thresholds"
              + ("" if len(rs) == 19 else "  (PARTIAL - key average is over 19)"))
        for k, v in zip(("acc", "mcc", "ece", "brier", "nll"), m):
            print(f"  {k:6s} mine {v:.6f}  key {KEY[name][k]:.6f}  diff {v - KEY[name][k]:+.6f}")


def main():
    """Evaluate both systems at the thresholds given on the command line (default: all 19)."""
    dps = [int(a) for a in sys.argv[1:]] or DPS
    # Load every classifier and regressor either system might use.
    c, r = load_models(sorted(set([150, 250, 400, 1000]) | set(range(100, 1001, 100))))
    done = done_pairs()
    for dp in dps:
        if all((dp, s) in done for s in ("4+4", "10+10")):
            print("skip", dp)
            continue
        print("loading threshold", dp, flush=True)
        X, y = load_xy(TEST, dp)
        for name, thr in (("4+4", thr_4_4(dp)), ("10+10", thr_10_10(dp))):
            if (dp, name) in done:
                continue
            p = expectation_predict(X, dp, thr, c, r)
            tn, fp, fn, tp = confusion(p, y)
            # Row layout: threshold, system, TP, TN, FP, FN, accuracy, MCC, ECE, Brier, NLL.
            row = [dp, name, tp, tn, fp, fn, accuracy(p, y), mcc(p, y),
                   ece_top_label(p, y), brier(p, y), nll(p, y)]
            print("  ", row, flush=True)
            with open(OUT, "a") as f:
                f.write(",".join(str(v) for v in row) + "\n")
    summary()


if __name__ == "__main__":
    main()