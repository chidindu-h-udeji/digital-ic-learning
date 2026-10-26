# route-confidence-study: reproducing and probing ML confidence for FPGA routability

*Built with AI assistance; see [../README.md](../README.md).*

A learning exercise on *Enabling Risk Management of Machine Learning Predictions for FPGA Routability* (Gunter, Thomas, Ghanathe, Wilton; [MLCAD '24](https://doi.org/10.1145/3670474.3685969)). I ran the authors' [Zenodo artifact](https://zenodo.org/doi/10.5281/zenodo.13118004), checked its results against the paper and the artifact's answer-key spreadsheets, and wrote numpy-only versions of the calibration metrics and the mixture-of-experts interpolation, checked against the authors' code. The aim was to understand how the paper's numbers are built, not to extend the paper.

**What I found.** The test halves of Tables 2 and 3 reproduce exactly (six decimals against the answer key, which agrees with the paper's printed values) for the confidence-based system and both prior-work baselines, using the artifact's saved models. Table 2's train half matches at threshold 500 but was not recomputed over all 20. Table 4 reproduces only approximately: from the plotted Figure 5 data, time-budget RMSE is 94.5 h vs 201.9 h (ratio 2.14), against the paper's 143 h vs 273 h (ratio 1.91). Routing control (22% vs 38%) cannot be computed from the artifact.

## Implementation and attribution

- **Authors'** (CC BY 4.0, per the artifact appendix): everything under `artifact/` (scripts, data, saved models, answer-key spreadsheets). Their scripts are unmodified; patched copies and outputs sit alongside them. `artifact/` is not committed.
- **Mine (`mine/`):**
  - `my_metrics.py`: ECE, Brier, NLL, accuracy, MCC and Equation 4 in numpy, with self-tests and a check against the authors' printed values.
  - `baseline_expectation.py`: vectorised reimplementation of the prior-work predictors in parts 3 and 4 (same decision logic, each model loaded once).
  - `moe_real_models.py`: Equation 4 on the saved models at 450 and 500.
  - `compare_*.py`, `diff_summary.py`: comparisons with the answer key and between retrained and saved models; `compare_ece_variants.py`, `reliability_500.py`: ECE binning study and reliability table.
  - `table4_check.py`, `dump_xlsx.py`: Table 4 estimate, and a spreadsheet reader that needs no pandas.
- **`mine/outputs/`:** saved output of each check, including `baseline.log`, `part2.log` (the authors' part 2 script, run by me) and `run_500.log` (the threshold-500 run whose values `my_metrics.py` checks against).

## Setup

| Item | Setting |
|---|---|
| Machine | WSL2 Ubuntu, about 3.8 GB RAM, 916 GB free disk |
| Environment | Miniforge conda, env `mlcad_87` from `mlcad_87.yml` |
| Versions | Python 3.10.13, scikit-learn 1.0.1, numpy 1.22.3 |
| Artifact | 5.4 GB zip, about 24 GB extracted, 11,796 files |
| Cost | Retraining one threshold took 8m45s; all 20 would take about 3 hours (estimate, not run) |

## Reproducing

Unzip the artifact to `./artifact/` (not included). Run each script from its own folder: the authors' scripts use relative paths, although their README says to run from the top level. Run one step at a time and wait for each background job to finish (`pgrep -a python`).

```bash
cd artifact/MLCAD24_paper87_risk_management
conda env create -f mlcad_87.yml && conda activate mlcad_87
cd src_and_data/Table2_Table3_Figure3
nohup env MPLBACKEND=Agg python table2-table3-part2.py > part2.log 2>&1 &   # confidence-based test rows (saved models)
```

For the threshold-500 predictions my checks use, make a patched copy of part 1:

```bash
cp table2-table3-part1.py test_one_threshold.py
sed -i "s/^decision_points_list = .*/decision_points_list = ['500']/" test_one_threshold.py
sed -i '/class_proba_test_array = clf.predict_proba/a\            np.savez("preds_500.npz", p_train=class_proba_train_array, y_train=data_train_y_class, p_test=class_proba_test_array, y_test=data_test_y_class)' test_one_threshold.py
MPLBACKEND=Agg python test_one_threshold.py
```

Two more patched copies produce the other inputs:

```bash
# saved-model predictions (for compare_saved_vs_retrained.py and diff_summary.py)
sed -e "s#clf = gb.fit(data_train_X_class, data_train_y_class)#clf = joblib.load('../ml_models/ml_models_class_6_30_numpy_1_22/mvto-500-1_gradb_class_6d30t')#" \
    -e "s#preds_500.npz#preds_500_saved.npz#" test_one_threshold.py > test_saved_500.py
MPLBACKEND=Agg python test_saved_500.py

# retrained model written to disk (for compare_trees.py and compare_tree_outputs.py)
sed -e 's#\#joblib.dump(clf, save_file_name)#joblib.dump(clf, "retrained_500.joblib")#' \
    -e 's#preds_500.npz#preds_500_re2.npz#' test_one_threshold.py > test_retrain_save.py
MPLBACKEND=Agg python test_retrain_save.py
```

Then, from `mine/`:

```bash
python my_metrics.py            # self-tests + threshold-500 check against the authors' values
python compare_part2.py         # part2.log averages vs the answer key
python baseline_expectation.py  # prior-work rows, resumable (writes baseline_rows.txt)
python moe_real_models.py       # Equation 4 at limit 475
python table4_check.py          # Table 4 time-control estimate
```

## Results

| Item | Paper | This repro | Status |
|---|---|---|---|
| Table 2 test, ours: ECE / Brier / NLL | 5.8% / 0.128 / 0.39 | 0.0584 / 0.1283 / 0.3920 | Exact (part 2, saved models) |
| Table 3, ours: accuracy / MCC | 80.4% / 0.605 | 0.8042 / 0.6052 | Exact (part 2) |
| Prior work 4+4: ECE / NLL, acc / MCC | 20.8% / 7.18, 79.2% / 0.599 | 0.2081 / 7.1860, 0.7919 / 0.5986 | Exact |
| Prior work 10+10: ECE / NLL, acc / MCC | 20.9% / 7.22, 79.1% / 0.602 | 0.2091 / 7.2226, 0.7909 / 0.6016 | Exact |
| Equation 4 on real models, limit 475 | key row | all five metrics equal to 6 decimals | Exact |
| Table 2 train, ours, threshold 500 | 5% / 0.03 / 0.12 (20-threshold average) | 0.0503 / 0.0305 / 0.1238 | Exact against the key's row; the average was not recomputed |
| Test, ours, threshold 500, retrained | key row: acc 0.7964, MCC 0.6062 | acc 0.7970, MCC 0.6072 | Approximate; the saved model matches the key exactly |
| Table 4 time control | 143 h / 273 h (ratio 1.91) | 94.5 h / 201.9 h (ratio 2.14), from plotted Figure 5 averages | Approximate |
| Table 4 routing control | 22% / 38% | not computable | Requested completion rates are not in the artifact |
| Figures 3 and 5 | | not attempted | The artifact provides the underlying data only |

- Train metrics in the paper average over the 20 regular thresholds (50 to 1000); test metrics over the 19 intermediate ones (75 to 975).
- Both baselines match the key's 19-threshold averages on all five metrics, and confusion counts match row by row at the thresholds I checked (75, 125, 375, 975).
- Limit 475 sits midway between models 450 and 500, so its plain and distance-weighted blends coincide; the unequal-weight case is covered only by a hand example (limit 120 gives 0.62).

## Against the paper

**Exact matches** come from the authors' saved models or from my vectorised reimplementation of their logic. My metric code passes 15 self-tests (hand-worked examples) and matches the authors' printed values on 10 checks at threshold 500 (to 1e-6).

**Approximate:**
- **Retrained model at threshold 500.** Train probabilities equal the saved model's (max difference 0.000000), but test probabilities differ by up to 0.111: 3.86% of samples differ at all, and 188 predicted classes flip. Of 30 trees, 12 are identical and 10 more reach the same node sizes and leaf values with different split features; the other 8 were not classified cleanly by my comparison. This is consistent with ties between equivalent splits; I did not prove it.
- **Table 4 time control.** The direction and the roughly 2× ratio agree, but the absolute values differ, plausibly because Figure 5 shows averages, in which over- and under-shoots cancel before the RMSE (untested). The confidence-based system finishes 84.6 h under budget on average, the expectation-based one 132.7 h over.

## Findings

- **ECE depends on the binning.** The authors use top-label ECE with 20 bins. On the threshold-500 test set, 10 to 50 bins moves it from 0.029 to 0.041 (positive-class variant: 0.038 to 0.052), because over- and under-confident bins cancel inside wide bins. Train ECE does not change with the bin count.
- **Underconfident on train, overconfident in the middle on test.** Train mean confidence is 0.914 against accuracy 0.964, with every bin negative. On test, bins from 0.55 to 0.80 are overconfident by 0.05 to 0.12, while the signed average is only +0.026, so cancellation hides it.
- **Hard 0/1 predictors collapse the metrics.** A predictor outputting exactly 0 or 1 has ECE = Brier = error rate and NLL = error rate × 34.54 (the sklearn clipping constant), so part of the headline gap is probabilistic versus hard predictions, as Section 4.1 notes.
- **Part 2 uses two blends.** Accuracy and MCC use the distance-weighted blend; ECE, Brier and NLL a plain 50/50 mean. They coincide at the midpoint thresholds used.

## Limitations

- Baseline rows come from my vectorised reimplementation, not the authors' per-sample scripts. It matches their answer key but is a different program.
- Only threshold 500 was retrained and compared; the 20-threshold train average was not recomputed.
- Table 4 time control is approximated from averaged points, and the sheet's "Expt." column is not confirmed to be the "Enhanced" system.
- The tree-output check used three circuits per set, and the tree comparison cannot tell reordered nodes from different splits.
- Numbers come from scikit-learn 1.0.1 and numpy 1.22.3; other versions may differ.

## Appendix: artifact notes

- **Naming mismatches.** The artifact README names `environment_file.yml`, but the file is `mlcad_87.yml`; `table2-table-3-part4.py` has an extra hyphen; the zip adds a nesting level, so the root is `artifact/MLCAD24_paper87_risk_management/`.
- **Scripts.** Part 1 retrains all 20 models from raw CSVs (about 9 min per threshold); part 2 uses the saved models for the confidence-based test rows; parts 3 and 4 are the 4+4 and 10+10 baselines, which load models inside the per-sample loop (hence my vectorised version).
- **Spreadsheet typo.** `table2_table3.xlsx`, sheet `test_regular_threshold`, cell K32 reads 2.01E-3 where the row implies 0.201.
- **Part 2 limitation (from reading the code, not run).** `table2-table3-part2.py` assigns `predicted_class_proba_array` only in its intermediate-threshold branch but uses it after the `if`/`else`. A multiple of 50 as the first threshold would raise a `NameError`; later in the list it would silently reuse the previous threshold's probabilities.