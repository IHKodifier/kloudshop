from sqlalchemy import Column, String, DateTime, JSON, Boolean, ForeignKey, Integer
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

class StaffLoginHistory(Base):
    __tablename__ = "staff_login_history"
    __table_args__ = {"schema": SCHEMA} if SCHEMA else {}

    login_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    staff_user_id = Column(String, ForeignKey(f"{SCHEMA}.staff_users.uid" if SCHEMA else "staff_users.uid", ondelete="SET NULL"), nullable=True)
    tenant_id = Column(String, nullable=True, index=True)
    ip_address = Column(String, nullable=False)
    user_agent = Column(String, nullable=True)
    country_code = Column(String, nullable=True)
    country_name = Column(String, nullable=True)
    region_name = Column(String, nullable=True)
    city_name = Column(String, nullable=True)
    latitude = Column(String, nullable=True)
    longitude = Column(String, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

class StaffSecurityState(Base):
    __tablename__ = "staff_security_states"
    __table_args__ = {"schema": SCHEMA} if SCHEMA else {}

    gmail = Column(String, primary_key=True) # lowercase email
    failed_attempts_count = Column(Integer, nullable=False, default=0)
    last_failed_attempt_at = Column(DateTime, nullable=True)
    cool_off_until = Column(DateTime, nullable=True)
    failed_days_count = Column(Integer, nullable=False, default=0)
    last_failed_day = Column(String, nullable=True) # stored as 'YYYY-MM-DD'
    is_blocked = Column(Boolean, nullable=False, default=False)
    unblock_token = Column(String, nullable=True, index=True)
    unblock_token_expires_at = Column(DateTime, nullable=True)
    unblock_request_count = Column(Integer, nullable=False, default=0)
    last_unblock_request_at = Column(DateTime, nullable=True)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
