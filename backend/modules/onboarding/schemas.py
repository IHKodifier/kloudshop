from pydantic import BaseModel, EmailStr
from typing import Optional, List, Dict, Any
from datetime import datetime

class SignupRequest(BaseModel):
    brand_name: str
    owner_email: EmailStr
    tier: str # basic | professional | enterprise

class RegionSelectionRequest(BaseModel):
    region: str # us-central1 | europe-west1 | asia-southeast1

class ImportAnalysisRequest(BaseModel):
    entity_type: str
    csv_sample: List[str] # List of header names

class ImportAnalysisResponse(BaseModel):
    suggested_mapping: Dict[str, str]
    confidence_score: float

class ImportExecutionRequest(BaseModel):
    entity_type: str
    mapping: Dict[str, str]
    csv_content_url: str

class OnboardingStatusResponse(BaseModel):
    session_id: str
    current_step: str
    import_status: str
    import_progress: int
    updated_at: datetime

class MigrationRunbookResponse(BaseModel):
    merchant_name: str
    steps: List[Dict[str, Any]]
    generated_at: datetime
