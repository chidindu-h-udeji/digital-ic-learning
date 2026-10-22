"""
my_metrics.py - calibration metrics and MoE interpolation, numpy only.

Conventions copied from the authors' table2-table3-part1.py so the numbers match:
  * p is an (N, 2) array of class probabilities [P(class 0), P(class 1)]
  * y is an (N,) array of 0/1 labels
  * ECE is "top-label": confidence = max(p), compared with whether the argmax was right
  * bins are (lower, upper], 20 bins by default
"""
import sys
import numpy as np

EPS = 1e-15  # clip so log(0) never happens (sklearn does the same)


# ---------------------------------------------------------------- helpers
def two_col(p1):
    """Turn P(class 1) values into an (N, 2) array [1 - p1, p1]."""
    p1 = np.asarray(p1, dtype=float)
    return np.column_stack([1.0 - p1, p1])


def _check(p, y):
    p = np.asarray(p, dtype=float)
    y = np.asarray(y).astype(int)
    if p.ndim != 2 or p.shape[1] != 2:
        raise ValueError("p must have shape (N, 2)")
    if len(p) != len(y):
        raise ValueError("p and y must have the same length")
    return p, y


# ---------------------------------------------------------------- Equation 1
def ece_top_label(p, y, bins=20):
    """Expected calibration error, authors' version (confidence = max class prob)."""
    p, y = _check(p, y)
    conf = p.max(axis=1)                      # confidence of the predicted class
    pred = p.argmax(axis=1)                   # predicted class (ties go to class 0)
    correct = (pred == y).astype(float)       # 1 if the prediction was right

    edges = np.linspace(0.0, 1.0, bins + 1)
    n = len(y)
    total = 0.0
    for lo, hi in zip(edges[:-1], edges[1:]):
        in_bin = (conf > lo) & (conf <= hi)
        k = int(in_bin.sum())
        if k > 0:
            gap = abs(conf[in_bin].mean() - correct[in_bin].mean())
            total += (k / n) * gap            # |B_m| / N * |acc - conf|
    return total


def ece_positive_class(p1, y, bins=20):
    """Variant from Part 3: compare P(class 1) with the actual class-1 rate per bin."""
    p1 = np.asarray(p1, dtype=float)
    y = np.asarray(y).astype(float)
    edges = np.linspace(0.0, 1.0, bins + 1)
    n = len(y)
    total = 0.0
    for lo, hi in zip(edges[:-1], edges[1:]):
        in_bin = (p1 > lo) & (p1 <= hi)
        k = int(in_bin.sum())
        if k > 0:
            total += (k / n) * abs(p1[in_bin].mean() - y[in_bin].mean())
    return total


# ---------------------------------------------------------------- Equation 2
def brier(p, y):
    """Mean squared difference between P(class 1) and the 0/1 outcome."""
    p, y = _check(p, y)
    return float(np.mean((p[:, 1] - y) ** 2))


# ---------------------------------------------------------------- Equation 3
def nll(p, y):
    """Negative log-likelihood: average of -log(probability given to the true class)."""
    p, y = _check(p, y)
    p_true = p[np.arange(len(y)), y]
    p_true = np.clip(p_true, EPS, 1.0)
    return float(-np.mean(np.log(p_true)))


# ---------------------------------------------------------------- Appendix A
def confusion(p, y):
    """Return (tn, fp, fn, tp) using the argmax prediction."""
    p, y = _check(p, y)
    pred = p.argmax(axis=1)
    tp = int(np.sum((pred == 1) & (y == 1)))
    tn = int(np.sum((pred == 0) & (y == 0)))
    fp = int(np.sum((pred == 1) & (y == 0)))
    fn = int(np.sum((pred == 0) & (y == 1)))
    return tn, fp, fn, tp


def accuracy(p, y):
    tn, fp, fn, tp = confusion(p, y)
    return (tp + tn) / (tp + tn + fp + fn)


def mcc(p, y):
    tn, fp, fn, tp = confusion(p, y)
    num = float(tp) * float(tn) - float(fp) * float(fn)
    den = np.sqrt(float(tp + fp) * float(tp + fn) * float(tn + fp) * float(tn + fn))
    return num / den if den > 0 else 0.0


