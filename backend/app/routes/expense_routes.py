from fastapi import APIRouter
from app.schemas.transaction_schema import Transaction
from app.services.expense_service import add_expense, get_user_history, delete_user_expense

router = APIRouter(prefix="/expense", tags=["Expense"])

@router.post("/add")
def create_expense(expense: Transaction):
    return add_expense(expense)

@router.get("/history/{user_id}")
def get_transaction_history(user_id: str):
    return get_user_history(user_id)

# 🔥 NEW: Delete Route
@router.delete("/delete/{transaction_id}")
def delete_transaction(transaction_id: str):
    return delete_user_expense(transaction_id)
