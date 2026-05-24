from sqlalchemy import Column, String, Text, Boolean, Integer, DateTime, JSON, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from shared.db import Base, engine
import uuid
from datetime import datetime, timezone

class ExportJob(Base):
    __tablename__ = "export_jobs"

    job_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    user_id = Column(String, nullable=False)
    
    status = Column(String(16), nullable=False, default='pending') # pending | processing | completed | failed
    format = Column(String(8), nullable=False) # csv | json
    resource_type = Column(String(16), nullable=False) # products | orders | customers | all
    
    download_url = Column(Text)
    expires_at = Column(DateTime)
    
    error_message = Column(Text)
    
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    completed_at = Column(DateTime)

    __table_args__ = (
        CheckConstraint(status.in_(['pending', 'processing', 'completed', 'failed']), name='export_job_status_check'),
        CheckConstraint(format.in_(['csv', 'json']), name='export_job_format_check'),
    )
