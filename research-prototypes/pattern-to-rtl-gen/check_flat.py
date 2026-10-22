import json, os, subprocess
from run_sweep import yosys_stats, OFF, WORK, FLAGS

pir = WORK / "u32_ug1_s1.pir"   # pattern file left by the most recent run_sweep.py run (u=32, ug=1, seed 1)
cfg_dict = dict(num_cols=1, char_per_col=20, col_per_file=1, custom=[])  # authors' one_group.json

cfg = WORK / "chk_flat.json"
cfg.write_text(json.dumps(cfg_dict))
d = WORK / "chk_flat"

subprocess.run(["python3", "engine/tools/build_rtl_countluts.py", "-c", str(cfg),
                "-m", str(pir), "-o", str(d), *FLAGS],
               cwd=OFF, env={**os.environ, "PYTHONPATH": "engine"}, check=True)
print("flat_exact", yosys_stats(d))