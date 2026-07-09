import pandas as pd
import os

# Single data folder
data_folder = r"C:\Users\HP PC\Desktop\nigeria-labour-education-analysis"

# List of files to convert
files = [
    "nlfs_2024q3_indiv.dta",
    "nlfs_2024q4_indiv.dta",
    "nlfs_2025q1_indiv.dta",
    "nlfs_2025q2_indiv.dta"
]

for file in files:
    input_path = os.path.join(data_folder, file)
    output_filename = file.replace(".dta", ".csv")
    output_path = os.path.join(data_folder, output_filename)
    
    print(f"Converting {file}...")
    df = pd.read_stata(input_path)
    df.to_csv(output_path, index=False)
    print(f"Done — {output_filename} saved. Rows: {df.shape[0]}, Columns: {df.shape[1]}")

print("\nAll files converted successfully!")