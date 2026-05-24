from sqlalchemy import Column, String, Text, Boolean, Integer, DateTime, JSON, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from shared.db import Base, engine
import uuid
from datetime import datetime, timezone

# Schema name for platform-wide tables
SCHEMA = "platform" if "sqlite" not in engine.url.drivername else None

class Feature(Base):
    __tablename__ = "features"
    if SCHEMA:
        __table_args__ = {"schema": SCHEMA}

    feature_id = Column(String, primary_key=True) # e.g. 'ai_copywriter', 'dynamic_pricing'
    name = Column(String, nullable=False)
    description = Column(Text)
    icon = Column(String) # Icon name for UI
    has_config = Column(Boolean, default=False)
    config_schema = Column(JSON) # JSON Schema for the wizard validation
    is_premium = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

class TenantFeatureActivation(Base):
    __tablename__ = "tenant_feature_activations"

    tenant_id = Column(String, primary_key=True)
    feature_id = Column(String, ForeignKey("features.feature_id"), primary_key=True)
    is_active = Column(Boolean, nullable=False, default=False)
    activated_at = Column(DateTime)
    activated_by = Column(String) # user_id

    __table_args__ = (
        CheckConstraint('is_active IN (0, 1)' if "sqlite" in engine.url.drivername else 'is_active IS NOT NULL'),
    )

class TenantFeatureConfig(Base):
    __tablename__ = "tenant_feature_configs"

    tenant_id = Column(String, primary_key=True)
    feature_id = Column(String, ForeignKey("features.feature_id"), primary_key=True)
    config_key = Column(String, primary_key=True)
    config_value = Column(Text) # Stored as string, cast based on config_schema
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

class FeatureRequest(Base):
    __tablename__ = "feature_requests"

    request_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    user_id = Column(String, nullable=False)
    title = Column(Text, nullable=False)
    description = Column(Text)
    status = Column(String(16), nullable=False, default='pending') # pending | planned | in_progress | completed
    votes_count = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        CheckConstraint(status.in_(['pending', 'planned', 'in_progress', 'completed']), name='feature_request_status_check'),
    )

class FeatureRequestVote(Base):
    __tablename__ = "feature_request_votes"

    request_id = Column(String, ForeignKey("feature_requests.request_id", ondelete="CASCADE"), primary_key=True)
    user_id = Column(String, primary_key=True)
    tenant_id = Column(String, nullable=False, index=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
