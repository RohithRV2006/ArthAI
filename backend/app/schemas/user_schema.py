from pydantic import BaseModel, Field, root_validator
from typing import Optional, List
from datetime import datetime
import uuid


# ==============================
# FAMILY MEMBER
# ==============================
class FamilyMember(BaseModel):
    member_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    relation: str  # self / spouse / parent / child
    age: Optional[int] = None
    profession: Optional[str] = ""
    dependent: Optional[bool] = False


# ==============================
# INCOME SOURCE
# ==============================
class IncomeSource(BaseModel):
    source: str
    amount: float
    frequency: str  # monthly / yearly / weekly / daily / one-time / variable

    owner_ids: List[str]  # supports multiple owners

    is_active: Optional[bool] = True
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None

    notes: Optional[str] = ""


# ==============================
# SAVINGS
# ==============================
class Saving(BaseModel):
    type: str  # bank / cash / emergency_fund / fixed_deposit
    amount: float

    institution: Optional[str] = ""
    liquidity: Optional[str] = "high"

    owner_ids: List[str]  # required ownership


# ==============================
# ASSET
# ==============================
class Asset(BaseModel):
    name: str
    type: str

    value: float

    purchase_value: Optional[float] = None
    purchase_date: Optional[datetime] = None

    owner_ids: List[str]

    income_generated: Optional[float] = 0
    liquidity: Optional[str] = "low"

    notes: Optional[str] = ""


# ==============================
# LIABILITY
# ==============================
class Liability(BaseModel):
    name: str
    type: str

    total_amount: float
    outstanding_amount: float

    interest_rate: Optional[float] = 0
    monthly_payment: Optional[float] = 0

    tenure_months: Optional[int] = None
    lender: Optional[str] = ""

    owner_ids: List[str]

    start_date: Optional[datetime] = None

    notes: Optional[str] = ""


# ==============================
# LOCATION
# ==============================
class Location(BaseModel):
    country: Optional[str] = "India"
    city: Optional[str] = ""


# ==============================
# USER PROFILE
# ==============================
class UserProfile(BaseModel):
    user_id: str

    # Auth
    email: str
    name: str
    phone: Optional[str] = ""
    auth_provider: Optional[str] = "email"

    # Profile
    profession: Optional[str] = ""

    # Location
    location: Optional[Location] = Location()

    # Family
    family_type: str = "individual"
    members: List[FamilyMember]

    # Financials
    income_sources: Optional[List[IncomeSource]] = []
    savings: Optional[List[Saving]] = []
    assets: Optional[List[Asset]] = []
    liabilities: Optional[List[Liability]] = []

    # Preferences
    language: Optional[str] = "english"
    currency: Optional[str] = "INR"

    # Metadata
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    onboarding_completed: Optional[bool] = True

    # ==============================
    # VALIDATION
    # ==============================
    @root_validator(skip_on_failure=True)
    def validate_ownership(cls, values):
        members = values.get("members", [])
        member_ids = {m.member_id for m in members}

        def check_owners(items, field_name):
            for item in items or []:
                for oid in item.owner_ids:
                    if oid not in member_ids:
                        raise ValueError(f"{field_name}: owner_id {oid} not in members")

        check_owners(values.get("income_sources"), "income_sources")
        check_owners(values.get("savings"), "savings")
        check_owners(values.get("assets"), "assets")
        check_owners(values.get("liabilities"), "liabilities")

        # ensure at least one 'self'
        if not any(m.relation == "self" for m in members):
            raise ValueError("At least one member must have relation='self'")

        return values