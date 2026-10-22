"""Estimate Table 4's time-control RMSE from the plotted Figure 5 data.

Reads Figure5.xlsx with the standard library (no pandas) and compares each system's
average route time with the user's time budget. Routing control cannot be computed
because the sheet has no requested completion rates.
"""
import re
import zipfile
import xml.etree.ElementTree as ET
import numpy as np

NS = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
P = "../artifact/MLCAD24_paper87_risk_management/paper_tables_and_figures/Figure5.xlsx"


def read_rows(path, first_row=3):
    """Return the numeric rows of the first sheet as an array with columns A to E."""
    z = zipfile.ZipFile(path)
    sheet = ET.fromstring(z.read("xl/worksheets/sheet1.xml"))
    out = []
    for row in sheet.iter(NS + "row"):
        if int(row.get("r")) < first_row:  # rows 1-2 hold headers
            continue
        vals = {}
        for c in row.findall(NS + "c"):
            v = c.find(NS + "v")
            if v is not None and c.get("t") not in ("s", "str", "inlineStr"):  # skip text cells
                vals[re.match(r"[A-Z]+", c.get("r")).group()] = float(v.text)
        if all(k in vals for k in "ABCDE"):
            out.append([vals[k] for k in "ABCDE"])
    return np.array(out)


# Columns: time budget, then average route time and completion rate for each system.
budget, conf_t, expt_t, conf_r, expt_r = read_rows(P).T
rmse = lambda a, b: float(np.sqrt(np.mean((a - b) ** 2)))
print("points:", len(budget))
print("time RMSE (h):  conf %.1f   expt %.1f   ratio %.2f"
      % (rmse(conf_t, budget), rmse(expt_t, budget),
         rmse(expt_t, budget) / rmse(conf_t, budget)))
# Negative means finishing under budget, positive means over.
print("mean signed error (h):  conf %+.1f   expt %+.1f"
      % (np.mean(conf_t - budget), np.mean(expt_t - budget)))
print("paper: 143 h vs 273 h, ratio %.2f" % (273 / 143))