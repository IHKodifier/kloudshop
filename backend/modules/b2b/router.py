from fastapi import APIRouter, Depends, HTTPException, status, Query, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from sqlalchemy.orm import selectinload
from typing import List, Optional
from decimal import Decimal
from shared.db import get_db
from shared.auth import UserClaims, validate_token
from shared.rbac import has_permissions
from .models import B2BAccount, PriceList, PriceListItem, ApprovalWorkflow, ApprovalRequest, B2BInvoice
from .schemas import (
    B2BAccountCreate, B2BAccountUpdate, B2BAccountResponse,
    PriceListCreate, PriceListUpdate, PriceListResponse,
    ApprovalWorkflowUpdate, ApprovalWorkflowResponse,
    ApprovalRequestResponse, B2BInvoiceResponse,
    B2BPortalOrderRequest, AccountStatus, ApprovalStatus
)
from ..orders.models import Order, OrderItem, OrderEvent
from ..inventory.models import StockLocation, Inventory
from ..catalog.models import Variant, Product
from ..catalog.schemas import ProductResponse
from shared.notifications import send_b2b_approval_notification
from shared.stripe_mock import stripe_mock
import uuid
from datetime import datetime, timedelta

router = APIRouter(prefix="/b2b", tags=["B2B Operations"])

# ── Buyer Accounts ───────────────────────────────────────────

@router.get("/buyers", response_model=List[B2BAccountResponse])
async def list_buyers(
    search: Optional[str] = None,
    status: Optional[AccountStatus] = None,
    user: UserClaims = has_permissions(["b2b:manage"]),
    db: AsyncSession = Depends(get_db)
):
    query = select(B2BAccount).where(B2BAccount.tenant_id == user.tenant_id)
    if search:
        query = query.where(B2BAccount.company_name.ilike(f"%{search}%") | B2BAccount.contact_email.ilike(f"%{search}%"))
    if status:
        query = query.where(B2BAccount.account_status == status)
    
    result = await db.execute(query)
    return result.scalars().all()

@router.post("/buyers", response_model=B2BAccountResponse, status_code=status.HTTP_201_CREATED)
async def invite_buyer(
    account: B2BAccountCreate,
    user: UserClaims = has_permissions(["b2b:manage"]),
    db: AsyncSession = Depends(get_db)
):
    # Check if email already exists for this tenant
    existing = await db.execute(select(B2BAccount).where(
        B2BAccount.tenant_id == user.tenant_id,
        B2BAccount.contact_email == account.contact_email
    ))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Buyer with this email already exists.")

    new_account = B2BAccount(
        **account.model_dump(),
        tenant_id=user.tenant_id,
        account_status='invited',
        invited_by=user.uid,
        invited_at=datetime.utcnow()
    )
    db.add(new_account)
    await db.commit()
    await db.refresh(new_account)
    return new_account

@router.get("/buyers/{id}", response_model=B2BAccountResponse)
async def get_buyer(
    id: str,
    user: UserClaims = has_permissions(["b2b:manage"]),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(B2BAccount).where(
        B2BAccount.tenant_id == user.tenant_id,
        B2BAccount.b2b_account_id == id
    ))
    buyer = result.scalar_one_or_none()
    if not buyer:
        raise HTTPException(status_code=404, detail="Buyer not found.")
    return buyer

@router.patch("/buyers/{id}", response_model=B2BAccountResponse)
async def update_buyer(
    id: str,
    update_data: B2BAccountUpdate,
    user: UserClaims = has_permissions(["b2b:manage"]),
    db: AsyncSession = Depends(get_db)
):
    query = update(B2BAccount).where(
        B2BAccount.tenant_id == user.tenant_id,
        B2BAccount.b2b_account_id == id
    ).values(**update_data.model_dump(exclude_unset=True)).returning(B2BAccount)
    
    result = await db.execute(query)
    updated_buyer = result.scalar_one_or_none()
    if not updated_buyer:
        raise HTTPException(status_code=404, detail="Buyer not found.")
    
    await db.commit()
    return updated_buyer

