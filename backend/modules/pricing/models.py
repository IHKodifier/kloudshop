from sqlalchemy import Column, String, Text, Boolean, Integer, Float, DateTime, JSON, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from shared.db import Base, engine
import uuid
from datetime import datetime, timezone

class PricingRule(Base):
    __tablename__ = "pricing_rules"

    rule_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    
    name = Column(String(128), nullable=False)
    rule_type = Column(String(32), nullable=False) # percentage | fixed | tiered
    
    # Selection criteria
    target_resource = Column(String(32), nullable=False) # products | categories | customers | all
    target_ids = Column(JSON, nullable=False, default=[]) # List of IDs or None for 'all'
    
    # Rule logic
    modifier_value = Column(Float, nullable=False) # e.g. -10 for 10% discount, 5 for $5 surcharge
    priority = Column(Integer, default=0)
    
    is_active = Column(Boolean, default=True)
    start_date = Column(DateTime)
    end_date = Column(DateTime)
    
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    created_by = Column(String)

    __table_args__ = (
        CheckConstraint(rule_type.in_(['percentage', 'fixed', 'tiered']), name='pricing_rule_type_check'),
    )
