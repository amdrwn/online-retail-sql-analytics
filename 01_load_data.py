import pandas as pd
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_HOST = os.getenv('DB_HOST')
DB_PORT = os.getenv('DB_PORT')
DB_NAME = os.getenv('DB_NAME')
FILE_PATH = os.getenv('FILE_PATH')

df1 = pd.read_excel(FILE_PATH, sheet_name="Year 2009-2010", engine="openpyxl")
df2 = pd.read_excel(FILE_PATH, sheet_name="Year 2010-2011", engine="openpyxl")

df = pd.concat([df1, df2], ignore_index=True)

df.columns = [
    "invoice_no", "stock_code", "description",
    "quantity", "invoice_date", "unit_price",
    "customer_id", "country"
]

for col in ["invoice_no", "stock_code", "description", "country"]:
    df[col] = df[col].astype(str).str.strip()

df["customer_id"] = df["customer_id"].astype(str).str.strip().str.replace(r'\.0$', '', regex=True)
df["customer_id"] = df["customer_id"].replace("nan", None)
df["quantity"] = pd.to_numeric(df["quantity"], errors="coerce")
df["unit_price"] = pd.to_numeric(df["unit_price"], errors="coerce")
df["invoice_date"] = pd.to_datetime(df["invoice_date"], errors="coerce")

conn = psycopg2.connect(
    dbname=DB_NAME, user=DB_USER,
    password=DB_PASSWORD, host=DB_HOST, port=DB_PORT
)
cursor = conn.cursor()

cursor.execute("TRUNCATE TABLE transactions;")
conn.commit()

records = list(df.itertuples(index=False, name=None))

for i in range(0, len(records), 5000):
    cursor.executemany("""
        INSERT INTO transactions (
            invoice_no, stock_code, description,
            quantity, invoice_date, unit_price,
            customer_id, country
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """, records[i:i+5000])
    conn.commit()
    print(f"Inserted rows {i} to {i+5000}")

cursor.close()
conn.close()
