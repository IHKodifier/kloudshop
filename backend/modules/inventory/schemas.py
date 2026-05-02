from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime, date
from decimal import Decimal

# --- Suppliers ---

class SupplierBase(BaseModel):
    name: str
    contact_name: Optional[str] = None
    contact_email: Optional[EmailStr] = None
    contact_phone: Optional[str] = None
    
    address_line1: Optional[str] = None
    address_line2: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    postcode: Optional[str] = None
    country_code: Optional[str] = Field(None, min_length=2, max_length=2)
    
    payment_terms: Optional[str] = None
    default_lead_time_days: Optional[int] = Field(None, ge=1)
    currency: str = Field("USD", min_length=3, max_length=3)
    
    status: str = "active"
    notes: Optional[str] = None

class SupplierCreate(SupplierBase):
    pass

class SupplierUpdate(BaseModel):
    name: Optional[str] = None
    contact_name: Optional[str] = None
    contact_email: Optional[EmailStr] = None
    contact_phone: Optional[str] = None
    address_line1: Optional[str] = None
    address_line2: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    postcode: Optional[str] = None
    country_code: Optional[str] = None
    payment_terms: Optional[str] = None
    default_lead_time_days: Optional[int] = None
    currency: Optional[str] = None
    status: Optional[str] = None
    notes: Optional[str] = None

class SupplierResponse(SupplierBase):
    supplier_id: str
    tenant_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# --- Purchase Orders ---

class POLineBase(BaseModel):
    variant_id: str
    quantity_ordered: int = Field(..., ge=1)
    unit_cost: Optional[Decimal] = None
    unit_cost_currency: Optional[str] = None

class POLineCreate(POLineBase):
    pass

class POLineResponse(POLineBase):
    po_line_id: str
    quantity_received: Optional[int] = None
    received_at: Optional[datetime] = None
    manufacture_date: Optional[date] = None
    discrepancy_flag: bool
    discrepancy_notes: Optional[str] = None

    class Config:
        from_attributes = True

class POCreate(BaseModel):
    supplier_id: str
    receiving_location_id: Optional[str] = None
    notes: Optional[str] = None
    lines: List[POLineCreate]

class POUpdate(BaseModel):
    receiving_location_id: Optional[str] = None
    notes: Optional[str] = None
    status: Optional[str] = None # Transitions only

class POResponse(BaseModel):
    po_id: str
    po_number: str
    tenant_id: str
    supplier_id: str
    status: str
    receiving_location_id: Optional[str] = None
    ordered_at: Optional[datetime] = None
    expected_delivery_at: Optional[datetime] = None
    received_at: Optional[datetime] = None
    cancelled_at: Optional[datetime] = None
    total_cost: Optional[Decimal] = None
    total_cost_currency: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    lines: List[POLineResponse]

    class Config:
        from_attributes = True

class POReceiveLine(BaseModel):
    po_line_id: str
    quantity_received: int = Field(..., ge=0)
    manufacture_date: Optional[date] = None
    discrepancy_notes: Optional[str] = None

class POReceiveRequest(BaseModel):
    lines: List[POReceiveLine]

# --- Stock Transfers ---

class StockTransferCreate(BaseModel):
    source_location_id: str
    destination_location_id: str
    variant_id: str
    quantity_transferred: int = Field(..., ge=1)
    notes: Optional[str] = None

class StockTransferResponse(BaseModel):
    transfer_id: str
    tenant_id: str
    source_location_id: str
    destination_location_id: str
    variant_id: str
    quantity_transferred: int
    quantity_received: Optional[int] = None
    status: str
    initiated_at: Optional[datetime] = None
    received_at: Optional[datetime] = None
    notes: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
