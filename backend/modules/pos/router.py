from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, func
from sqlalchemy.orm import selectinload
from decimal import Decimal
from datetime import datetime, timezone
import uuid

from shared.db import get_db
from shared.auth import UserClaims
from shared.rbac import has_permissions
from .models import StaffLocationAssignment
from .schemas import (
    POSOrderCreate, POSLocationResponse, 
    StaffLocationAssignmentCreate, StaffLocationAssignmentSchema
)
from modules.inventory.models import Inventory, StockLocation
from modules.catalog.models import Variant, Product
from modules.orders.models import Order, OrderItem, OrderEvent

router = APIRouter(tags=["POS"])

async def get_staff_location(staff_uid: str, tenant_id: str, db: AsyncSession):
    result = await db.execute(
        select(StaffLocationAssignment)
        .where(
            StaffLocationAssignment.staff_user_id == staff_uid,
            StaffLocationAssignment.tenant_id == tenant_id
        )
    )
    return result.scalar_one_or_none()

@router.get("/location", response_model=POSLocationResponse)
async def get_my_pos_location(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["pos:read"])
):
    assignment = await get_staff_location(user.uid, user.tenant_id, db)
    if not assignment:
        raise HTTPException(status_code=403, detail="Staff member not assigned to any POS location.")
    
    loc_result = await db.execute(
        select(StockLocation).where(StockLocation.stock_location_id == assignment.stock_location_id)
    )
    location = loc_result.scalar_one_or_none()
    if not location:
        raise HTTPException(status_code=404, detail="Assigned location not found.")
    
    return POSLocationResponse(
        stock_location_id=location.stock_location_id,
        name=location.name
    )

@router.post("/orders")
async def create_pos_order(
    order_in: POSOrderCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["pos:write"])
):
    # 1. Get staff location
    assignment = await get_staff_location(user.uid, user.tenant_id, db)
    if not assignment:
        raise HTTPException(status_code=403, detail="Staff member not assigned to any POS location.")
    
    location_id = assignment.stock_location_id
    
    # We use a manual transaction block to ensure all-or-nothing with row-level locks
    # Note: With asyncpg/SQLAlchemy async, we often use async with db.begin()
    
    total_subtotal = Decimal("0.00")
    order_items_to_create = []
    
    # 2. Lock inventory and verify stock
    for item_in in order_in.items:
        # SELECT FOR UPDATE on the inventory row
        inv_result = await db.execute(
            select(Inventory)
            .where(
                Inventory.variant_id == item_in.variant_id,
                Inventory.stock_location_id == location_id
            )
            .with_for_update()
        )
        inventory = inv_result.scalar_one_or_none()
        
        if not inventory or inventory.quantity_on_hand < item_in.quantity:
            await db.rollback()
            raise HTTPException(
                status_code=400, 
                detail=f"Insufficient stock for variant {item_in.variant_id} at location {location_id}"
            )
        
        # Fetch variant with product title
        var_result = await db.execute(
            select(Variant)
            .where(Variant.variant_id == item_in.variant_id)
            .options(selectinload(Variant.product))
        )
        variant = var_result.scalar_one_or_none()
        if not variant:
            await db.rollback()
            raise HTTPException(status_code=404, detail=f"Variant {item_in.variant_id} not found")
        
        # 3. Deduct stock
        inventory.quantity_on_hand -= item_in.quantity
        inventory.last_sold_at = datetime.now(timezone.utc)
        
        # 4. Prepare OrderItem
        item_subtotal = variant.price * item_in.quantity
        total_subtotal += item_subtotal
        
        variant_title = f"{variant.product.title}"
        if variant.option_1:
            variant_title += f" - {variant.option_1}"
            if variant.option_2:
                variant_title += f" / {variant.option_2}"
        
        order_item = OrderItem(
            variant_id=variant.variant_id,
            product_id=variant.product_id,
            title=variant_title,
            sku=variant.sku,
            quantity=item_in.quantity,
            unit_price=variant.price,
            total_price=item_subtotal,
            taxable=variant.taxable
        )
        order_items_to_create.append(order_item)

    # 5. Create Order
    # Generate order number
    count_result = await db.execute(
        select(func.count(Order.order_id)).where(Order.tenant_id == user.tenant_id)
    )
    order_number = f"POS-{1000 + count_result.scalar() + 1}"
    
    order = Order(
        order_number=order_number,
        tenant_id=user.tenant_id,
        order_source_id="pos",
        email=order_in.buyer_email or f"pos_customer_{order_number}@internal.kloudshop.io",
        payment_status="paid",
        fulfilment_status="fulfilled",
        subtotal=total_subtotal,
        grand_total=total_subtotal,
        currency=order_in.currency,
        placed_at=datetime.now(timezone.utc)
    )
    db.add(order)
    await db.flush() # Get order_id
    
    for item in order_items_to_create:
        item.order_id = order.order_id
        db.add(item)
        
    # 6. Record Event
    event = OrderEvent(
        order_id=order.order_id,
        event_type="order_placed",
        description=f"POS Sale processed by {user.uid} at location {location_id}",
        actor_id=user.uid
    )
    db.add(event)
    
    payment_event = OrderEvent(
        order_id=order.order_id,
        event_type="payment_confirmed",
        description=f"Paid via {order_in.payment_method}",
        actor_id=user.uid
    )
    db.add(payment_event)
    
    await db.commit()
    return {"order_id": order.order_id, "order_number": order.order_number, "total": total_subtotal}

@router.post("/assign-location", response_model=StaffLocationAssignmentSchema)
async def assign_staff_location(
    assign_in: StaffLocationAssignmentCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["users:write"])
):
    # Check if assignment already exists
    existing_result = await db.execute(
        select(StaffLocationAssignment).where(
            StaffLocationAssignment.staff_user_id == assign_in.staff_user_id,
            StaffLocationAssignment.tenant_id == user.tenant_id
        )
    )
    assignment = existing_result.scalar_one_or_none()
    
    if assignment:
        assignment.stock_location_id = assign_in.stock_location_id
    else:
        assignment = StaffLocationAssignment(
            tenant_id=user.tenant_id,
            staff_user_id=assign_in.staff_user_id,
            stock_location_id=assign_in.stock_location_id
        )
        db.add(assignment)
    
    await db.commit()
    await db.refresh(assignment)
    return assignment
