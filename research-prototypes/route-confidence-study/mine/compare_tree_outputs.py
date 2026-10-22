"""Compare each tree's output in the retrained and saved models on a few circuits."""
import glob
import joblib
import numpy as np

D = "../artifact/MLCAD24_paper87_risk_management/src_and_data/"
a = joblib.load(D + "Table2_Table3_Figure3/retrained_500.joblib")
b = joblib.load(D + "ml_models/ml_models_class_6_30_numpy_1_22/mvto-500-1_gradb_class_6d30t")


def rows(folder, n_files):
    """Return the stacked feature rows of the first n_files circuits and their file names."""
    files = sorted(glob.glob(D + "input_data/" + folder + "/*-500-1_train_X.csv"))[:n_files]
    X = np.concatenate([np.atleast_2d(np.genfromtxt(f, delimiter=",", dtype=float)) for f in files])
    return X, [f.split("/")[-1] for f in files]


for label, folder in (("train", "circuit_split_train_data_for_cv"),
                      ("test", "ttnkoi_class_50-1000_by_name")):
    X, names = rows(folder, 3)  # three circuits keep the run short
    print(f"[{label}] {len(X)} rows from {names}")
    differs = []
    for i in range(30):
        d = np.abs(a.estimators_[i, 0].predict(X) - b.estimators_[i, 0].predict(X)).max()
        if d > 1e-9:
            differs.append((i, round(float(d), 4)))
    print("  trees whose outputs differ on these rows:", differs or "none")
    # decision_function is the ensemble's raw score before the sigmoid.
    print("  ensemble raw-score max diff: %.3e" %
          np.abs(a.decision_function(X) - b.decision_function(X)).max())