@router.patch("/buyers/{id}/approve", response_model=B2BAccountResponse)
async def approve_buyer(
    id: str,
    user: UserClaims = has_permissions(["b2b:approve"]),
    db: AsyncSession = Depends(get_db)
):
    buyer_result = await db.execute(select(B2BAccount).where(
        B2BAccount.tenant_id == user.tenant_id,
        B2BAccount.b2b_account_id == id
    ))
    buyer = buyer_result.scalar_one_or_none()
    if not buyer:
        raise HTTPException(status_code=404, detail="Buyer not found.")
    
    if buyer.account_status != 'pending_approval':
        raise HTTPException(status_code=400, detail="Buyer is not pending approval.")
    
    buyer.account_status = 'active'
    await db.commit()
    await db.refresh(buyer)
    return buyer

# ── Price Lists ──────────────────────────────────────────────

@router.get("/price-lists", response_model=List[PriceListResponse])
async def list_price_lists(
    user: UserClaims = has_permissions(["b2b:manage"]),
    db: AsyncSession = Depends(get_db)
):
    query = select(PriceList).where(PriceList.tenant_id == user.tenant_id).options(selectinload(PriceList.items))
    result = await db.execute(query)
    return result.scalars().all()

@router.post("/price-lists", response_model=PriceListResponse, status_code=status.HTTP_201_CREATED)
async def create_price_list(
    price_list: PriceListCreate,
    user: UserClaims = has_permissions(["b2b:manage"]),
    db: AsyncSession = Depends(get_db)
):
    new_list = PriceList(
        **price_list.model_dump(exclude={"items"}),
        tenant_id=user.tenant_id,
        created_by=user.uid
    )
    db.add(new_list)
    await db.flush() # Get ID

    if price_list.items:
        for item in price_list.items:
            new_item = PriceListItem(
                **item.model_dump(),
                price_list_id=new_list.price_list_id,
                created_by=user.uid
            )
            db.add(new_item)
    
    await db.commit()
    
    # Reload with items for response
    result = await db.execute(
        select(PriceList)
        .where(PriceList.price_list_id == new_list.price_list_id)
        .options(selectinload(PriceList.items))
    )
    return result.scalar_one()

@router.get("/price-lists/{id}", response_model=PriceListResponse)
async def get_price_list(
    id: str,
    user: UserClaims = has_permissions(["b2b:manage"]),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(PriceList)
        .where(PriceList.tenant_id == user.tenant_id, PriceList.price_list_id == id)
        .options(selectinload(PriceList.items))
    )
    price_list = result.scalar_one_or_none()
    if not price_list:
        raise HTTPException(status_code=404, detail="Price list not found.")
    return price_list

# ── Approval Workflows ───────────────────────────────────────

@router.get("/approval-workflow", response_model=ApprovalWorkflowResponse)
async def get_approval_workflow(
    user: UserClaims = has_permissions(["b2b:manage"]),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(ApprovalWorkflow).where(ApprovalWorkflow.tenant_id == user.tenant_id))
    workflow = result.scalar_one_or_none()
    if not workflow:
        # Create default workflow if not exists (seed row)
        workflow = ApprovalWorkflow(tenant_id=user.tenant_id)
        db.add(workflow)
        await db.commit()
        await db.refresh(workflow)
    return workflow

@router.put("/approval-workflow", response_model=ApprovalWorkflowResponse)
async def update_approval_workflow(
    update_data: ApprovalWorkflowUpdate,
    user: UserClaims = has_permissions(["b2b:manage"]),
    db: AsyncSession = Depends(get_db)
):
    # Upsert pattern
    result = await db.execute(select(ApprovalWorkflow).where(ApprovalWorkflow.tenant_id == user.tenant_id))
    workflow = result.scalar_one_or_none()
    
    if workflow:
        for key, value in update_data.model_dump().items():
            setattr(workflow, key, value)
    else:
        workflow = ApprovalWorkflow(**update_data.model_dump(), tenant_id=user.tenant_id)
        db.add(workflow)
    
    await db.commit()
    await db.refresh(workflow)
    return workflow

