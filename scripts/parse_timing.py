import sys
import json
import os

def load_metrics(run_dir):
    # Handle direct file paths or directory fallbacks
    if run_dir.endswith('.json'):
        metrics_path = run_dir
    else:
        metrics_path = os.path.join(run_dir, "metrics.json")
        if not os.path.exists(metrics_path):
            metrics_path = os.path.join(run_dir, "final", "metrics.json")
    
    if not os.path.exists(metrics_path):
        print(f"Error: Could not find metrics.json in {run_dir}")
        sys.exit(1)

    with open(metrics_path, 'r') as f:
        return json.load(f)

def get_run_name(path):
    # Extract directory name, stepping back if path ends in 'final' or 'metrics.json'
    path = path.rstrip('/')
    if path.endswith('.json'):
        path = os.path.dirname(path)
    if path.endswith('final'):
        path = os.path.dirname(path)
    return os.path.basename(path)

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 parse_timing.py <run_dir_1> <run_dir_2>")
        sys.exit(1)

    # Load both runs
    metrics1 = load_metrics(sys.argv[1])
    metrics2 = load_metrics(sys.argv[2])

    # Extract dynamic column headers
    run1_name = get_run_name(sys.argv[1])
    run2_name = get_run_name(sys.argv[2])

    # Define the fields we want to extract
    keys_to_compare = [
        ("Setup WNS (ns)", "timing__setup__ws"),
        ("Max Slew Violations", "design__max_slew_violation__count"),
        ("Max Cap Violations", "design__max_cap_violation__count"),
        ("Max Fanout Violations", "design__max_fanout_violation__count"),
        ("Die Area (um^2)", "design__die__area"),
        ("Utilization", "design__instance__utilization")
    ]

    # Print Header
    print(f"\n{'Metric':<25} | {run1_name:<15} | {run2_name:<15}")
    print("-" * 62)

    # Print Table Rows
    for label, key in keys_to_compare:
        val1 = metrics1.get(key, "N/A")
        val2 = metrics2.get(key, "N/A")

        # Round floats for readability
        if isinstance(val1, float): val1 = round(val1, 4)
        if isinstance(val2, float): val2 = round(val2, 4)

        print(f"{label:<25} | {str(val1):<15} | {str(val2):<15}")

    print("-" * 62)

    # Automated Sanity Checks
    print("\n--- Sanity Checks ---")
    if metrics1.get("design__die__area") == metrics2.get("design__die__area"):
        print("[PASS] Die Area remained constant across constraints.")
    else:
        print("[WARN] Die Area changed unexpectedly!")

    util1 = round(float(metrics1.get("design__instance__utilization", 0)), 4)
    util2 = round(float(metrics2.get("design__instance__utilization", 0)), 4)
    
    # Introduce a 0.001 tolerance (0.1%) to pass minor placement density variations
    if abs(util1 - util2) <= 0.001:
        print("[PASS] Logic Utilization remained stable.")
    else:
        print(f"[WARN] Utilization changed unexpectedly! ({util1} vs {util2})")
    print()

if __name__ == '__main__':
    main()