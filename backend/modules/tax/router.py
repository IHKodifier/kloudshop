from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from decimal import Decimal

from shared.db import get_db
from shared.auth import UserClaims, validate_token
from modules.platform.models import Tenant
from modules.catalog.models import Variant
from .models import StoreTaxRate
from .schemas import (
    TaxRateCreate, TaxRateResponse,
    TaxCalculateRequest, TaxCalculateResponse
)

router = APIRouter(tags=["Tax"])

# --- Tax Rates CRUD ---

@router.post("/rates", response_model=TaxRateResponse, status_code=status.HTTP_201_CREATED)
async def create_tax_rate(
    req: TaxRateCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="Tenant ID missing")

    # Check for duplicate rates for same country/state under this tenant
    dup_res = await db.execute(
        select(StoreTaxRate)
        .where(
            StoreTaxRate.tenant_id == user.tenant_id,
            StoreTaxRate.country_code == req.country_code.upper(),
            StoreTaxRate.state_code == (req.state_code.upper() if req.state_code else None)
        )
    )
    if dup_res.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Tax rate for this country/state already exists")

    rate = StoreTaxRate(
        tenant_id=user.tenant_id,
        country_code=req.country_code.upper(),
        state_code=req.state_code.upper() if req.state_code else None,
        tax_percentage=req.tax_percentage,
        is_active=req.is_active
    )
    db.add(rate)
    await db.commit()
    await db.refresh(rate)
    return rate

@router.get("/rates", response_model=List[TaxRateResponse])
async def list_tax_rates(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="Tenant ID missing")

    result = await db.execute(
        select(StoreTaxRate)
        .where(StoreTaxRate.tenant_id == user.tenant_id)
    )
    return result.scalars().all()

@router.delete("/rates/{tax_rate_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_tax_rate(
    tax_rate_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    result = await db.execute(
        select(StoreTaxRate)
        .where(StoreTaxRate.tax_rate_id == tax_rate_id, StoreTaxRate.tenant_id == user.tenant_id)
    )
    rate = result.scalar_one_or_none()
    if not rate:
        raise HTTPException(status_code=404, detail="Tax rate not found")
    
    await db.delete(rate)
    await db.commit()
    return None

# --- Checkout Tax Calculator ---

@router.post("/calculate", response_model=TaxCalculateResponse)
async def calculate_tax(
    req: TaxCalculateRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="Tenant ID missing")

    # 1. Fetch Tenant to check if Stripe Tax is enabled
    tenant_res = await db.execute(select(Tenant).where(Tenant.id == user.tenant_id))
    tenant = tenant_res.scalar_one_or_none()
    
    stripe_tax_enabled = False
    if tenant and tenant.config:
        stripe_tax_enabled = tenant.config.get("stripe_tax_enabled", False)

    # 2. Fetch Variant details to check taxable flag and price
    variant_ids = [item.variant_id for item in req.items]
    if not variant_ids:
        return TaxCalculateResponse(total_tax_amount=Decimal("0.0"), tax_rate_percentage=Decimal("0.0"), calculation_mode="manual_fallback")

    v_res = await db.execute(
        select(Variant).where(Variant.variant_id.in_(variant_ids), Variant.tenant_id == user.tenant_id)
    )
    variants = {v.variant_id: v for v in v_res.scalars().all()}

    # Calculate subtotal of taxable items
    taxable_subtotal = Decimal("0.0")
    for item in req.items:
        v = variants.get(item.variant_id)
        if not v:
            raise HTTPException(status_code=400, detail=f"Variant {item.variant_id} not found")
        if v.taxable:
            taxable_subtotal += v.price * item.quantity

    if stripe_tax_enabled:
        # Simulate Stripe Connect tax calculation
        # Let's say Stripe Tax is a simulated flat 8.5% for demo/test purposes
        tax_pct = Decimal("8.50")
        tax_amt = (taxable_subtotal * tax_pct / Decimal("100.0")).quantize(Decimal("0.01"))
        return TaxCalculateResponse(
            total_tax_amount=tax_amt,
            tax_rate_percentage=tax_pct,
            calculation_mode="stripe_automated"
        )
    else:
        # Query manual StoreTaxRate fallback
        target_country = req.country_code.strip().upper()
        target_state = req.state_code.strip().upper() if req.state_code else None

        # Try to find a state-specific rate first
        rate_query = select(StoreTaxRate).where(
            StoreTaxRate.tenant_id == user.tenant_id,
            StoreTaxRate.country_code == target_country,
            StoreTaxRate.is_active == True
        )
        
        rates_res = await db.execute(rate_query)
        rates = rates_res.scalars().all()
        
        matched_rate = None
        if target_state:
            # Match state-specific
            matched_rate = next((r for r in rates if r.state_code and r.state_code.upper() == target_state), None)
        
        # Fallback to country-only (no state code)
        if not matched_rate:
            matched_rate = next((r for r in rates if not r.state_code), None)

        tax_pct = matched_rate.tax_percentage if matched_rate else Decimal("0.0")
        tax_amt = (taxable_subtotal * tax_pct / Decimal("100.0")).quantize(Decimal("0.01"))
        
        return TaxCalculateResponse(
            total_tax_amount=tax_amt,
            tax_rate_percentage=tax_pct,
            calculation_mode="manual_fallback"
        )
