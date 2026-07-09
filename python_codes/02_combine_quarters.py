import pandas as pd

files = {
    "2024q3": r"C:\Users\HP PC\Desktop\nigeria-labour-education-analysis\nlfs_2024q3_indiv.csv",
    "2024q4": r"C:\Users\HP PC\Desktop\nigeria-labour-education-analysis\nlfs_2024q4_indiv.csv",
    "2025q1": r"C:\Users\HP PC\Desktop\nigeria-labour-education-analysis\nlfs_2025q1_indiv.csv",
    "2025q2": r"C:\Users\HP PC\Desktop\nigeria-labour-education-analysis\nlfs_2025q2_indiv.csv"
}

combined = []

for quarter, path in files.items():
    df = pd.read_csv(path, low_memory=False)
    df['quarter'] = quarter
    combined.append(df)
    print(f"Loaded {quarter}: {df.shape[0]} rows")

final = pd.concat(combined, ignore_index=True)
print(f"\nCombined dataset: {final.shape[0]} rows, {final.shape[1]} columns")

final.to_csv(r"C:\Users\HP PC\Desktop\nigeria-labour-education-analysis\nlfs_combined.csv", index=False)
print("Combined file saved successfully!")