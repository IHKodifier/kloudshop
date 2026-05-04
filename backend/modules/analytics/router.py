from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from shared.db import get_db
from shared.auth import UserClaims, validate_token
from modules.orders.models import Order
from modules.inventory.models import Inventory, StockLocation
from modules.b2b.models import B2BAccount
from datetime import datetime, timedelta
from typing import Dict, Any, List

router = APIRouter(tags=["Analytics"])

@router.get("/overview")
async def get_revenue_overview(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    """
    Get real-time revenue KPIs:
    - GMV (Gross Merchandise Value)
    - Order Count
    - AOV (Average Order Value)
    - Conversion Rate (Placeholder for MVP)
    """
    # GMV & Order Count (Total for the tenant)
    result = await db.execute(
        select(
            func.sum(Order.grand_total).label("gmv"),
            func.count(Order.order_id).label("order_count")
        ).where(Order.tenant_id == user.tenant_id)
    )
    stats = result.one()
    
    gmv = float(stats.gmv or 0)
    order_count = stats.order_count or 0
    aov = gmv / order_count if order_count > 0 else 0
    
    return {
        "gmv": round(gmv, 2),
        "order_count": order_count,
        "aov": round(aov, 2),
        "conversion_rate": 0.035, # Mock: 3.5%
        "currency": "USD",
        "refreshed_at": datetime.utcnow()
    }

@router.get("/needs-attention")
async def get_needs_attention(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    """
    Operational alerts:
    - Pending Orders (> 24h)
    - Low Stock Items (quantity <= reorder_point)
    - B2B Approvals (Pending)
    """
    # 1. Pending Orders > 24h
    day_ago = datetime.utcnow() - timedelta(hours=24)
    pending_orders_result = await db.execute(
        select(func.count(Order.order_id)).where(
            Order.tenant_id == user.tenant_id,
            Order.fulfilment_status == "unfulfilled",
            Order.placed_at < day_ago
        )
    )
    pending_orders_count = pending_orders_result.scalar() or 0
    
    # 2. Low Stock Items
    # Join Inventory with StockLocation to filter by tenant if needed (assuming Inventory table is tenant-scoped via Variant)
    # Actually, Inventory doesn't have tenant_id, but Variant does.
    from modules.catalog.models import Variant
    low_stock_result = await db.execute(
        select(func.count(Inventory.inventory_id)).join(Variant).where(
            Variant.tenant_id == user.tenant_id,
            Inventory.quantity_on_hand <= Inventory.reorder_point
        )
    )
    low_stock_count = low_stock_result.scalar() or 0
    
    # 3. Pending B2B Approvals
    b2b_approvals_result = await db.execute(
        select(func.count(B2BAccount.b2b_account_id)).where(
            B2BAccount.tenant_id == user.tenant_id,
            B2BAccount.account_status == "pending_approval"
        )
    )
    pending_b2b_approvals = b2b_approvals_result.scalar() or 0
    
    return {
        "pending_orders_overdue": pending_orders_count,
        "low_stock_variants": low_stock_count,
        "pending_b2b_approvals": pending_b2b_approvals,
        "total_alerts": pending_orders_count + low_stock_count + pending_b2b_approvals
    }

@router.get("/forecasting")
async def get_forecasting(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    """Vertex AI Demand Forecasting Stub."""
    return {
        "provider": "Vertex AI",
        "model": "demand-forecaster-v1",
        "disclaimer": "Insufficient data for accurate forecasting. Requires >90 days of history and 100+ orders.",
        "forecast_period": "30-day-next",
        "recommendations": [
            {"sku": "SKU-PROD-A", "predicted_demand": 50, "confidence": 0.45},
            {"sku": "SKU-PROD-B", "predicted_demand": 120, "confidence": 0.38}
        ]
    }

@router.get("/looker/token")
async def get_looker_token(
    user: UserClaims = Depends(validate_token)
):
    """Scoped BigQuery/Looker Studio embed token generator."""
    # In a real implementation, this would call Google Cloud STS or a custom signer
    return {
        "embed_url": f"https://lookerstudio.google.com/embed/reporting/123-abc?tenant={user.tenant_id}",
        "access_token": "mock_bigquery_scoped_token_123",
        "expires_in": 3600
    }
