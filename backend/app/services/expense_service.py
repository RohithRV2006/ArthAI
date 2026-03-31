from app.config.db import db, transactions_col
from bson import ObjectId
from datetime import datetime
from app.services.summary_service import update_summary
from app.services.budget_service import check_budget


# ==============================
# ➕ ADD EXPENSE (UNIFIED)
# ==============================
def add_expense(expense):
    try:
        # Extract data safely
        exp_dict = expense.dict() if hasattr(expense, "dict") else expense

        user_id = exp_dict.get("user_id", "") or exp_dict.get("userId", "")
        amount = float(exp_dict.get("amount", 0))
        category = str(exp_dict.get("category", "others")).lower()
        description = str(exp_dict.get("description", ""))

        # Determine type
        txn_type = "income" if category == "income" else "expense"

        # 🔥 Unified structure (same as AI)
        doc = {
            "user_id": user_id,
            "type": txn_type,                 # ✅ standardized
            "amount": amount,
            "category": category,
            "subcategory": "",
            "payment_method": "",
            "description": description,
            "source": "manual",
            "date": datetime.utcnow()  # (we'll fix later step)
        }

        transactions_col.insert_one(doc)

        # Update summary + budget
        try:
            update_summary(user_id, txn_type, amount, category)
            check_budget(user_id, category, amount)
        except Exception as summary_err:
            print(f"Summary update failed: {summary_err}")

        return {"message": "Expense added successfully"}

    except Exception as e:
        print(f"Error saving manual expense: {e}")
        return {"status": "error"}


# ==============================
# 📜 GET USER HISTORY (FIXED)
# ==============================
def get_user_history(user_id: str):
    try:
        # 🔥 FIX: use transactions collection
        history = list(
            transactions_col.find({"user_id": user_id})
            .sort("date", -1)
        )

        formatted_history = []

        for item in history:
            try:
                category = str(item.get("category", "others")).lower()

                # ✅ Support both old & new data
                txn_type = item.get("type") or item.get("intent") or "expense"

                try:
                    amount = float(item.get("amount", 0))
                except:
                    amount = 0.0

                # Handle date safely
                raw_date = item.get("date", "")
                if isinstance(raw_date, datetime):
                    date_str = raw_date.strftime("%Y-%m-%d")
                else:
                    date_str = str(raw_date)

                formatted_history.append({
                    "id": str(item["_id"]),
                    "amount": amount,
                    "category": category,
                    "description": str(item.get("description", "")),
                    "date": date_str,
                    "intent": txn_type   # keep for frontend compatibility
                })

            except Exception as loop_err:
                continue

        return formatted_history

    except Exception as e:
        print(f"Critical error fetching history: {e}")
        return []


# ==============================
# ❌ DELETE TRANSACTION (FIXED)
# ==============================
def delete_user_expense(transaction_id: str):
    try:
        # 🔥 FIX: delete from transactions collection
        transactions_col.delete_one({"_id": ObjectId(transaction_id)})
        return {"status": "success"}

    except Exception as e:
        print(f"Error deleting expense: {e}")
        return {"status": "error"}