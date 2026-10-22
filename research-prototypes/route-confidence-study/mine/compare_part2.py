"""Average part2.log's per-threshold rows and compare them with the answer key."""
import re

LOG = ("../artifact/MLCAD24_paper87_risk_management/src_and_data/"
       "Table2_Table3_Figure3/part2.log")
# Averages over the 19 intermediate thresholds (table2_table3.xlsx,
# sheet test_intermediate_threshold, row 23).
KEY = dict(acc=0.80420420476984655, mcc=0.60524246117918989,
           ece=0.058401997894736837, brier=0.12828736805836261,
           nll=0.39198580000710498)

rows = []
for line in open(LOG):
    if re.match(r"^\d+,", line):  # result rows start with the threshold
        f = [x.strip("[] \n") for x in line.split(",")]  # ECE is printed as "[0.0942]"
        rows.append([float(v) for v in f])

print("rows parsed:", len(rows), "(expect 19)")
names = ["acc", "mcc", "ece", "brier", "nll"]
for name, col in zip(names, range(5, 10)):  # columns: threshold, TP, TN, FP, FN, then the metrics
    mean = sum(r[col] for r in rows) / len(rows)
    print(f"{name:6s} mine {mean:.6f}  key {KEY[name]:.6f}  diff {mean - KEY[name]:+.6f}")