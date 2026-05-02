from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional
from datetime import datetime
from decimal import Decimal
from uuid import UUID

class StockLocationBase(BaseModel):
    name: str
    location_type: str = "warehouse"
    address_line1: Optional[str] = None
    address_line2: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    postcode: Optional[str] = None
    country_code: Optional[str] = Field(None, min_length=2, max_length=2)
    fulfils_online: bool = True
    fulfils_pos: bool = False
    is_default: bool = False
    is_active: bool = True

class StockLocationCreate(StockLocationBase):
    pass

class StockLocationResponse(StockLocationBase):
    stock_location_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class InventoryBase(BaseModel):
    variant_id: str
    stock_location_id: str
    quantity_on_hand: int = 0
    quantity_reserved: int = 0
    reorder_point: Optional[int] = None
    reorder_quantity: Optional[int] = None

class InventoryResponse(InventoryBase):
    inventory_id: str
    quantity_available: int
    last_received_at: Optional[datetime] = None
    last_sold_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

    @property
    def quantity_available(self) -> int:
        return self.quantity_on_hand - self.quantity_reserved

class OrderItemBase(BaseModel):
    variant_id: str
    quantity: int = Field(..., gt=0)

class OrderItemResponse(BaseModel):
    order_item_id: str
    variant_id: str
    product_id: str
    title: str
    sku: Optional[str] = None
    quantity: int
    unit_price: Decimal
    total_price: Decimal
    tax_amount: Decimal
    taxable: bool
    is_digital: bool

    class Config:
        from_attributes = True

class OrderEventResponse(BaseModel):
    event_id: str
    event_type: str
    description: Optional[str] = None
    actor_id: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class OrderNoteBase(BaseModel):
    content: str
    is_customer_visible: bool = False

class OrderNoteCreate(OrderNoteBase):
    pass

class OrderNoteResponse(OrderNoteBase):
    note_id: str
    author_id: str
    created_at: datetime

    class Config:
        from_attributes = True

class OrderResponse(BaseModel):
    order_id: str
    order_number: str
    tenant_id: str
    consumer_id: Optional[str] = None
    email: EmailStr
    payment_status: str
    fulfilment_status: str
    currency: str
    subtotal: Decimal
    tax_total: Decimal
    shipping_total: Decimal
    grand_total: Decimal
    shipping_name: Optional[str] = None
    shipping_address1: Optional[str] = None
    shipping_address2: Optional[str] = None
    shipping_city: Optional[str] = None
    shipping_state: Optional[str] = None
    shipping_postcode: Optional[str] = None
    shipping_country: Optional[str] = None
    placed_at: datetime
    cancelled_at: Optional[datetime] = None
    updated_at: datetime
    items: List[OrderItemResponse]
    events: List[OrderEventResponse]
    notes: List[OrderNoteResponse]

    class Config:
        from_attributes = True

class PaymentIntentRequest(BaseModel):
    items: List[OrderItemBase]
    currency: str = "usd"
    email: EmailStr

class PaymentIntentResponse(BaseModel):
    client_secret: str
    payment_intent_id: str
    amount: int # In cents
    currency: str

class OrderConfirmRequest(BaseModel):
    payment_intent_id: str
    items: List[OrderItemBase] # In real app, this might come from server-side cart
    shipping_name: str
    shipping_address1: str
    shipping_address2: Optional[str] = None
    shipping_city: str
    shipping_state: str
    shipping_postcode: str
    shipping_country: str = "US"

class OrderFulfilRequest(BaseModel):
    tracking_number: Optional[str] = None
    tracking_url: Optional[str] = None
    carrier: Optional[str] = None
    notify_customer: bool = True

class OrderRefundRequest(BaseModel):
    amount: Optional[Decimal] = None # NULL means full refund
    reason: Optional[str] = None
    refund_items: Optional[List[OrderItemBase]] = None
