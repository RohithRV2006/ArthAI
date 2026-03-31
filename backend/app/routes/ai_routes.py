from fastapi import APIRouter
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

from app.config.db import db
from app.schemas.input_schema import UserInput
from app.services.ai_service import classify_and_parse
from app.services.summary_service import update_summary
from app.services.budget_service import check_budget
from app.services.insight_service import generate_insight, generate_data_insights
from app.utils.category_mapper import normalize_category
from app.services.rule_engine import detect_intent_rule
from app.services.memory_service import save_memory, get_recent_memory
from app.services.behavior_service import analyze_behavior
from app.services.context_service import build_context
from app.services.alert_service import generate_alerts
from app.services.preprocessor_service import preprocess_input
from app.services.budget_service import (
    get_budget_health_score,
    get_budget_status,
    predict_budget_risk,
)
from app.services.goal_service import get_goals, get_goal_alerts
from app.services.recommendation_service import (
    generate_recommendations,
    explain_recommendations,
)
from app.services.user_service import get_user_profile
from app.services.financial_health_service import calculate_financial_health
from app.services.health_history_service import save_health_snapshot
from app.services.expense_service import get_user_history

router = APIRouter(prefix="/ai", tags=["AI"])

# ── Language instruction helper ──────────────────────────────────────────────
def _lang_instruction(language: str) -> str:
    """Returns a system instruction for the AI based on language."""
    if language.lower() == "tamil":
        return "You must respond entirely in Tamil language (தமிழ்). Do not use English."
    return "Respond in English."


