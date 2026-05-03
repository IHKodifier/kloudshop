from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class PricingRuleBase(BaseModel):
    name: str
    rule_type: str # percentage | fixed | tiered
    target_resource: str # products | categories | customers | all
    target_ids: List[str] = []
    modifier_value: float
    priority: int = 0
    is_active: bool = True
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None

class PricingRuleCreate(PricingRuleBase):
    pass

class PricingRuleResponse(PricingRuleBase):
    rule_id: str
    tenant_id: str
    created_at: datetime
    
    class Config:
        from_attributes = True
