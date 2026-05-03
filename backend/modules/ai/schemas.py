from pydantic import BaseModel, Field
from typing import List, Optional, Any, Dict
from datetime import datetime

class BrandVoiceProfileBase(BaseModel):
    tone: Optional[str] = None
    target_audience: Optional[str] = None
    brand_adjectives: List[str] = []
    writing_style_rules: Optional[str] = None
    negative_brands: List[str] = []

class BrandVoiceProfileResponse(BrandVoiceProfileBase):
    tenant_id: str
    brand_profile_id: str
    configured_at: datetime
    
    class Config:
        from_attributes = True

class CopyGenerationRequest(BaseModel):
    brand_profile_id: str
    source_content: Optional[str] = None # Existing title/description
    context_data: Dict[str, Any] = {} # Category, attributes, etc.

class CopyVariant(BaseModel):
    variant_id: int # 1, 2, or 3
    label: str # Benefit-led, Problem-solution, Authority
    content: str

class CopyGenerationResponse(BaseModel):
    log_id: str
    variants: List[CopyVariant]

class CopyAcceptanceRequest(BaseModel):
    variant_accepted: int
    was_edited: bool = False
    final_content: Optional[str] = None # For logging purposes
