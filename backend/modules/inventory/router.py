from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func
from sqlalchemy.orm import selectinload
from typing import List
from datetime import datetime, timezone

from shared.db import get_db
from shared.auth import UserClaims
from shared.rbac import has_permissions
from .models import (
    Supplier, PurchaseOrder, PurchaseOrderLine, 
    StockLocation, Inventory, StockTransfer
)
from .schemas import (
    SupplierCreate, SupplierUpdate, SupplierResponse,
    POCreate, POResponse, POUpdate, POReceiveRequest,
    StockTransferCreate, StockTransferResponse
)

router = APIRouter(tags=["Inventory"])

# --- Suppliers ---

@router.post("/suppliers", response_model=SupplierResponse)
async def create_supplier(
    supplier_in: SupplierCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["supplier:write"])
):
    supplier = Supplier(
        **supplier_in.model_dump(),
        tenant_id=user.tenant_id,
        created_by=user.uid
    )
    db.add(supplier)
    await db.commit()
    await db.refresh(supplier)
    return supplier

@router.get("/suppliers", response_model=List[SupplierResponse])
async def list_suppliers(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["supplier:read"])
):
    result = await db.execute(
        select(Supplier).where(Supplier.tenant_id == user.tenant_id)
    )
    return result.scalars().all()

@router.get("/suppliers/{supplier_id}", response_model=SupplierResponse)
async def get_supplier(
    supplier_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["supplier:read"])
):
    result = await db.execute(
        select(Supplier).where(
            Supplier.supplier_id == supplier_id,
            Supplier.tenant_id == user.tenant_id
        )
    )
    supplier = result.scalar_one_or_none()
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    return supplier

@router.patch("/suppliers/{supplier_id}", response_model=SupplierResponse)
async def update_supplier(
    supplier_id: str,
    supplier_in: SupplierUpdate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["supplier:write"])
):
    result = await db.execute(
        select(Supplier).where(
            Supplier.supplier_id == supplier_id,
            Supplier.tenant_id == user.tenant_id
        )
    )
    supplier = result.scalar_one_or_none()
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    
    for field, value in supplier_in.model_dump(exclude_unset=True).items():
        setattr(supplier, field, value)
    
    await db.commit()
    await db.refresh(supplier)
    return supplier

@router.delete("/suppliers/{supplier_id}")
async def delete_supplier(
    supplier_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["supplier:write"])
):
    # Check if POs exist (Blocked by DB RESTRICT, but nice to handle gracefully)
    po_check = await db.execute(
        select(func.count(PurchaseOrder.po_id)).where(PurchaseOrder.supplier_id == supplier_id)
    )
    if po_check.scalar() > 0:
        raise HTTPException(status_code=400, detail="Cannot delete supplier with existing purchase orders. Archive it instead.")
    
    result = await db.execute(
        delete(Supplier).where(
            Supplier.supplier_id == supplier_id,
            Supplier.tenant_id == user.tenant_id
        )
    )
    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Supplier not found")
    
    await db.commit()
    return {"message": "Supplier deleted successfully"}

# --- Purchase Orders ---

@router.post("/purchase-orders", response_model=POResponse)
async def create_purchase_order(
    po_in: POCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["po:write"])
):
    # Generate PO number (PO-XXXX)
    count_result = await db.execute(
        select(func.count(PurchaseOrder.po_id)).where(PurchaseOrder.tenant_id == user.tenant_id)
    )
    po_number = f"PO-{1000 + count_result.scalar() + 1}"
    
    po = PurchaseOrder(
        po_number=po_number,
        tenant_id=user.tenant_id,
        supplier_id=po_in.supplier_id,
        receiving_location_id=po_in.receiving_location_id,
        notes=po_in.notes,
        created_by=user.uid,
        status="draft"
    )
    db.add(po)
    await db.flush() # Get po_id
    
    total_cost = 0
    for line_in in po_in.lines:
        line = PurchaseOrderLine(
            po_id=po.po_id,
            variant_id=line_in.variant_id,
            quantity_ordered=line_in.quantity_ordered,
            unit_cost=line_in.unit_cost,
            unit_cost_currency=line_in.unit_cost_currency
        )
        db.add(line)
        if line_in.unit_cost:
            total_cost += line_in.unit_cost * line_in.quantity_ordered
    
    po.total_cost = total_cost
    # Fetch currency from supplier
    supplier_result = await db.execute(select(Supplier.currency).where(Supplier.supplier_id == po_in.supplier_id))
    po.total_cost_currency = supplier_result.scalar()
    
    await db.commit()
    
    # Return with lines loaded
    result = await db.execute(
        select(PurchaseOrder)
        .where(PurchaseOrder.po_id == po.po_id)
        .options(selectinload(PurchaseOrder.lines))
    )
    return result.scalar_one()

