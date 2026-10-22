"""Compare the retrained and saved threshold-500 trees node by node.

Equal node sizes and leaf values with different split features suggest the same
partition of the training data reached through tied splits. This is not a proof.
Requires retrained_500.joblib (see test_retrain_save.py).
"""
import joblib
import numpy as np

D = ("../artifact/MLCAD24_paper87_risk_management/src_and_data/"
     "Table2_Table3_Figure3/")
a = joblib.load(D + "retrained_500.joblib")
b = joblib.load(D + "../ml_models/ml_models_class_6_30_numpy_1_22/"
                "mvto-500-1_gradb_class_6d30t")

identical = same_partition = other = 0
for i in range(a.estimators_.shape[0]):
    ta, tb = a.estimators_[i, 0].tree_, b.estimators_[i, 0].tree_
    if ta.node_count != tb.node_count:
        other += 1
        print(f"tree {i:2d}: different size ({ta.node_count} vs {tb.node_count} nodes)")
        continue
    feat = np.array_equal(ta.feature, tb.feature)
    thr = np.allclose(ta.threshold, tb.threshold, rtol=0, atol=1e-9)
    samples = np.array_equal(ta.n_node_samples, tb.n_node_samples)
    val = float(np.abs(ta.value - tb.value).max())
    if feat and thr and samples and val < 1e-9:
        identical += 1
    elif samples and val < 1e-9:
        same_partition += 1
        print(f"tree {i:2d}: different split features/thresholds, SAME node sizes and leaf values")
    else:
        # Nodes are compared by position, so a reordered but equal tree lands here too.
        other += 1
        print(f"tree {i:2d}: differs (node sizes equal: {samples}, leaf diff {val:.2e})")

print(f"\nidentical (within 1e-9): {identical}")
print(f"different splits, same node sizes/values: {same_partition}")
print(f"genuinely different: {other}")