# ── Orders & Approvals ───────────────────────────────────────

@router.get("/orders", response_model=List[ApprovalRequestResponse])
async def list_pending_approvals(
    user: UserClaims = has_permissions(["b2b:approve"]),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(ApprovalRequest).where(
        ApprovalRequest.tenant_id == user.tenant_id,
        ApprovalRequest.status == 'pending'
    ))
    return result.scalars().all()

@router.patch("/orders/{id}/approve", response_model=ApprovalRequestResponse)
async def approve_b2b_order(
    id: str,
    user: UserClaims = has_permissions(["b2b:approve"]),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(ApprovalRequest).where(
        ApprovalRequest.tenant_id == user.tenant_id,
        ApprovalRequest.approval_request_id == id
    ))
    request = result.scalar_one_or_none()
    if not request:
        raise HTTPException(status_code=404, detail="Approval request not found.")
    
    request.status = 'approved'
    request.decided_by = user.uid
    request.decided_at = datetime.utcnow()
    
    # 1. Update order status
    order_res = await db.execute(select(Order).where(Order.order_id == request.order_id))
    order = order_res.scalar_one_or_none()
    if order:
        order.b2b_approval_status = 'approved'
        # Log Event
        event = OrderEvent(
            order_id=order.order_id,
            event_type="b2b_order_approved",
            description=f"Order approved by staff ({user.uid})."
        )
        db.add(event)

    # 2. Trigger Invoice Generation
    buyer_res = await db.execute(select(B2BAccount).where(B2BAccount.b2b_account_id == request.b2b_account_id))
    buyer = buyer_res.scalar_one_or_none()
    if buyer:
        due_date = datetime.utcnow() + timedelta(days=buyer.net_terms_days or 30)
        # In a real app, this would be a background task calling Stripe
        stripe_invoice = await stripe_mock.create_invoice(
            amount=int(request.order_grand_total * 100),
            currency=request.currency_code,
            customer_email=buyer.contact_email,
            due_date=due_date,
            metadata={"order_id": order.order_id}
        )
        
        new_invoice = B2BInvoice(
            tenant_id=request.tenant_id,
            order_id=order.order_id,
            stripe_invoice_id=stripe_invoice["id"],
            payment_status="open",
            due_date=due_date,
            invoice_amount=request.order_grand_total,
            currency_code=request.currency_code
        )
        db.add(new_invoice)

    await db.commit()
    await db.refresh(request)
    return request

@router.patch("/orders/{id}/decline", response_model=ApprovalRequestResponse)
async def decline_b2b_order(
    id: str,
    decline_reason: str,
    user: UserClaims = has_permissions(["b2b:approve"]),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(ApprovalRequest).where(
        ApprovalRequest.tenant_id == user.tenant_id,
        ApprovalRequest.approval_request_id == id
    ))
    request = result.scalar_one_or_none()
    if not request:
        raise HTTPException(status_code=404, detail="Approval request not found.")
    
    request.status = 'declined'
    request.decided_by = user.uid
    request.decided_at = datetime.utcnow()
    request.decline_reason = decline_reason
    
    # Update order status
    order_res = await db.execute(select(Order).where(Order.order_id == request.order_id))
    order = order_res.scalar_one_or_none()
    if order:
        order.b2b_approval_status = 'declined'
        # Log Event
        event = OrderEvent(
            order_id=order.order_id,
            event_type="b2b_order_declined",
            description=f"Order declined by staff ({user.uid}). Reason: {decline_reason}"
        )
        db.add(event)

    await db.commit()
    await db.refresh(request)
    return request

# ── B2B Portal (Buyer View) ──────────────────────────────────