@router.get("/purchase-orders", response_model=List[POResponse])
async def list_purchase_orders(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["po:read"])
):
    result = await db.execute(
        select(PurchaseOrder)
        .where(PurchaseOrder.tenant_id == user.tenant_id)
        .options(selectinload(PurchaseOrder.lines))
        .order_by(PurchaseOrder.created_at.desc())
    )
    return result.scalars().all()

@router.get("/purchase-orders/{po_id}", response_model=POResponse)
async def get_purchase_order(
    po_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["po:read"])
):
    result = await db.execute(
        select(PurchaseOrder)
        .where(PurchaseOrder.po_id == po_id, PurchaseOrder.tenant_id == user.tenant_id)
        .options(selectinload(PurchaseOrder.lines))
    )
    po = result.scalar_one_or_none()
    if not po:
        raise HTTPException(status_code=404, detail="Purchase order not found")
    return po

@router.patch("/purchase-orders/{po_id}/send", response_model=POResponse)
async def send_purchase_order(
    po_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["po:write"])
):
    result = await db.execute(
        select(PurchaseOrder)
        .where(PurchaseOrder.po_id == po_id, PurchaseOrder.tenant_id == user.tenant_id)
        .options(selectinload(PurchaseOrder.lines))
    )
    po = result.scalar_one_or_none()
    if not po:
        raise HTTPException(status_code=404, detail="Purchase order not found")
    
    if po.status != "draft":
        raise HTTPException(status_code=400, detail=f"Cannot send PO in {po.status} status")
    
    if not po.receiving_location_id:
        raise HTTPException(status_code=400, detail="Receiving location must be set before sending")
    
    po.status = "sent"
    po.ordered_at = datetime.now(timezone.utc)
    po.sent_by = user.uid
    
    await db.commit()
    await db.refresh(po)
    return po

@router.post("/purchase-orders/{po_id}/receive", response_model=POResponse)
async def receive_purchase_order(
    po_id: str,
    receive_in: POReceiveRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["po:write"])
):
    # Atomic inventory update
    result = await db.execute(
        select(PurchaseOrder)
        .where(PurchaseOrder.po_id == po_id, PurchaseOrder.tenant_id == user.tenant_id)
        .options(selectinload(PurchaseOrder.lines))
        .with_for_update() # Lock the PO
    )
    po = result.scalar_one_or_none()
    if not po:
        raise HTTPException(status_code=404, detail="Purchase order not found")
    
    if po.status not in ["sent", "acknowledged", "partial"]:
        raise HTTPException(status_code=400, detail=f"Cannot receive items for PO in {po.status} status")
    
    # Process line receipts
    lines_received = 0
    all_fully_received = True
    
    for receive_line in receive_in.lines:
        # Find matching line
        po_line = next((l for l in po.lines if l.po_line_id == receive_line.po_line_id), None)
        if not po_line:
            continue
        
        # Update line receipt
        old_received = po_line.quantity_received or 0
        new_received = receive_line.quantity_received
        diff = new_received # We assume the request provides the *newly* received amount for this batch
        
        po_line.quantity_received = old_received + diff
        po_line.received_at = datetime.now(timezone.utc)
        po_line.manufacture_date = receive_line.manufacture_date
        
        if po_line.quantity_received != po_line.quantity_ordered:
            po_line.discrepancy_flag = True
            po_line.discrepancy_notes = receive_line.discrepancy_notes
            if po_line.quantity_received < po_line.quantity_ordered:
                all_fully_received = False
        
        # Update Inventory
        # Try to find existing inventory record
        inv_result = await db.execute(
            select(Inventory).where(
                Inventory.variant_id == po_line.variant_id,
                Inventory.stock_location_id == po.receiving_location_id
            ).with_for_update()
        )
        inventory = inv_result.scalar_one_or_none()
        
        if not inventory:
            # Create new inventory record
            inventory = Inventory(
                tenant_id=user.tenant_id,
                variant_id=po_line.variant_id,
                stock_location_id=po.receiving_location_id,
                quantity_on_hand=diff,
                last_received_at=datetime.now(timezone.utc)
            )
            db.add(inventory)
        else:
            inventory.quantity_on_hand += diff
            inventory.last_received_at = datetime.now(timezone.utc)
        
        lines_received += 1
    
    if all_fully_received:
        po.status = "received"
        po.received_at = datetime.now(timezone.utc)
    else:
        po.status = "partial"
    
    await db.commit()
    
    # Refresh and return
    result = await db.execute(
        select(PurchaseOrder)
        .where(PurchaseOrder.po_id == po.po_id)
        .options(selectinload(PurchaseOrder.lines))
    )
    return result.scalar_one()

