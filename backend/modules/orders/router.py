from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import selectinload
from typing import List, Optional
import uuid
import csv
import io
from datetime import datetime
from decimal import Decimal

from shared.db import get_db
from shared.auth import UserClaims
from shared.rbac import has_permissions
from .models import Order, OrderItem, OrderEvent, OrderNote
from ..inventory.models import StockLocation, Inventory
from .schemas import (
    OrderResponse, PaymentIntentRequest, PaymentIntentResponse, OrderConfirmRequest,
    StockLocationResponse, StockLocationCreate, InventoryResponse,
    OrderFulfilRequest, OrderRefundRequest
)
from ..catalog.models import Variant, Product

router = APIRouter()

# Mock Stripe (In production, use 'import stripe' and set stripe.api_key)
class MockStripe:
    async def create_payment_intent(self, amount: int, currency: str, metadata: dict):
        # Simulate Stripe API call
        return {
            "id": f"pi_{uuid.uuid4().hex[:16]}",
            "client_secret": f"secret_{uuid.uuid4().hex}",
            "amount": amount,
            "currency": currency
        }
    
    async def retrieve_payment_intent(self, pi_id: str):
        # Simulate retrieval
        return {
            "id": pi_id,
            "status": "succeeded", # Mocked as always succeeded for now
            "amount": 1000,
            "currency": "usd"
        }
    
    async def create_refund(self, pi_id: str, amount: int = None):
        # Simulate refund API call
        return {
            "id": f"re_{uuid.uuid4().hex[:16]}",
            "payment_intent": pi_id,
            "status": "succeeded",
            "amount": amount
        }

stripe_client = MockStripe()