# ---------------------------------------------------------------- Equation 4
def moe_interpolate(preds, imax, step=50):
    """
    preds: probabilities from the experts, preds[0] for threshold 50, preds[1] for 100, ...
    imax:  the user's iteration limit, between `step` and `step * len(preds)`
    Returns the probability that routing completes within imax iterations.
    """
    preds = list(preds)
    top = step * len(preds)
    if not (step <= imax <= top):
        raise ValueError(f"imax must be between {step} and {top}")

    if imax % step == 0:                      # exact multiple: one model, no blending
        return float(preds[int(imax // step) - 1])

    l = int(imax // step)                     # floor
    u = l + 1                                 # ceil
    zl, zu = l * step, u * step               # thresholds of the lower and upper experts
    fl, fu = preds[l - 1], preds[u - 1]
    return ((zu - imax) * fl + (imax - zl) * fu) / ((zu - imax) + (imax - zl))


# ================================================================ tests
def _report(name, got, want, tol):
    ok = abs(got - want) <= tol
    print(f"{'PASS' if ok else 'FAIL'}  {name:34s} got {got:.6f}  want {want:.6f}")
    return ok


def self_tests():
    print("--- self-tests (hand-worked examples) ---")
    p1 = np.array([0.15, 0.10, 0.20, 0.12, 0.85, 0.90, 0.80, 0.88, 0.95, 0.82])
    y = np.array([0, 0, 1, 0, 1, 1, 0, 1, 1, 1])
    p = two_col(p1)
    ok = True
    ok &= _report("Brier, 10-prediction example", brier(p, y), 0.14087, 1e-4)
    ok &= _report("NLL, 10-prediction example", nll(p, y), 0.42600, 1e-3)
    ok &= _report("ECE positive-class, 2 bins", ece_positive_class(p1, y, bins=2), 0.063, 1e-4)
    ok &= _report("ECE top-label, 2 bins", ece_top_label(p, y, bins=2), 0.063, 1e-4)

    # perfectly calibrated example: says 0.9, right 90% of the time -> ECE 0
    pc = two_col(np.full(10, 0.9))
    yc = np.array([1] * 9 + [0])
    ok &= _report("ECE calibrated (0.9, 90% right)", ece_top_label(pc, yc, bins=20), 0.0, 1e-9)

    # Equation 4 worked example: limit 120, f2 (100) = 0.70, f3 (150) = 0.50 -> 0.62
    experts = [0.0] * 20
    experts[1], experts[2] = 0.70, 0.50
    ok &= _report("MoE interpolation, limit 120", moe_interpolate(experts, 120), 0.62, 1e-9)
    experts[5] = 0.33
    ok &= _report("MoE exact threshold 300 -> f6", moe_interpolate(experts, 300), 0.33, 1e-9)

    # always-predict-negative baseline: accuracy = base rate, MCC = 0
    p_neg = two_col(np.zeros(100))
    y_base = np.array([1] * 27 + [0] * 73)
    ok &= _report("accuracy, always-negative (73/27)", accuracy(p_neg, y_base), 0.73, 1e-9)
    ok &= _report("MCC, always-negative", mcc(p_neg, y_base), 0.0, 1e-9)
    ex = [0.0] * 20
    ex[0], ex[1] = 0.2, 0.6                       # f1 (50) and f2 (100)
    ok &= _report("MoE limit 75 (midpoint)", moe_interpolate(ex, 75), 0.4, 1e-12)
    ex[18], ex[19] = 0.3, 0.9                     # f19 (950) and f20 (1000)
    ok &= _report("MoE limit 975 (midpoint)", moe_interpolate(ex, 975), 0.6, 1e-12)
    ok &= _report("midpoint = plain mean", moe_interpolate(ex, 975), (0.3 + 0.9) / 2, 1e-12)
    rng = np.random.default_rng(0)
    y_h = rng.integers(0, 2, 10000)
    wrong = rng.random(10000) < 0.2
    pred_h = np.where(wrong, 1 - y_h, y_h)
    p_h = two_col(pred_h.astype(float))
    err = float(np.mean(pred_h != y_h))
    ok &= _report("hard predictor: ECE = error rate", ece_top_label(p_h, y_h), err, 1e-9)
    ok &= _report("hard predictor: Brier = error rate", brier(p_h, y_h), err, 1e-9)
    ok &= _report("hard predictor: NLL = err*34.54", nll(p_h, y_h), err * -np.log(EPS), 1e-6)
    return ok


# authors' printed values for threshold 500 (from run_500.log)
REFERENCE_500 = {
    "train": dict(ece=0.05026567, brier=0.03047976344906063, nll=0.12376245957043705,
                  acc=0.9641266722799139, mcc=0.8929825283716054),
    "test": dict(ece=0.03587501, brier=0.13570528136343044, nll=0.4149422357851334,
                 acc=0.7970051796193006, mcc=0.6071849645960535),
}


def check_against_artifact(path):
    print(f"\n--- check against the artifact, threshold 500 ({path}) ---")
    d = np.load(path)
    ok = True
    for split in ("train", "test"):
        p, y, ref = d[f"p_{split}"], d[f"y_{split}"], REFERENCE_500[split]
        print(f"[{split}]  N = {len(y)}")
        ok &= _report(f"{split} ECE", ece_top_label(p, y, 20), ref["ece"], 1e-6)
        ok &= _report(f"{split} Brier", brier(p, y), ref["brier"], 1e-6)
        ok &= _report(f"{split} NLL", nll(p, y), ref["nll"], 1e-6)
        ok &= _report(f"{split} accuracy", accuracy(p, y), ref["acc"], 1e-6)
        ok &= _report(f"{split} MCC", mcc(p, y), ref["mcc"], 1e-6)
        tn, fp, fn, tp = confusion(p, y)
        print(f"        TN {tn}  FP {fp}  FN {fn}  TP {tp}")
    return ok


if __name__ == "__main__":
    all_ok = self_tests()
    path = (sys.argv[1] if len(sys.argv) > 1 else
            "../artifact/MLCAD24_paper87_risk_management/src_and_data/"
            "Table2_Table3_Figure3/preds_500.npz")
    try:
        all_ok &= check_against_artifact(path)
    except FileNotFoundError:
        print(f"\n(no {path} yet - the artifact check was skipped)")
    print("\nALL PASS" if all_ok else "\nSOMETHING FAILED")