# --- Stock Transfers ---

@router.post("/transfers", response_model=StockTransferResponse)
async def create_stock_transfer(
    transfer_in: StockTransferCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["inventory:write"])
):
    if transfer_in.source_location_id == transfer_in.destination_location_id:
        raise HTTPException(status_code=400, detail="Source and destination locations must be different")
    
    # Check source stock
    source_inv_result = await db.execute(
        select(Inventory).where(
            Inventory.variant_id == transfer_in.variant_id,
            Inventory.stock_location_id == transfer_in.source_location_id
        ).with_for_update()
    )
    source_inv = source_inv_result.scalar_one_or_none()
    
    if not source_inv or source_inv.quantity_on_hand < transfer_in.quantity_transferred:
        raise HTTPException(status_code=400, detail="Insufficient stock at source location")
    
    # Immediate decrement for simplicity (or move to 'in_transit' status)
    source_inv.quantity_on_hand -= transfer_in.quantity_transferred
    
    transfer = StockTransfer(
        tenant_id=user.tenant_id,
        source_location_id=transfer_in.source_location_id,
        destination_location_id=transfer_in.destination_location_id,
        variant_id=transfer_in.variant_id,
        quantity_transferred=transfer_in.quantity_transferred,
        status="in_transit",
        initiated_by=user.uid,
        initiated_at=datetime.now(timezone.utc),
        notes=transfer_in.notes
    )
    db.add(transfer)
    await db.commit()
    await db.refresh(transfer)
    return transfer

@router.post("/transfers/{transfer_id}/receive", response_model=StockTransferResponse)
async def receive_stock_transfer(
    transfer_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["inventory:write"])
):
    result = await db.execute(
        select(StockTransfer).where(
            StockTransfer.transfer_id == transfer_id,
            StockTransfer.tenant_id == user.tenant_id
        ).with_for_update()
    )
    transfer = result.scalar_one_or_none()
    if not transfer:
        raise HTTPException(status_code=404, detail="Transfer not found")
    
    if transfer.status != "in_transit":
        raise HTTPException(status_code=400, detail=f"Cannot receive transfer in {transfer.status} status")
    
    # Update destination stock
    dest_inv_result = await db.execute(
        select(Inventory).where(
            Inventory.variant_id == transfer.variant_id,
            Inventory.stock_location_id == transfer.destination_location_id
        ).with_for_update()
    )
    dest_inv = dest_inv_result.scalar_one_or_none()
    
    if not dest_inv:
        dest_inv = Inventory(
            tenant_id=user.tenant_id,
            variant_id=transfer.variant_id,
            stock_location_id=transfer.destination_location_id,
            quantity_on_hand=transfer.quantity_transferred,
            last_received_at=datetime.now(timezone.utc)
        )
        db.add(dest_inv)
    else:
        dest_inv.quantity_on_hand += transfer.quantity_transferred
        dest_inv.last_received_at = datetime.now(timezone.utc)
    
    transfer.status = "received"
    transfer.received_by = user.uid
    transfer.received_at = datetime.now(timezone.utc)
    transfer.quantity_received = transfer.quantity_transferred
    
    await db.commit()
    await db.refresh(transfer)
    return transfer

# --- AI Replenishment & Dashboards ---

@router.get("/replenishment/recommendations")
async def get_replenishment_recommendations(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["inventory:read"])
):
    # Join Inventory with Variant
    result = await db.execute(
        select(Inventory)
        .where(Inventory.quantity_on_hand <= Inventory.reorder_point)
        .options(selectinload(Inventory.variant))
    )
    items = result.scalars().all()
    
    recommendations = []
    for item in items:
        # Simple rule-based recommendation
        rec_qty = item.reorder_quantity or 10
        urgency = "medium"
        if item.quantity_on_hand == 0:
            urgency = "high"
        elif item.reorder_point and item.quantity_on_hand < (item.reorder_point * 0.5):
            urgency = "high"
            
        recommendations.append({
            "variant_id": item.variant_id,
            "sku": item.variant.sku if item.variant else "N/A",
            "current_stock": item.quantity_on_hand,
            "reorder_point": item.reorder_point,
            "recommended_quantity": rec_qty,
            "urgency": urgency,
            "reason": "Stock below reorder point"
        })
        
    return recommendations
