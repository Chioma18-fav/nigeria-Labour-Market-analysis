import pandas as pd

files = [
    r"C:\Users\HP PC\Desktop\nigeria-labour-education-analysis\nlfs_2024q3_indiv.csv",
    r"C:\Users\HP PC\Desktop\nigeria-labour-education-analysis\nlfs_2024q4_indiv.csv",
    r"C:\Users\HP PC\Desktop\nigeria-labour-education-analysis\nlfs_2025q1_indiv.csv",
    r"C:\Users\HP PC\Desktop\nigeria-labour-education-analysis\nlfs_2025q2_indiv.csv"
]

dataframes = {}
for file in files:
    quarter = file.split("nlfs_")[1].split("_ind")[0]
    df = pd.read_csv(file)
    dataframes[quarter] = set(df.columns)
    print(f"{quarter}: {df.shape[0]} rows, {df.shape[1]} columns")

# Check if all have same columns
all_columns = list(dataframes.values())
if all_columns[0] == all_columns[1] == all_columns[2] == all_columns[3]:
    print("\nAll four files have identical columns")
else:
    print("\nDifferences found:")
    base = dataframes['2025q1']
    for quarter, cols in dataframes.items():
        extra = cols - base
        missing = base - cols
        if extra:
            print(f"{quarter} has EXTRA columns: {extra}")
        if missing:
            print(f"{quarter} is MISSING columns: {missing}")


files = {
    "2024q3": r"C:\Users\HP PC\Desktop\nigeria-labour-education-analysis\nlfs_2024q3_indiv.csv",
    "2024q4": r"C:\Users\HP PC\Desktop\nigeria-labour-education-analysis\nlfs_2024q4_indiv.csv",
    "2025q1": r"C:\Users\HP PC\Desktop\nigeria-labour-education-analysis\nlfs_2025q1_indiv.csv",
    "2025q2": r"C:\Users\HP PC\Desktop\nigeria-labour-education-analysis\nlfs_2025q2_indiv.csv"
}

key_columns = ['id1_zone', 'id2_state', 'id5_sector', 'dc3', 'dc5', 'ed7', 'atw1', 'mjj4', 'popw']

for quarter, path in files.items():
    print(f"\n{'='*40}")
    print(f"QUARTER: {quarter}")
    print(f"{'='*40}")
    df = pd.read_csv(path, low_memory=False, usecols=key_columns)
    for col in key_columns:
        print(f"\n{col}:")
        print(df[col].value_counts().head(5))
