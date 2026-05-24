from sqlalchemy import Column, String, Boolean, Text, JSON, DateTime, ForeignKey, Integer
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
import uuid

from shared.db import Base

class Theme(Base):
    __tablename__ = "themes"

    theme_id = Column(String, primary_key=True) # e.g. "modern-dark", "minimalist"
    name = Column(Text, nullable=False)
    description = Column(Text)
    preview_url = Column(Text)
    base_config = Column(JSON, nullable=False) # Default tokens and slots
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

class ThemeConfiguration(Base):
    __tablename__ = "theme_configurations"

    config_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    theme_id = Column(String, ForeignKey("themes.theme_id"), nullable=False)
    
    # Draft vs Live
    draft_tokens = Column(JSON, nullable=False, default={})
    live_tokens = Column(JSON, nullable=False, default={})
    
    draft_slots = Column(JSON, nullable=False, default={})
    live_slots = Column(JSON, nullable=False, default={})
    
    is_active = Column(Boolean, nullable=False, default=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    theme = relationship("Theme")
