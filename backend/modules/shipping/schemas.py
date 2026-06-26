from pydantic import BaseModel, Field
from typing import List, Optional
from decimal import Decimal

class ShippingRateBase(BaseModel):
    name: str
    price: Decimal
    min_value: Optional[Decimal] = None
    max_value: Optional[Decimal] = None
    min_weight: Optional[Decimal] = None
    max_weight: Optional[Decimal] = None
    rate_type: str = "flat"  # flat / weight_based / price_based

class ShippingRateCreate(ShippingRateBase):
    pass

class ShippingRateResponse(ShippingRateBase):
    rate_id: str
    zone_id: str
    tenant_id: str

    class Config:
        from_attributes = True

class ShippingZoneBase(BaseModel):
    name: str
    countries: List[str] = Field(default_factory=list) # List of ISO 2-letter codes

class ShippingZoneCreate(ShippingZoneBase):
    pass

class ShippingZoneResponse(ShippingZoneBase):
    zone_id: str
    profile_id: str
    tenant_id: str
    rates: List[ShippingRateResponse] = Field(default_factory=list)

    class Config:
        from_attributes = True

class ShippingProfileBase(BaseModel):
    name: str
    is_general: bool = False

class ShippingProfileCreate(ShippingProfileBase):
    pass

class ShippingProfileResponse(ShippingProfileBase):
    profile_id: str
    tenant_id: str
    zones: List[ShippingZoneResponse] = Field(default_factory=list)

    class Config:
        from_attributes = True

# Checkout Calculation Schemas
class ShippingCalculateItem(BaseModel):
    variant_id: str
    quantity: int

class ShippingCalculateRequest(BaseModel):
    country_code: str
    items: List[ShippingCalculateItem]

class BlendedRateDetail(BaseModel):
    profile_name: str
    rate_name: str
    price: Decimal

class ShippingCalculateResponse(BaseModel):
    total_shipping_price: Decimal
    rates: List[BlendedRateDetail]
