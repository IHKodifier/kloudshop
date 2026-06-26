from pydantic import BaseModel
from typing import List, Optional
from decimal import Decimal

class TaxRateBase(BaseModel):
    country_code: str
    state_code: Optional[str] = None
    tax_percentage: Decimal
    is_active: bool = True

class TaxRateCreate(TaxRateBase):
    pass

class TaxRateResponse(TaxRateBase):
    tax_rate_id: str
    tenant_id: str

    class Config:
        from_attributes = True

# Checkout Calculation Schemas
class TaxCalculateItem(BaseModel):
    variant_id: str
    quantity: int

class TaxCalculateRequest(BaseModel):
    country_code: str
    state_code: Optional[str] = None
    items: List[TaxCalculateItem]

class TaxCalculateResponse(BaseModel):
    total_tax_amount: Decimal
    tax_rate_percentage: Decimal
    calculation_mode: str  # stripe_automated / manual_fallback
