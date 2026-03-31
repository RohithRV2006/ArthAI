from fastapi import FastAPI
from app.routes import expense_routes, ai_routes
from app.routes import budget_routes
from app.routes import goal_routes
from app.routes import recommendation_routes
from app.routes import user_routes
from app.routes import financial_routes
from app.routes import behavior_routes
from app.routes import alert_routes
from app.routes import translation_routes

app = FastAPI()

app.include_router(expense_routes.router)
app.include_router(ai_routes.router)
app.include_router(budget_routes.router)
app.include_router(goal_routes.router)
app.include_router(recommendation_routes.router)
app.include_router(user_routes.router)
app.include_router(financial_routes.router)
app.include_router(behavior_routes.router)
app.include_router(alert_routes.router)
app.include_router(translation_routes.router)


@app.get("/")
def root():
    return {"message": "Arth Backend Running"}
