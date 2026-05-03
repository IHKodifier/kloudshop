from pydantic import BaseModel, Field
from typing import List, Optional, Any, Dict
from datetime import datetime

class FeatureBase(BaseModel):
    feature_id: str
    name: str
    description: Optional[str] = None
    icon: Optional[str] = None
    has_config: bool = False
    is_premium: bool = False

class FeatureResponse(FeatureBase):
    config_schema: Optional[Dict[str, Any]] = None
    is_active: bool = False
    
    class Config:
        from_attributes = True

class FeatureActivationRequest(BaseModel):
    is_active: bool

class FeatureConfigRequest(BaseModel):
    config: Dict[str, Any]

class FeatureRequestBase(BaseModel):
    title: str
    description: Optional[str] = None

class FeatureRequestCreate(FeatureRequestBase):
    pass

class FeatureRequestResponse(FeatureRequestBase):
    request_id: str
    status: str
    votes_count: int
    created_at: datetime
    has_voted: bool = False

    class Config:
        from_attributes = True

class FeatureVoteResponse(BaseModel):
    request_id: str
    votes_count: int
    has_voted: bool
