from sqlalchemy import Column, String, Text, Integer, Boolean, DateTime
from datetime import datetime, timezone
from shared.db import Base
import uuid

class StorePolicy(Base):
    __tablename__ = "store_policies"

    policy_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    policy_type = Column(String(32), nullable=False) # refund / privacy / terms / shipping
    draft_content = Column(Text, nullable=True)
    published_content = Column(Text, nullable=True)
    version = Column(Integer, nullable=False, default=1)
    is_active = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    deactivated_at = Column(DateTime, nullable=True)
