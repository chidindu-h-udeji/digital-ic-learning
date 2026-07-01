import csv
import sys
import os
import re

"""
OpenLane Timing Report Parser
Takes an OpenLane .rpt file, extracts the startpoint, endpoint, 
slack, and status of every timing path, and outputs a formatted 
terminal summary and a results.csv file.
Usage: python3 parse_timing.py <filepath>
"""

def parse_timing_report(filepath):
    paths = []          # List for the completed dictionaries
    current_path = {}   # Temporary bucket for current path

    with open(filepath, 'r') as f:  # Open file      
        for line in f:              # Loop line by line       
            line = line.strip()     # Strip whitespace
            
            # DETECTION AND EXTRACTION
            if 'Startpoint' in line:
                current_path['startpoint'] = line.split()[1] # Turns into a list and [1] grabs startpoint

            elif 'Endpoint' in line:
                current_path['endpoint'] = line.split()[1] # Turns into a list and [1] grabs endpoint

            elif 'slack' in line:
                try:
                    # Grabs the numerical value
                    slack = re.search(r'(?<!\S)[+-]?\d+(?:\.\d+)?', line).group() 
                    current_path['slack'] = float(slack)

                    # Grabs the word that's not slack
                    status = re.search(r'\b(?!slack\b)[A-Za-z]\w*\b', line).group() 
                    current_path['status'] = status.strip('()')
                
                except (AttributeError, ValueError):
                    print('Skipping malformed slack line')
                    continue

                
                paths.append(current_path)  # Append completed dictionary to list
                
                current_path = {}           # Empty the bucket for the next path

    return paths

def print_summary(paths):
    # Print the table header and horizontal divider
    print(f"{'Startpoint':<15} | {'Endpoint':<15} | {'Status':<15} | {'Slack':>10}")
    print('-' * 70)
    
    # Loops list and prints values
    for path in paths:
        print(f"{path['startpoint']:<15} | {path['endpoint']:<15} | {path['status']:<15} | {path['slack']:>10}")

def write_csv(paths, output_path):
    with open(output_path, 'w', newline='') as f:    # Write file
        fieldnames = ['startpoint', 'endpoint', 'slack', 'status']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        
        writer.writeheader() # Writes the top row of column names
        
        writer.writerows(paths) # Writes dictionary



# Main execution
if __name__ == '__main__':
    
    # Check for the right number of arguments
    if len(sys.argv) != 2:
        print('Error: Usage is python3 script.py <file>')
        sys.exit()

    # Check if the file exists
    filepath = sys.argv[1]
    if not os.path.exists(filepath):
        print(f'Error: Could not find {filepath}')
        sys.exit()

    paths = parse_timing_report(filepath)
    print_summary(paths)
    write_csv(paths, 'results.csv')