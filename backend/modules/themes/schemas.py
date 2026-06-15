from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime

class ThemeBase(BaseModel):
    theme_id: str
    name: str
    description: Optional[str]
    preview_url: Optional[str]

class ThemeResponse(ThemeBase):
    base_config: Dict[str, Any]
    created_at: datetime

class ThemeConfigRequest(BaseModel):
    name: Optional[str] = None
    tokens: Optional[Dict[str, Any]] = None
    slots: Optional[Dict[str, Any]] = None

class ThemeConfigResponse(BaseModel):
    config_id: str
    tenant_id: str
    theme_id: str
    name: str
    draft_tokens: Dict[str, Any]
    live_tokens: Dict[str, Any]
    draft_slots: Dict[str, Any]
    live_slots: Dict[str, Any]
    is_active: bool
    updated_at: datetime

class ThemeCloneRequest(BaseModel):
    name: str

class ThemeSelectionRequest(BaseModel):
    theme_id: str
