from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class ExportRequest(BaseModel):
    format: str = "csv" # csv | json
    resource_type: str = "all" # products | orders | customers | all

class ExportJobResponse(BaseModel):
    job_id: str
    status: str
    format: str
    resource_type: str
    download_url: Optional[str] = None
    created_at: datetime
    completed_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True
