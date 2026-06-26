from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class PolicyBase(BaseModel):
    policy_type: str  # refund / privacy / terms / shipping
    draft_content: Optional[str] = None
    published_content: Optional[str] = None
    is_active: bool = False

class PolicyCreate(PolicyBase):
    pass

class PolicyUpdate(BaseModel):
    draft_content: str

class PolicyResponse(PolicyBase):
    policy_id: str
    tenant_id: str
    version: int
    created_at: datetime
    updated_at: datetime
    deactivated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class PolicyTemplateSeedRequest(BaseModel):
    policy_type: str

class PolicyTemplateSeedResponse(BaseModel):
    policy_type: str
    seeded_content: str