# ── /ai/process ──────────────────────────────────────────────────────────────
@router.post("/process")
def process_input(input_data: UserInput):
    text = preprocess_input(input_data.text)
    user_id = input_data.user_id
    
    # 🔥 THE FIX: Get the user's language securely
    user_lang = getattr(input_data, "language", "english").lower()

    rule_intent = detect_intent_rule(text)

    if rule_intent == "greeting":
        return {
            "type": "chat",
            "response": "வணக்கம்! உங்கள் செலவுகளை என்னிடம் கூறலாம்." if user_lang == "tamil" else "Hi! You can tell me your expenses or ask about your finances.",
        }

    if text.lower() in ["help", "what can you do"]:
        return {
            "type": "chat",
            "response": "நீங்கள் 'நான் உணவுக்காக 200 ரூபாய் செலவழித்தேன்' என்று கூறலாம்." if user_lang == "tamil" else "You can say things like 'I spent 200 on food' or ask about your finances.",
        }

    memory_context = get_recent_memory(user_id)
    system_context = build_context(user_id)
    results = classify_and_parse(text, user_lang)

    saved_transactions = []
    save_memory(user_id, text, "raw")

    for item in results:
        intent = item.get("intent")
        data = item.get("data", {})

        # 🔥 Improve intent reliability
        if intent not in ["expense", "income"] and rule_intent:
            intent = rule_intent

        if intent in ["query", "habit", "goal"]:
            continue

        if intent in ["expense", "income"]:
            try:
                amount = float(data.get("amount", 0))
            except:
                amount = 0.0

            if amount <= 0:
                continue

            raw_category = data.get("category", "others") or "others"
            category = str(normalize_category(raw_category)).lower()
            allowed_categories = ["food", "travel", "shopping", "bills", "health", "education", "others"]
            if category not in allowed_categories:
                category = "others"

            subcategory = str(data.get("subcategory", "")).lower()
            notes = str(data.get("notes", data.get("description", "Added via AI"))).strip()
            payment_method = str(data.get("payment_method", "")).lower()

            doc = {
                "user_id": user_id,
                "type": intent,
                "amount": amount,
                "category": category,
                "subcategory": subcategory,
                "payment_method": payment_method,
                "description": notes,
                "source": "ai",
                "date": datetime.today().strftime("%Y-%m-%d") 
            }

            inserted = db.transactions.insert_one(doc)
            txn_id = str(inserted.inserted_id)
            update_summary(user_id, intent, amount, category)
            alert = check_budget(user_id, category, amount)

            saved_transactions.append({
                "transaction_id": txn_id,
                "intent": intent,
                "amount": amount,
                "category": category,
                "alert": alert,
            })

    if saved_transactions:
        return {
            "type": "multi_data_saved",
            "message": f"{len(saved_transactions)} transaction(s) recorded successfully",
            "transactions": saved_transactions
        }

    try:
        health = get_budget_health_score(user_id)
        budget_status = get_budget_status(user_id)
        budget_risk = predict_budget_risk(user_id)
    except:
        health, budget_status, budget_risk = {}, [], []

    try:
        goals = get_goals(user_id)
        goal_alerts = get_goal_alerts(user_id)
    except:
        goals, goal_alerts = [], []

    try:
        profile = get_user_profile(user_id)
    except:
        profile = {}

    try:
        financial_health = calculate_financial_health(user_id)
    except:
        financial_health = {}

    try:
        save_health_snapshot(user_id)
    except:
        pass

    try:
        raw_recommendations = generate_recommendations(user_id)
    except:
        raw_recommendations = []

    try:
        ai_recommendation = explain_recommendations(user_id, raw_recommendations)
    except:
        ai_recommendation = ""

    try:
        behavior = analyze_behavior(user_id)
    except:
        behavior = {"patterns": []}

    try:
        alerts = generate_alerts(user_id)
    except:
        alerts = []

    profile_summary = {
        "income": profile.get("monthly_income", 0) if profile else 0,
        "savings": profile.get("monthly_savings", 0) if profile else 0,
        "emi": sum(l.get("monthly_payment", 0) for l in profile.get("liabilities", [])) if profile else 0,
        "net_worth": (
            sum(a.get("value", 0) for a in profile.get("assets", []))
            - sum(l.get("outstanding_amount", 0) for l in profile.get("liabilities", []))
        ) if profile else 0,
    }

    try:
        full_history = get_user_history(user_id)
        current_month_str = datetime.now().strftime("%Y-%m")
        current_month_name = datetime.now().strftime("%B %Y")
        
        this_month_txns = [t for t in full_history if str(t.get('date', '')).startswith(current_month_str)]
        
        real_time_spent = sum([t['amount'] for t in this_month_txns if t['intent'] == 'expense'])
        real_time_income = sum([t['amount'] for t in this_month_txns if t['intent'] == 'income'])
        
        total_combined_income = profile_summary['income'] + real_time_income

        category_totals = {}
        for t in this_month_txns:
            if t['intent'] == 'expense':
                c = t['category'].title()
                category_totals[c] = category_totals.get(c, 0) + t['amount']
                
        category_breakdown = "\n".join([f"- {c}: ₹{amt}" for c, amt in category_totals.items()])
        if not category_breakdown:
            category_breakdown = "- No recorded expenses this month."
        recent_txns = full_history[:10]
        if recent_txns:
            recent_text = "\n".join([
                f"- {t['date']}: {t['intent'].upper()} ₹{t['amount']} ({t['category']} - {t.get('description', '')})"
                for t in recent_txns
            ])
        else:
            recent_text = "No recent transactions."
    except Exception as e:
        print(f"Error building AI memory: {e}")
        real_time_spent = 0
        total_combined_income = profile_summary["income"]
        category_breakdown = "- Error loading categories."
        recent_text = "No recent transactions."
        current_month_name = "this month"

    structured_context = f"""
    Total Income: ₹{total_combined_income}
    Total Spent ({current_month_name}): ₹{real_time_spent}
    Savings: ₹{profile_summary['savings']}
    EMI: ₹{profile_summary['emi']}
    Net Worth: ₹{profile_summary['net_worth']}

    Category Breakdown:
    {category_breakdown}

    Financial Health: {financial_health.get("status", "Unknown")}

    Recent Transactions:
    {recent_text}
    """

    # 🔥 THE FIX: Pass the language into the insight generator!
    insight = generate_insight(text, memory_context + [structured_context], language=user_lang)

    return {
        "type": "insight",
        "response": insight["insight"], # Extracting the actual string from the dict
        "budget_health": health,
        "financial_health": financial_health,
        "goals": goals,
        "recommendations": raw_recommendations,
        "ai_recommendation": ai_recommendation,
        "user_profile": profile_summary,
        "alerts": alerts,
    }

# ── /ai/insights/{user_id} ──────────────────────────────────────────────────
@router.get("/insights/{user_id}")
def get_insights(user_id: str, language: str = "english"):
    return generate_data_insights(user_id, language=language)
