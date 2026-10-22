import json, os, subprocess
from pathlib import Path
from run_sweep import yosys_stats, OFF, WORK, FLAGS

pir = WORK / "u32_ug1_s1.pir"
variants = {
  "authors_json_exact": dict(num_cols=4, char_per_col=5, col_per_file=4, custom=[]),
  "harness_plus_cpf4":  dict(num_cols=4, char_per_col=5, col_per_file=4,
                             data_width=80, max_width=80, custom=[]),
}
for name, c in variants.items():
    cfg = WORK / f"chk_{name}.json"; cfg.write_text(json.dumps(c))
    d = WORK / f"chk_{name}"
    try:
        subprocess.run(["python3", "engine/tools/build_rtl_countluts.py", "-c", str(cfg),
                        "-m", str(pir), "-o", str(d), *FLAGS],
                       cwd=OFF, env={**os.environ, "PYTHONPATH": "engine"}, check=True)
        print(name, yosys_stats(d))
    except Exception as e:
        print(name, "FAILED:", e)