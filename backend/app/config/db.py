from pymongo import MongoClient
import os
from dotenv import load_dotenv

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")

client = MongoClient(MONGO_URI)
db = client["arth_db"]

# Collections
user_col = db["users"]
transactions_col = db["transactions"]
summary_col = db["summary"]
budgets_col = db["budgets"]
goals_col = db["goals"]
health_col = db["financial_health"]