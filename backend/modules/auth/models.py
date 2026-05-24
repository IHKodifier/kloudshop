from sqlalchemy import Column, String, DateTime, JSON, Boolean, ForeignKey
from shared.db import Base, engine
import uuid
from datetime import datetime, timezone

# Schema name for platform-wide tables
# Disable schema for SQLite tests
SCHEMA = "kloudshop_platform" if "sqlite" not in engine.url.drivername else None

class Invitation(Base):
    __tablename__ = "invitations"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, nullable=False, index=True)
    tenant_id = Column(String, nullable=False, index=True)
    roles = Column(JSON, nullable=False, default=[])
    invited_by = Column(String, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    accepted_at = Column(DateTime, nullable=True)
    is_cancelled = Column(Boolean, default=False)

class StaffUser(Base):
    __tablename__ = "staff_users"

    uid = Column(String, primary_key=True) # Firebase UID
    email = Column(String, nullable=False, unique=True, index=True)
    display_name = Column(String, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

class StaffRoleAssignment(Base):
    __tablename__ = "staff_role_assignments"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    staff_user_id = Column(String, nullable=False) # Simplified for SQLite schema issues
    tenant_id = Column(String, nullable=False, index=True)
    roles = Column(JSON, nullable=False, default=[])
    is_owner = Column(Boolean, default=False)
    invited_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    accepted_at = Column(DateTime, nullable=True)

class B2BInvitation(Base):
    __tablename__ = "b2b_invitations"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, nullable=False, index=True)
    tenant_id = Column(String, nullable=False, index=True)
    buyer_account_id = Column(String, nullable=True) # Corporate account grouping
    token = Column(String, unique=True, index=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    expires_at = Column(DateTime, nullable=False)
    accepted_at = Column(DateTime, nullable=True)

class BuyerUser(Base):
    __tablename__ = "buyer_users"

    uid = Column(String, primary_key=True) # Firebase UID
    email = Column(String, nullable=False, unique=True, index=True)
    tenant_id = Column(String, nullable=False, index=True)
    buyer_account_id = Column(String, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

class ConsumerUser(Base):
    __tablename__ = "consumer_users"

    uid = Column(String, primary_key=True) # Firebase UID
    email = Column(String, nullable=False, unique=True, index=True)
    tenant_id = Column(String, nullable=False, index=True)
    full_name = Column(String)
    default_shipping_address = Column(JSON) # {address1, address2, city, state, zip, country}
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
