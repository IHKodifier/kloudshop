import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey
from shared.db import Base

class StaffLocationAssignment(Base):
    """
    Links a merchant staff user to a specific physical stock location.
    Required for POS operators to process sales from a specific store.
    """
    __tablename__ = "staff_location_assignments"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    staff_user_id = Column(String, nullable=False, index=True) # Firebase UID
    stock_location_id = Column(String, ForeignKey("stock_locations.stock_location_id", ondelete="CASCADE"), nullable=False)
    
    assigned_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
