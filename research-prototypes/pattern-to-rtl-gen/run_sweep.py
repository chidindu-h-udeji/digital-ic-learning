"""run_sweep.py - Automated hardware resource sweep comparing flat vs. decomposed architectures."""
import csv, json, os, subprocess
from pathlib import Path
from make_synth import make_patterns, write_pir

# Paths and configuration
OFF = Path.home() / "patterns-to-parsers"
WORK = Path.cwd() / "sweep_work"
WORK.mkdir(exist_ok=True)

N = 256  # Pattern count scaled for resource-constrained execution
FLAGS = ["--rtl", "--tree1", "--tree2"]
CFG = {
    "flat":       dict(num_cols=1, char_per_col=20, col_per_file=1),
    "decomposed": dict(num_cols=4, char_per_col=5,  col_per_file=4)
}

def yosys_stats(d, top="hex_to_rtl_top"):
    """Synthesizes the generated RTL using Yosys and extracts LUT and FF statistics."""
    files = [str(p) for p in sorted(Path(d).glob("*.sv")) if not p.name.endswith("_tb.sv")]
    js = Path(d) / "stat.json"
    
    # Execute Yosys synthesis flow targeting 6-input LUTs (FSM extraction disabled)
    subprocess.run(["yosys", "-q", "-p",
        f"read_verilog -sv {' '.join(files)}; synth -top {top} -nofsm -flatten -lut 6; tee -q -o {js} stat -json"],
        check=True)
        
    data = json.loads(js.read_text())
    
    # Yosys prefixes module names with a backslash in the JSON dump
    mod = data.get("modules", {}).get(f"\\{top}", {})
    
    # Extract the hardware cell counts (LUTs and Flip-Flops)
    cells = mod.get("num_cells_by_type", {})
    
    luts = cells.get("$lut", 0)
    ffs = sum(v for k, v in cells.items() if "dff" in k.lower())
    return luts, ffs

def main():
    # Use a new CSV file to prevent mixing stale formats with the new seeded data
    out_csv = Path("results_seeded.csv")
    
    # 1. Read already completed runs to avoid duplicate work
    completed = set()
    if out_csv.exists():
        with open(out_csv, "r") as f:
            reader = csv.reader(f)
            next(reader, None)  # Skip header
            for row in reader:
                if row:
                    completed.add((int(row[0]), int(row[1]), int(row[2]), int(row[3]), row[4]))

    # 2. Append to the file instead of overwriting
    mode_write = "a" if out_csv.exists() else "w"
    
    with open(out_csv, mode_write, newline="") as f:
        w = csv.writer(f)
        if mode_write == "w":
            w.writerow(["n", "seed", "u", "ug", "mode", "luts", "ffs"])
        
        # Loop through seeds 1 to 3 to differentiate noise from trend
        for seed in (1, 2, 3):
            # Sweep across pattern uniqueness (u) and structural decomposition groups (ug)
            for u in (32, 64, 128):
                for ug in (1, 2, 3, 4):
                    pir = WORK / f"u{u}_ug{ug}_s{seed}.pir"
                    write_pir(make_patterns(N, u, ug, seed=seed), pir)
                    
                    for mode, c in CFG.items():
                        # Skip if this data point is already in results_seeded.csv
                        if (N, seed, u, ug, mode) in completed:
                            print(f"Skipping {mode} | N={N} | seed={seed} | u={u} | ug={ug} (Already recorded)")
                            continue
                            
                        print(f"Synthesizing {mode} | N={N} | seed={seed} | u={u} | ug={ug}...", flush=True)
                        
                        cfg = WORK / f"{mode}.json"
                        cfg.write_text(json.dumps({**c, "custom": []}))
                        d = WORK / f"{mode}_u{u}_ug{ug}_s{seed}"
                        
                        # Generate architecture RTL via official toolchain
                        subprocess.run(["python3", "engine/tools/build_rtl_countluts.py", "-c", str(cfg),
                                        "-m", str(pir), "-o", str(d), *FLAGS],
                                       cwd=OFF, env={**os.environ, "PYTHONPATH": "engine"}, check=True)
                        
                        # Collect synthesis metrics
                        luts, ffs = yosys_stats(d)
                        
                        # Record data point
                        w.writerow([N, seed, u, ug, mode, luts, ffs])
                        f.flush()
                        print(f"--> RESULT: {luts} LUTs, {ffs} FFs\n", flush=True)

if __name__ == "__main__":
    main()