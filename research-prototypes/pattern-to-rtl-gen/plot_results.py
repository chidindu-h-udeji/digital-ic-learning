"""plot_results.py - Generates the ratio visualization and markdown table for the 3-seed sweep."""
import csv
import matplotlib.pyplot as plt
import numpy as np
from collections import defaultdict

def main():
    # data[u][ug][mode] = [lut_seed1, lut_seed2, lut_seed3]
    data = defaultdict(lambda: defaultdict(lambda: {'flat': [], 'decomposed': []}))
    
    with open('results_seeded.csv', 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            u, ug = int(row['u']), int(row['ug'])
            mode, luts = row['mode'], int(row['luts'])
            data[u][ug][mode].append(luts)

    u_values = [32, 64, 128]
    ug_values = [1, 2, 3, 4]
    
    # 1. Print the Markdown Table for the README
    print("\n### Copy this table into your README.md ###\n")
    print("| Repetition | Uniqueness (u) | Groups (ug) | Flat LUTs (Mean [Min-Max]) | Decomposed LUTs (Mean [Min-Max]) | Ratio (Flat/Decomp) |")
    print("| :--- | :--- | :--- | :--- | :--- | :--- |")
    
    # Setup for plotting
    fig, ax = plt.subplots(figsize=(9, 6))
    colors = {32: '#1f77b4', 64: '#ff7f0e', 128: '#2ca02c'}
    markers = {32: 'o', 64: 's', 128: '^'}
    
    for u in u_values:
        means_ratio, min_ratios, max_ratios = [], [], []
        
        for ug in ug_values:
            f_luts = data[u][ug]['flat']
            d_luts = data[u][ug]['decomposed']
            
            f_mean, d_mean = np.mean(f_luts), np.mean(d_luts)
            
            # Calculate ratios for min/max shading
            ratios = [f / d for f, d in zip(f_luts, d_luts)]
            means_ratio.append(f_mean / d_mean)
            min_ratios.append(np.min(ratios))
            max_ratios.append(np.max(ratios))
            
            rep = 256 // u
            # Print row for table
            print(f"| **{rep}x** | {u} | {ug} | {f_mean:.0f} [{min(f_luts)}-{max(f_luts)}] | {d_mean:.0f} [{min(d_luts)}-{max(d_luts)}] | **{f_mean/d_mean:.2f}** |")
            
        # Plot the mean line and shade the min-max area for the 3 seeds
        ax.plot(ug_values, means_ratio, marker=markers[u], color=colors[u], 
                label=f'u={u} ({256//u}x repetition)', linewidth=2.5)
        ax.fill_between(ug_values, min_ratios, max_ratios, color=colors[u], alpha=0.15)

    # Formatting the Chart
    ax.set_title('Hardware Efficiency Ratio: Flat vs. Decomposed Architecture\n(Means across 3 pattern seeds with Min-Max range)', fontsize=13, pad=15)
    ax.set_xlabel('Number of Structural Groups (ug)', fontsize=11, labelpad=10)
    ax.set_ylabel('Ratio (Flat LUTs / Decomposed LUTs)\n← Flat is Better  |  Decomposed is Better →', fontsize=11, labelpad=10)
    ax.set_xticks(ug_values)
    
    # Add a breakeven line where Flat == Decomposed
    ax.axhline(1.0, color='red', linestyle='--', alpha=0.7, label='Breakeven Point')
    ax.grid(True, linestyle=':', alpha=0.7)
    ax.legend(loc='upper left')
    
    plt.tight_layout()
    plt.savefig('lut_ratio_chart.png', dpi=300)
    print("\n--> Chart successfully saved as lut_ratio_chart.png!\n")

if __name__ == "__main__":
    main()