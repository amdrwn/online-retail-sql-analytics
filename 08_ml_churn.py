import pandas as pd
import psycopg2
from dotenv import load_dotenv
import os
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, roc_auc_score
import xgboost as xgb
import shap
import matplotlib.pyplot as plt

load_dotenv()

conn = psycopg2.connect(
    dbname=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT")
)

query_features = """
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(revenue) AS monetary,
        MAX(invoice_date) AS last_purchase,
        MIN(invoice_date) AS first_purchase,
        COUNT(DISTINCT DATE_TRUNC('month', invoice_date)) AS active_months
    FROM clean_transactions
    WHERE invoice_date < '2011-09-09'
    GROUP BY customer_id
"""

query_labels = """
    SELECT DISTINCT customer_id
    FROM clean_transactions
    WHERE invoice_date >= '2011-09-09'
"""

df_features = pd.read_sql(query_features, conn)
df_labels = pd.read_sql(query_labels, conn)
conn.close()

df_features['churned'] = (~df_features['customer_id'].isin(df_labels['customer_id'])).astype(int)
df_features['recency_days'] = (pd.to_datetime('2011-09-09') - df_features['last_purchase']).dt.days
df_features['tenure_days'] = (df_features['last_purchase'] - df_features['first_purchase']).dt.days

print(df_features['churned'].value_counts())
print(f"Churn rate: {df_features['churned'].mean():.2%}")

features = ['recency_days', 'frequency', 'monetary', 'tenure_days', 'active_months']
X = df_features[features]
y = df_features['churned']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

lr = LogisticRegression(random_state=42)
lr.fit(X_train_scaled, y_train)
lr_preds = lr.predict(X_test_scaled)
lr_auc = roc_auc_score(y_test, lr.predict_proba(X_test_scaled)[:,1])

print("Logistic Regression:")
print(classification_report(y_test, lr_preds))
print(f"AUC: {lr_auc:.4f}")

xgb_model = xgb.XGBClassifier(n_estimators=100, max_depth=4, learning_rate=0.1,
                                random_state=42, eval_metric='logloss')
xgb_model.fit(X_train, y_train)
xgb_preds = xgb_model.predict(X_test)
xgb_auc = roc_auc_score(y_test, xgb_model.predict_proba(X_test)[:,1])

print("\nXGBoost:")
print(classification_report(y_test, xgb_preds))
print(f"AUC: {xgb_auc:.4f}")

explainer = shap.TreeExplainer(xgb_model)
shap_values = explainer.shap_values(X_test)

plt.figure()
shap.summary_plot(shap_values, X_test, feature_names=features, show=False)
plt.tight_layout()
plt.savefig('shap_summary.png', dpi=150, bbox_inches='tight')
plt.close()
print("SHAP plot saved.")

xgb.plot_importance(xgb_model, importance_type='gain', max_num_features=5)
plt.tight_layout()
plt.savefig('feature_importance.png', dpi=150, bbox_inches='tight')
plt.close()
print("Feature importance plot saved.")