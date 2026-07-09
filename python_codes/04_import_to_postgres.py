import pandas as pd
from sqlalchemy import create_engine

engine = create_engine('postgresql://postgres:Chris2010%40ngo@localhost:5432/nigeria_labour_education_analysis')

print("Loading combined CSV file")
df = pd.read_csv(
    r"C:\Users\HP PC\Desktop\nigeria-labour-education-analysis\nlfs_combined.csv",
    low_memory=False
)

print(f"File loaded successfully: {df.shape[0]} rows, {df.shape[1]} columns")

print("\nUploading to PostgreSQL... this may take a few minutes due to file size...")
df.to_sql(
    name='staging_nlfs',        
    con=engine,
    if_exists='replace',        
    index=False,                
    chunksize=1000              
)

print("\nDone! staging_nlfs table created successfully in nigeria_labour_education_analysis database")
print(f"Total rows uploaded: {df.shape[0]}")