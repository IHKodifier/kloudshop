from sqlalchemy import Column, String, Boolean, Text, JSON, DateTime, Integer, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
import uuid

from shared.db import Base

class OnboardingSession(Base):
    __tablename__ = "onboarding_sessions"

    session_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    current_step = Column(String(32), nullable=False, default="signup")
    selected_tier = Column(String(32))
    selected_region = Column(String(64))
    import_status = Column(String(32), default="none") # none | analyzing | executing | completed | failed
    import_progress = Column(Integer, default=0)
    last_error = Column(Text)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

class ImportMapping(Base):
    __tablename__ = "import_mappings"

    mapping_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    entity_type = Column(String(32), nullable=False) # product | customer | order
    header_mapping = Column(JSON, nullable=False) # {csv_column: model_field}
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
