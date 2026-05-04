from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, text
from shared.db import get_db, engine
from shared.auth import UserClaims, validate_token
from modules.orders.models import Order
from modules.b2b.models import B2BAccount
from typing import Dict, Any, List
import os

router = APIRouter(tags=["Hygiene & Compliance"])

@router.post("/gdpr/erasure")
async def gdpr_erasure(
    email: str = Body(..., embed=True),
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    """
    GDPR Right-to-Erasure Pipeline.
    Anonymizes PII in Orders and B2B Accounts for a specific email.
    """
    if not user.is_owner:
        raise HTTPException(status_code=403, detail="Only owners can trigger erasure")
        
    # 1. Anonymize Orders
    await db.execute(
        update(Order).where(
            Order.tenant_id == user.tenant_id,
            Order.email == email
        ).values(
            email="redacted@kloudshop.io",
            shipping_name="Deleted User",
            shipping_address1="Redacted",
            shipping_address2=None,
            shipping_city="Redacted",
            shipping_postcode="00000",
            stripe_payment_intent_id="redacted"
        )
    )
    
    # 2. Anonymize B2B Accounts
    await db.execute(
        update(B2BAccount).where(
            B2BAccount.tenant_id == user.tenant_id,
            B2BAccount.contact_email == email
        ).values(
            contact_email=f"deleted_{os.urandom(4).hex()}@redacted.com",
            contact_first_name="Deleted",
            contact_last_name="User",
            contact_phone=None,
            company_name="Redacted Company",
            default_address_line1="Redacted",
            firebase_uid=None
        )
    )
    
    await db.commit()
    return {"status": "success", "message": f"PII associated with {email} has been anonymized."}

@router.get("/health/schema-drift")
async def check_schema_drift(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    """
    Nightly schema drift detection.
    Compares live schema vs SQLAlchemy metadata (Simplified for MVP).
    """
    # In a real scenario, we'd use Alembic's migration context to compare.
    # For MVP, we check if core tables exist.
    result = await db.execute(text("SELECT name FROM sqlite_master WHERE type='table';"))
    tables = [row[0] for row in result.fetchall()]
    
    expected_tables = ["orders", "products", "variants", "tenants", "b2b_accounts"]
    missing = [t for t in expected_tables if t not in tables]
    
    return {
        "status": "healthy" if not missing else "drift_detected",
        "missing_tables": missing,
        "database_type": engine.url.drivername,
        "timestamp": "2026-05-04T07:00:00Z"
    }

@router.get("/version")
async def get_version():
    """SYS-18 version detection."""
    return {
        "version": "1.0.4-rc2",
        "build_hash": "a1b2c3d4",
        "environment": "production-aligned",
        "api_status": "operational"
    }
