import uuid
import enum
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Boolean
from shared.db import Base, engine

# Schema name for platform-wide tables
SCHEMA = "kloudshop_platform" if "sqlite" not in engine.url.drivername else None

class SubscriptionStatus(str, enum.Enum):
    TRIALING = "trialing"
    ACTIVE = "active"
    PAST_DUE = "past_due"
    CANCELED = "canceled"
    UNPAID = "unpaid"

class SubscriptionTier(str, enum.Enum):
    FREE = "free"
    DTC = "dtc"
    B2B = "b2b"
    HYBRID = "hybrid"

class Subscription(Base):
    __tablename__ = "subscriptions"
    if SCHEMA:
        __table_args__ = {"schema": SCHEMA}

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, unique=True, index=True)
    stripe_customer_id = Column(String, nullable=True, index=True)
    stripe_subscription_id = Column(String, nullable=True, index=True)
    tier = Column(String, default=SubscriptionTier.FREE)
    status = Column(String, default=SubscriptionStatus.TRIALING)
    
    current_period_start = Column(DateTime, nullable=True)
    current_period_end = Column(DateTime, nullable=True)
    
    trial_start = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    trial_end = Column(DateTime, nullable=True)
    
    cancel_at_period_end = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