@router.post("/portal/orders", response_model=ApprovalRequestResponse)
async def place_b2b_order(
    request: B2BPortalOrderRequest,
    background_tasks: BackgroundTasks,
    user: UserClaims = Depends(validate_token),
    db: AsyncSession = Depends(get_db)
):
    """
    B2B Buyer places an order.
    1. Validate Buyer Account
    2. Calculate Total based on Price List
    3. Check Thresholds & Credit Limit
    4. Create Order + ApprovalRequest
    """
    if user.account_type != "buyer":
        raise HTTPException(status_code=403, detail="Only B2B buyers can place portal orders.")

    # 1. Validate Buyer Account
    buyer_res = await db.execute(select(B2BAccount).where(B2BAccount.firebase_uid == user.uid))
    buyer = buyer_res.scalar_one_or_none()
    if not buyer or buyer.account_status != 'active':
        raise HTTPException(status_code=403, detail="Active B2B account required.")

    # 2. Calculate Total & Validate Items
    grand_total = Decimal("0.00")
    order_items_data = []
    
    # Get Price List items for overrides
    price_list_items = {}
    if buyer.price_list_id:
        pli_res = await db.execute(select(PriceListItem).where(PriceListItem.price_list_id == buyer.price_list_id))
        price_list_items = {item.variant_id: item for item in pli_res.scalars().all()}

    for item in request.items:
        v_res = await db.execute(select(Variant).where(Variant.variant_id == item.variant_id))
        variant = v_res.scalar_one_or_none()
        if not variant:
            raise HTTPException(status_code=404, detail=f"Variant {item.variant_id} not found")
        
        # Apply B2B pricing override
        price = variant.price
        if item.variant_id in price_list_items:
            override = price_list_items[item.variant_id]
            if override.override_type == 'fixed':
                price = override.override_price
            elif override.override_type == 'percentage':
                price = variant.price * (Decimal("1") - Decimal(str(override.override_discount_pct)) / Decimal("100"))
        
        item_total = price * item.quantity
        grand_total += item_total
        order_items_data.append({
            "variant": variant,
            "quantity": item.quantity,
            "unit_price": price,
            "total_price": item_total
        })

    # 3. Check Thresholds & Approval Logic
    workflow_res = await db.execute(select(ApprovalWorkflow).where(ApprovalWorkflow.tenant_id == buyer.tenant_id))
    workflow = workflow_res.scalar_one_or_none()
    
    needs_approval = False
    if workflow and workflow.is_enabled:
        if workflow.auto_approve_under is not None and grand_total > workflow.auto_approve_under:
            needs_approval = True
        
        if workflow.auto_approve_within_credit_limit:
            if buyer.credit_limit is not None and grand_total > buyer.credit_limit:
                needs_approval = True

    status = 'pending' if needs_approval else 'auto_approved'
    
    # 4. Create Order
    order_number = f"B2B-{uuid.uuid4().hex[:6].upper()}"
    new_order = Order(
        order_number=order_number,
        tenant_id=buyer.tenant_id,
        email=buyer.contact_email,
        b2b_account_id=buyer.b2b_account_id,
        b2b_approval_status=status,
        payment_status="pending",
        fulfilment_status="unfulfilled",
        currency="USD",
        subtotal=grand_total,
        tax_total=Decimal("0.00"),
        grand_total=grand_total,
        shipping_name=request.shipping_name,
        shipping_address1=request.shipping_address1,
        shipping_address2=request.shipping_address2,
        shipping_city=request.shipping_city,
        shipping_state=request.shipping_state,
        shipping_postcode=request.shipping_postcode,
        shipping_country=request.shipping_country
    )
    db.add(new_order)
    await db.flush()

    for data in order_items_data:
        v = data["variant"]
        oi = OrderItem(
            order_id=new_order.order_id,
            variant_id=v.variant_id,
            product_id=v.product_id,
            title=f"B2B: {v.sku}",
            sku=v.sku,
            quantity=data["quantity"],
            unit_price=data["unit_price"],
            total_price=data["total_price"],
            tax_amount=Decimal("0.00"),
            taxable=v.taxable,
            is_digital=False
        )
        db.add(oi)

    # 5. Create Approval Request
    approval_req = ApprovalRequest(
        tenant_id=buyer.tenant_id,
        order_id=new_order.order_id,
        b2b_account_id=buyer.b2b_account_id,
        order_grand_total=grand_total,
        currency_code="USD",
        status=status,
        requested_at=datetime.utcnow()
    )
    db.add(approval_req)
    
    if status == 'auto_approved':
        approval_req.decided_at = datetime.utcnow()
        approval_req.decided_by = "system"
        
        # Trigger Invoice Generation for Auto-Approved orders
        due_date = datetime.utcnow() + timedelta(days=buyer.net_terms_days or 30)
        stripe_invoice = await stripe_mock.create_invoice(
            amount=int(grand_total * 100),
            currency="USD",
            customer_email=buyer.contact_email,
            due_date=due_date,
            metadata={"order_id": new_order.order_id}
        )
        new_invoice = B2BInvoice(
            tenant_id=buyer.tenant_id,
            order_id=new_order.order_id,
            stripe_invoice_id=stripe_invoice["id"],
            payment_status="open",
            due_date=due_date,
            invoice_amount=grand_total,
            currency_code="USD"
        )
        db.add(new_invoice)
    else:
        # Send Notification to Staff
        approver_roles = workflow.approver_roles if workflow else ["owner", "admin"]
        background_tasks.add_task(
            send_b2b_approval_notification,
            buyer.tenant_id,
            new_order.order_id,
            float(grand_total),
            approver_roles
        )

    # Log Event
    event = OrderEvent(
        order_id=new_order.order_id,
        event_type="b2b_order_placed",
        description=f"B2B Order placed by {buyer.company_name}. Status: {status}"
    )
    db.add(event)
    
    await db.commit()
    await db.refresh(approval_req)
    return approval_req