@router.post("/checkout/payment-intent", response_model=PaymentIntentResponse)
async def create_payment_intent(
    request: PaymentIntentRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Step 1: Calculate total and create Stripe PaymentIntent.
    Public storefront endpoint.
    """
    total_amount = Decimal("0.00")
    
    for item in request.items:
        result = await db.execute(select(Variant).where(Variant.variant_id == item.variant_id))
        variant = result.scalars().first()
        if not variant:
            raise HTTPException(status_code=404, detail=f"Variant {item.variant_id} not found")
        
        total_amount += variant.price * item.quantity
    
    # Stripe expects amount in cents
    amount_cents = int(total_amount * 100)
    
    intent = await stripe_client.create_payment_intent(
        amount=amount_cents,
        currency=request.currency,
        metadata={"email": request.email}
    )
    
    return PaymentIntentResponse(
        client_secret=intent["client_secret"],
        payment_intent_id=intent["id"],
        amount=intent["amount"],
        currency=intent["currency"]
    )

@router.post("/checkout/confirm", response_model=OrderResponse)
async def confirm_order(
    request: OrderConfirmRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Step 2: Verify payment and create order with atomic inventory decrement.
    Public storefront endpoint.
    """
    # 1. Verify Payment Intent
    intent = await stripe_client.retrieve_payment_intent(request.payment_intent_id)
    if intent["status"] != "succeeded":
        raise HTTPException(status_code=400, detail="Payment not successful")
    
    # 2. Get Metadata (In real Stripe, this comes from the intent)
    email = "customer@example.com" # Mocked
    tenant_id = "t_mock" # This would be derived from the storefront context/tenant_id path param
    
    # 3. Create Order Number
    order_number = f"KS-{uuid.uuid4().hex[:6].upper()}"
    
    # 4. Atomic Inventory Update & Order Creation
    # We use a nested transaction or rely on the DI session
    try:
        # Find default stock location for tenant
        loc_result = await db.execute(
            select(StockLocation).where(
                StockLocation.is_default == True,
                StockLocation.is_active == True
            )
        )
        location = loc_result.scalars().first()
        if not location:
            # Fallback to any active location if no default
            loc_result = await db.execute(select(StockLocation).where(StockLocation.is_active == True))
            location = loc_result.scalars().first()
        
        if not location:
            raise HTTPException(status_code=500, detail="No active stock locations configured for this store")

        new_order = Order(
            order_number=order_number,
            tenant_id=tenant_id,
            email=email,
            payment_status="paid",
            fulfilment_status="unfulfilled",
            currency=intent["currency"].upper(),
            subtotal=Decimal("0.00"), # Will calculate below
            grand_total=Decimal(intent["amount"]) / 100,
            shipping_name=request.shipping_name,
            shipping_address1=request.shipping_address1,
            shipping_address2=request.shipping_address2,
            shipping_city=request.shipping_city,
            shipping_state=request.shipping_state,
            shipping_postcode=request.shipping_postcode,
            shipping_country=request.shipping_country,
            stripe_payment_intent_id=request.payment_intent_id
        )
        db.add(new_order)
        await db.flush()

        # In a real scenario, items would come from the PaymentIntent metadata or a Cart session
        # For this skeleton, we assume the items were validated at intent creation.
        # Here we mock one item for demonstration if none provided (normally items are passed)
        
        # 5. Process Items & Inventory
        subtotal = Decimal("0.00")
        for item in request.items:
            # Lock Inventory row
            inv_result = await db.execute(
                select(Inventory).where(
                    Inventory.variant_id == item.variant_id,
                    Inventory.stock_location_id == location.stock_location_id
                ).with_for_update()
            )
            inventory = inv_result.scalars().first()
            
            if not inventory or inventory.quantity_on_hand < item.quantity:
                # Handle over-selling: In real app, we might check other locations
                raise HTTPException(status_code=400, detail=f"Insufficient stock for variant {item.variant_id}")
            
            # Fetch Variant for snapshots
            v_result = await db.execute(select(Variant).options(selectinload(Variant.product)).where(Variant.variant_id == item.variant_id))
            variant = v_result.scalars().first()
            
            # Create Order Item (Snapshotting price and title)
            order_item = OrderItem(
                order_id=new_order.order_id,
                variant_id=variant.variant_id,
                product_id=variant.product_id,
                title=f"{variant.product.title} ({variant.option_1 or 'Default'})",
                sku=variant.sku,
                quantity=item.quantity,
                unit_price=variant.price,
                total_price=variant.price * item.quantity,
                is_digital=variant.product.is_digital
            )
            db.add(order_item)
            subtotal += order_item.total_price
            
            # Decrement Inventory
            inventory.quantity_on_hand -= item.quantity
            inventory.last_sold_at = datetime.utcnow()

        new_order.subtotal = subtotal
        await db.commit()
        await db.refresh(new_order)
        
        # Log Event
        event = OrderEvent(
            order_id=new_order.order_id,
            event_type="payment_confirmed",
            description=f"Payment of {new_order.grand_total} {new_order.currency} confirmed via Stripe."
        )
        db.add(event)
        await db.commit()
        
        # Re-fetch with relationships
        result = await db.execute(
            select(Order).options(
                selectinload(Order.items),
                selectinload(Order.events),
                selectinload(Order.notes)
            ).where(Order.order_id == new_order.order_id)
        )
        return result.scalars().first()

    except HTTPException:
        await db.rollback()
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Order confirmation failed: {str(e)}")

# --- Admin Endpoints ---

@router.get("/", response_model=List[OrderResponse])
async def list_orders(
    limit: int = 100,
    offset: int = 0,
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["orders:read"])
):
    query = select(Order).options(
        selectinload(Order.items),
        selectinload(Order.events),
        selectinload(Order.notes)
    ).where(Order.tenant_id == user.tenant_id)
    
    if status:
        query = query.where(Order.fulfilment_status == status)
        
    query = query.order_by(Order.placed_at.desc()).offset(offset).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()

