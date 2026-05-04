from pydantic import BaseModel, EmailStr
from typing import List, Optional
from decimal import Decimal
from datetime import datetime

class POSItemCreate(BaseModel):
    variant_id: str
    quantity: int

class POSOrderCreate(BaseModel):
    items: List[POSItemCreate]
    payment_method: str # 'cash', 'external_card', 'other'
    buyer_email: Optional[str] = None # Optional for POS receipts
    currency: str = "USD"

class StaffLocationAssignmentCreate(BaseModel):
    staff_user_id: str
    stock_location_id: str

class StaffLocationAssignmentSchema(BaseModel):
    id: str
    staff_user_id: str
    stock_location_id: str
    assigned_at: datetime

    class Config:
        from_attributes = True

class POSLocationResponse(BaseModel):
    stock_location_id: str
    name: str