@router.get("/portal/catalog", response_model=List[ProductResponse])
async def get_b2b_catalog(
    search: Optional[str] = None,
    user: UserClaims = Depends(validate_token),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns the product catalog scoped for the B2B buyer,
    including custom pricing from their assigned price list.
    """
    if user.account_type != "buyer":
        raise HTTPException(status_code=403, detail="Only B2B buyers can access the portal catalog.")

    # 1. Fetch Buyer Account
    buyer_res = await db.execute(select(B2BAccount).where(B2BAccount.firebase_uid == user.uid))
    buyer = buyer_res.scalar_one_or_none()
    if not buyer or buyer.account_status != 'active':
        raise HTTPException(status_code=403, detail="Active B2B account required.")

    # 2. Fetch Products
    query = select(Product).options(selectinload(Product.variants)).where(
        Product.tenant_id == buyer.tenant_id,
        Product.status == 'active'
    )
    
    if search:
        # Simple search for now (AI Search hook)
        query = query.where(Product.title.ilike(f"%{search}%"))
        
    prod_res = await db.execute(query)
    products = prod_res.scalars().all()

    # 3. Apply Price List Overrides
    if buyer.price_list_id:
        pli_res = await db.execute(select(PriceListItem).where(PriceListItem.price_list_id == buyer.price_list_id))
        overrides = {item.variant_id: item for item in pli_res.scalars().all()}
        
        for prod in products:
            for variant in prod.variants:
                if variant.variant_id in overrides:
                    ov = overrides[variant.variant_id]
                    if ov.override_type == 'fixed':
                        variant.price = ov.override_price
                    elif ov.override_type == 'percentage':
                        # Use local variable to avoid modifying the variant object in session 
                        # if we don't want to persist it, but since it's a response model, 
                        # we can modify it temporarily. 
                        # To be safe and avoid accidental DB updates on next flush:
                        # Variant objects are loaded from DB. 
                        # We'll just set the attribute.
                        variant.price = variant.price * (Decimal("1") - Decimal(str(ov.override_discount_pct)) / Decimal("100"))
    
    return products
