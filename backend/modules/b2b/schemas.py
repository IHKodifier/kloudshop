from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional
from datetime import datetime
from decimal import Decimal
from enum import Enum

class AccountStatus(str, Enum):
    invited = "invited"
    pending_approval = "pending_approval"
    active = "active"
    suspended = "suspended"
    archived = "archived"

class OverrideType(str, Enum):
    fixed = "fixed"
    percentage = "percentage"

class ApprovalStatus(str, Enum):
    pending = "pending"
    approved = "approved"
    auto_approved = "auto_approved"
    declined = "declined"

class InvoicePaymentStatus(str, Enum):
    draft = "draft"
    open = "open"
    paid = "paid"
    void = "void"
    uncollectible = "uncollectible"

# ── Buyer Accounts ───────────────────────────────────────────

class B2BAccountBase(BaseModel):
    company_name: str
    contact_first_name: str
    contact_last_name: str
    contact_email: EmailStr
    contact_phone: Optional[str] = None
    credit_limit: Optional[Decimal] = None
    net_terms_days: Optional[int] = None
    price_list_id: Optional[str] = None
    assigned_account_manager_id: Optional[str] = None
    notes: Optional[str] = None
    default_address_line1: Optional[str] = None
    default_address_line2: Optional[str] = None
    default_address_city: Optional[str] = None
    default_address_state: Optional[str] = None
    default_address_postcode: Optional[str] = None
    default_address_country: Optional[str] = Field(None, min_length=2, max_length=2)

class B2BAccountCreate(B2BAccountBase):
    pass

class B2BAccountUpdate(BaseModel):
    company_name: Optional[str] = None
    contact_first_name: Optional[str] = None
    contact_last_name: Optional[str] = None
    contact_phone: Optional[str] = None
    credit_limit: Optional[Decimal] = None
    net_terms_days: Optional[int] = None
    price_list_id: Optional[str] = None
    account_status: Optional[AccountStatus] = None
    assigned_account_manager_id: Optional[str] = None
    notes: Optional[str] = None

class B2BAccountResponse(B2BAccountBase):
    b2b_account_id: str
    tenant_id: str
    account_status: AccountStatus
    firebase_uid: Optional[str] = None
    invited_by: Optional[str] = None
    invited_at: Optional[datetime] = None
    registered_at: Optional[datetime] = None
    last_login_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# ── Price Lists ──────────────────────────────────────────────

class PriceListItemBase(BaseModel):
    variant_id: str
    override_type: OverrideType
    override_price: Optional[Decimal] = None
    override_discount_pct: Optional[Decimal] = None

class PriceListItemCreate(PriceListItemBase):
    pass

class PriceListItemResponse(PriceListItemBase):
    price_list_id: str
    created_by: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class PriceListBase(BaseModel):
    name: str
    description: Optional[str] = None
    currency_code: str = "USD"
    is_default: bool = False
    is_active: bool = True
    effective_from: Optional[datetime] = None
    effective_to: Optional[datetime] = None

class PriceListCreate(PriceListBase):
    items: Optional[List[PriceListItemCreate]] = None

class PriceListUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    currency_code: Optional[str] = None
    is_default: Optional[bool] = None
    is_active: Optional[bool] = None
    effective_from: Optional[datetime] = None
    effective_to: Optional[datetime] = None

class PriceListResponse(PriceListBase):
    price_list_id: str
    tenant_id: str
    created_by: str
    created_at: datetime
    updated_at: datetime
    items: Optional[List[PriceListItemResponse]] = None

    class Config:
        from_attributes = True

# ── Approval Workflows ───────────────────────────────────────

class ApprovalWorkflowBase(BaseModel):
    is_enabled: bool = False
    auto_approve_under: Optional[Decimal] = None
    auto_approve_within_credit_limit: bool = True
    approver_roles: List[str] = ["owner", "admin"]
    escalation_hours: Optional[int] = None

class ApprovalWorkflowUpdate(ApprovalWorkflowBase):
    pass

class ApprovalWorkflowResponse(ApprovalWorkflowBase):
    workflow_id: str
    tenant_id: str
    updated_at: datetime

    class Config:
        from_attributes = True

# ── Approval Requests ────────────────────────────────────────

class ApprovalRequestResponse(BaseModel):
    approval_request_id: str
    tenant_id: str
    order_id: str
    b2b_account_id: str
    order_grand_total: Decimal
    currency_code: str
    status: ApprovalStatus
    decided_by: Optional[str] = None
    decided_at: Optional[datetime] = None
    decline_reason: Optional[str] = None
    requested_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# ── B2B Invoices ─────────────────────────────────────────────

class B2BInvoiceResponse(BaseModel):
    invoice_id: str
    tenant_id: str
    order_id: str
    stripe_invoice_id: Optional[str] = None
    payment_status: InvoicePaymentStatus
    due_date: Optional[datetime] = None
    invoice_amount: Decimal
    currency_code: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# ── B2B Portal (Buyer View) ──────────────────────────────────

class B2BPortalOrderItem(BaseModel):
    variant_id: str
    quantity: int = Field(..., gt=0)

class B2BPortalOrderRequest(BaseModel):
    items: List[B2BPortalOrderItem]
    shipping_name: str
    shipping_address1: str
    shipping_address2: Optional[str] = None
    shipping_city: str
    shipping_state: str
    shipping_postcode: str
    shipping_country: str = "US"
    notes: Optional[str] = None
