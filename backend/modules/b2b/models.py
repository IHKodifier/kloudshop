from sqlalchemy import Column, String, Text, Boolean, Integer, Numeric, DateTime, JSON, ForeignKey, CheckConstraint, CHAR, VARCHAR
from sqlalchemy.orm import relationship
from shared.db import Base, engine
import uuid
from datetime import datetime, timezone

# Schema name for platform-wide tables (not used for tenant tables in SQLite mode)
SCHEMA = "kloudshop_platform" if "sqlite" not in engine.url.drivername else None

class B2BAccount(Base):
    __tablename__ = "b2b_accounts"

    b2b_account_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)

    # Identity
    company_name = Column(Text, nullable=False)
    contact_first_name = Column(Text, nullable=False)
    contact_last_name = Column(Text, nullable=False)
    contact_email = Column(String, nullable=False, unique=True)
    contact_phone = Column(Text)

    # Firebase Auth
    firebase_uid = Column(String, unique=True)

    # Commercial Terms
    credit_limit = Column(Numeric(12, 2))
    net_terms_days = Column(Integer)
    price_list_id = Column(String, index=True) # References PriceList

    # Status
    account_status = Column(VARCHAR(20), nullable=False, default='invited')
    # invited | pending_approval | active | suspended | archived

    # Assignment
    assigned_account_manager_id = Column(String) # staff_user_id

    # Shipping Address
    default_address_line1 = Column(Text)
    default_address_line2 = Column(Text)
    default_address_city = Column(Text)
    default_address_state = Column(Text)
    default_address_postcode = Column(Text)
    default_address_country = Column(CHAR(2))

    # Internal Notes
    notes = Column(Text)

    # Invitation Tracking
    invited_by = Column(String) # staff_user_id
    invited_at = Column(DateTime)
    registered_at = Column(DateTime)
    last_login_at = Column(DateTime)

    # Metadata
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        CheckConstraint(account_status.in_(['invited', 'pending_approval', 'active', 'suspended', 'archived']), name='b2b_accounts_status_check'),
        CheckConstraint('credit_limit IS NULL OR credit_limit >= 0', name='b2b_accounts_credit_limit_non_negative'),
        CheckConstraint('net_terms_days IS NULL OR net_terms_days >= 1', name='b2b_accounts_net_terms_positive'),
        CheckConstraint('registered_at IS NULL OR firebase_uid IS NOT NULL', name='b2b_accounts_registered_requires_uid'),
    )

class PriceList(Base):
    __tablename__ = "price_lists"

    price_list_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)

    name = Column(Text, nullable=False)
    description = Column(Text)
    currency_code = Column(CHAR(3), nullable=False, default='USD')
    is_default = Column(Boolean, nullable=False, default=False)
    is_active = Column(Boolean, nullable=False, default=True)

    effective_from = Column(DateTime)
    effective_to = Column(DateTime)

    created_by = Column(String, nullable=False) # staff_user_id
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    items = relationship("PriceListItem", back_populates="price_list", cascade="all, delete-orphan")

    __table_args__ = (
        CheckConstraint('length(currency_code) = 3', name='price_lists_currency_length'),
        CheckConstraint('effective_to IS NULL OR effective_from IS NULL OR effective_to > effective_from', name='price_lists_effective_dates_check'),
    )

class PriceListItem(Base):
    __tablename__ = "price_list_items"

    price_list_id = Column(String, ForeignKey("price_lists.price_list_id", ondelete="CASCADE"), primary_key=True)
    variant_id = Column(String, primary_key=True) # References variants table (no hard FK for SQLite cross-module simplicity if needed, but variants is in same DB)
    
    override_type = Column(VARCHAR(16), nullable=False, default='fixed') # fixed | percentage
    override_price = Column(Numeric(12, 2))
    override_discount_pct = Column(Numeric(6, 3))

    created_by = Column(String, nullable=False) # staff_user_id
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    price_list = relationship("PriceList", back_populates="items")

    __table_args__ = (
        CheckConstraint(override_type.in_(['fixed', 'percentage']), name='price_list_items_override_type_check'),
        CheckConstraint("override_type != 'fixed' OR (override_price IS NOT NULL AND override_discount_pct IS NULL)", name='price_list_items_fixed_exclusive'),
        CheckConstraint("override_type != 'percentage' OR (override_discount_pct IS NOT NULL AND override_price IS NULL)", name='price_list_items_percentage_exclusive'),
        CheckConstraint('override_price IS NULL OR override_price >= 0', name='price_list_items_override_price_non_negative'),
        CheckConstraint('override_discount_pct IS NULL OR (override_discount_pct > 0 AND override_discount_pct <= 100)', name='price_list_items_discount_pct_range'),
    )

class ApprovalWorkflow(Base):
    __tablename__ = "approval_workflows"

    workflow_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)

    is_enabled = Column(Boolean, nullable=False, default=False)
    auto_approve_under = Column(Numeric(12, 2))
    auto_approve_within_credit_limit = Column(Boolean, nullable=False, default=True)
    approver_roles = Column(JSON, nullable=False, default=["owner", "admin"])
    escalation_hours = Column(Integer)

    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        CheckConstraint('auto_approve_under IS NULL OR auto_approve_under >= 0', name='approval_workflows_auto_approve_non_negative'),
        CheckConstraint('escalation_hours IS NULL OR escalation_hours >= 1', name='approval_workflows_escalation_positive'),
    )

class ApprovalRequest(Base):
    __tablename__ = "approval_requests"

    approval_request_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)

    order_id = Column(String, nullable=False, unique=True)
    b2b_account_id = Column(String, ForeignKey("b2b_accounts.b2b_account_id"), nullable=False)
    
    order_grand_total = Column(Numeric(12, 2), nullable=False)
    currency_code = Column(CHAR(3), nullable=False)
    
    status = Column(VARCHAR(16), nullable=False, default='pending') # pending | approved | auto_approved | declined
    
    decided_by = Column(String) # staff_user_id
    decided_at = Column(DateTime)
    decline_reason = Column(Text)
    
    escalation_sent_at = Column(DateTime)
    requested_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        CheckConstraint(status.in_(['pending', 'approved', 'auto_approved', 'declined']), name='approval_requests_status_check'),
        CheckConstraint("status = 'pending' OR decided_at IS NOT NULL", name='approval_requests_decision_consistency'),
        CheckConstraint('order_grand_total >= 0', name='approval_requests_order_total_non_negative'),
    )

class B2BInvoice(Base):
    __tablename__ = "b2b_invoices"

    invoice_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)

    order_id = Column(String, nullable=False, unique=True)
    stripe_invoice_id = Column(String, unique=True)
    
    payment_status = Column(VARCHAR(20), nullable=False, default='open') # draft | open | paid | void | uncollectible
    due_date = Column(DateTime)
    
    invoice_amount = Column(Numeric(12, 2), nullable=False)
    currency_code = Column(CHAR(3), nullable=False)
    
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        CheckConstraint(payment_status.in_(['draft', 'open', 'paid', 'void', 'uncollectible']), name='b2b_invoices_payment_status_check'),
    )
