# Physical Design Analysis Scripts

This directory contains custom Python utilities developed to extract, parse, and compare timing and physical design metrics from synthesis runs.

### `parse_path_details.py`
A regex-based parser for raw text timing reports (`.rpt`).
* **Functionality:** Extracts startpoints, endpoints, slack values, and path status (MET/VIOLATED).
* **Output:** Generates a formatted terminal table and exports a `results.csv` for external analysis.
* **Usage:** `python3 parse_path_details.py <path_to_report.rpt>`

### `parse_timing.py`
A JSON comparator for evaluating Performance and Area metrics across different physical design runs.
* **Functionality:** Reads `metrics.json` files (supports direct files or run directories with `final/` fallback) to compare Setup WNS, electrical violations (max fanout, max slew, max capacitance), die area, and logic utilization.
* **Sanity Checks:** Automatically flags unexpected architectural changes (e.g., die area or utilization shifts) across constraint iterations.
* **Note:** When comparing an RTL baseline against a macro integration run, the [WARN] flags for Die Area and Utilization changes are expected, since these differ by design.
* **Usage:** `python3 parse_timing.py <run_dir_or_json_1> <run_dir_or_json_2>`