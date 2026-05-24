import uuid
from sqlalchemy import Column, String, DateTime, Boolean, JSON
from datetime import datetime, timezone
from shared.db import Base, engine

# Schema name for platform-wide tables
SCHEMA = "kloudshop_platform" if "sqlite" not in engine.url.drivername else None

class Tenant(Base):
    __tablename__ = "tenants"
    if SCHEMA:
        __table_args__ = {"schema": SCHEMA}

    id = Column(String, primary_key=True) # e.g. 'acme'
    name = Column(String, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    is_active = Column(Boolean, default=True)
    
    # GCP Metadata
    gcp_project_id = Column(String)
    gcp_bucket_name = Column(String)
    
    # Configuration
    config = Column(JSON, default={})
    supported_locales = Column(JSON, default=["en"])
