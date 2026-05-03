from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from .models import SubscriptionStatus, SubscriptionTier

class SubscriptionBase(BaseModel):
    tier: SubscriptionTier
    status: SubscriptionStatus

class SubscriptionResponse(SubscriptionBase):
    id: str
    tenant_id: str
    current_period_end: Optional[datetime] = None
    trial_end: Optional[datetime] = None
    cancel_at_period_end: bool
    created_at: datetime

    class Config:
        from_attributes = True

class UpgradeRequest(BaseModel):
    plan_id: str # dtc, b2b, hybrid
    success_url: str
    cancel_url: str

class InvoiceResponse(BaseModel):
    id: str
    amount_paid: int
    currency: str
    status: str
    hosted_invoice_url: Optional[str] = None
    invoice_pdf: Optional[str] = None
    created: datetime

class PortalSessionResponse(BaseModel):
    url: str