@router.get("/export")
async def export_orders(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["orders:read"])
):
    """
    Export orders for the tenant as a CSV file.
    """
    query = select(Order).where(Order.tenant_id == user.tenant_id)
    
    if start_date:
        query = query.where(Order.placed_at >= start_date)
    if end_date:
        query = query.where(Order.placed_at <= end_date)
    if status:
        query = query.where(Order.fulfilment_status == status)
        
    result = await db.execute(query.order_by(Order.placed_at.desc()))
    orders = result.scalars().all()
    
    output = io.StringIO()
    writer = csv.writer(output)
    
    # Header
    writer.writerow([
        "Order Number", "Date", "Email", "Payment Status", 
        "Fulfilment Status", "Currency", "Grand Total", "Shipping Name"
    ])
    
    for o in orders:
        writer.writerow([
            o.order_number,
            o.placed_at.strftime("%Y-%m-%d %H:%M:%S") if o.placed_at else "",
            o.email,
            o.payment_status,
            o.fulfilment_status,
            o.currency,
            float(o.grand_total),
            o.shipping_name
        ])
    
    output.seek(0)
    
    filename = f"orders_export_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
    
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )

@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["orders:read"])
):
    result = await db.execute(
        select(Order).options(
            selectinload(Order.items),
            selectinload(Order.events),
            selectinload(Order.notes)
        ).where(
            Order.order_id == order_id,
            Order.tenant_id == user.tenant_id
        )
    )
    order = result.scalars().first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order

@router.patch("/{order_id}/fulfil", response_model=OrderResponse)
async def fulfil_order(
    order_id: str,
    data: OrderFulfilRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["orders:write"])
):
    """
    Mark an order as fulfilled and log tracking information.
    """
    result = await db.execute(
        select(Order).where(Order.order_id == order_id, Order.tenant_id == user.tenant_id)
    )
    order = result.scalars().first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    if order.fulfilment_status == "fulfilled":
        raise HTTPException(status_code=400, detail="Order is already fulfilled")
    
    order.fulfilment_status = "fulfilled"
    
    # Log Event
    event = OrderEvent(
        order_id=order.order_id,
        event_type="order_fulfilled",
        description=f"Order fulfilled. Carrier: {data.carrier}, Tracking: {data.tracking_number}",
        actor_id=user.uid
    )
    db.add(event)
    
    await db.commit()
    await db.refresh(order)
    
    # Re-fetch with relationships
    result = await db.execute(
        select(Order).options(
            selectinload(Order.items),
            selectinload(Order.events),
            selectinload(Order.notes)
        ).where(Order.order_id == order_id)
    )
    return result.scalars().first()

@router.post("/{order_id}/refund", response_model=OrderResponse)
async def refund_order(
    order_id: str,
    data: OrderRefundRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["orders:write"])
):
    """
    Refund an order via Stripe.
    """
    result = await db.execute(
        select(Order).where(Order.order_id == order_id, Order.tenant_id == user.tenant_id)
    )
    order = result.scalars().first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    if order.payment_status not in ["paid", "partially_refunded"]:
        raise HTTPException(status_code=400, detail="Order payment status does not allow refund")
    
    # Stripe Refund
    refund_amount_cents = int(data.amount * 100) if data.amount else None
    await stripe_client.create_refund(order.stripe_payment_intent_id, refund_amount_cents)
    
    if data.amount and data.amount < order.grand_total:
        order.payment_status = "partially_refunded"
    else:
        order.payment_status = "refunded"
    
    # Log Event
    event = OrderEvent(
        order_id=order.order_id,
        event_type="order_refunded",
        description=f"Refund issued. Amount: {data.amount or order.grand_total} {order.currency}. Reason: {data.reason}",
        actor_id=user.uid
    )
    db.add(event)
    
    await db.commit()
    await db.refresh(order)
    
    # Re-fetch with relationships
    result = await db.execute(
        select(Order).options(
            selectinload(Order.items),
            selectinload(Order.events),
            selectinload(Order.notes)
        ).where(Order.order_id == order_id)
    )
    return result.scalars().first()

# --- Inventory Admin ---

@router.post("/locations", response_model=StockLocationResponse, status_code=status.HTTP_201_CREATED)
async def create_location(
    data: StockLocationCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["inventory:write"])
):
    new_loc = StockLocation(**data.model_dump())
    db.add(new_loc)
    await db.commit()
    await db.refresh(new_loc)
    return new_loc

@router.get("/locations", response_model=List[StockLocationResponse])
async def list_locations(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["inventory:read"])
):
    result = await db.execute(select(StockLocation).where(StockLocation.is_active == True))
    return result.scalars().all()
