from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from typing import List
from decimal import Decimal

from shared.db import get_db
from shared.auth import UserClaims, validate_token
from shared.rbac import has_permissions
from modules.catalog.models import Variant, Product
from .models import StoreShippingProfile, StoreShippingZone, StoreShippingRate
from .schemas import (
    ShippingProfileCreate, ShippingProfileResponse,
    ShippingZoneCreate, ShippingZoneResponse,
    ShippingRateCreate, ShippingRateResponse,
    ShippingCalculateRequest, ShippingCalculateResponse, BlendedRateDetail
)

router = APIRouter(tags=["Shipping"])

# --- Profiles CRUD ---

@router.post("/profiles", response_model=ShippingProfileResponse, status_code=status.HTTP_201_CREATED)
async def create_profile(
    req: ShippingProfileCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="Tenant ID missing")

    # If is_general is True, make sure we deactivate any other general profiles
    if req.is_general:
        existing_general = await db.execute(
            select(StoreShippingProfile)
            .where(StoreShippingProfile.tenant_id == user.tenant_id, StoreShippingProfile.is_general == True)
        )
        for p in existing_general.scalars().all():
            p.is_general = False

    profile = StoreShippingProfile(
        tenant_id=user.tenant_id,
        name=req.name,
        is_general=req.is_general
    )
    db.add(profile)
    await db.commit()
    await db.refresh(profile)
    return profile

@router.get("/profiles", response_model=List[ShippingProfileResponse])
async def list_profiles(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="Tenant ID missing")

    result = await db.execute(
        select(StoreShippingProfile)
        .where(StoreShippingProfile.tenant_id == user.tenant_id)
        .options(selectinload(StoreShippingProfile.zones).selectinload(StoreShippingZone.rates))
    )
    return result.scalars().all()

@router.get("/profiles/{profile_id}", response_model=ShippingProfileResponse)
async def get_profile(
    profile_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    result = await db.execute(
        select(StoreShippingProfile)
        .where(StoreShippingProfile.profile_id == profile_id, StoreShippingProfile.tenant_id == user.tenant_id)
        .options(selectinload(StoreShippingProfile.zones).selectinload(StoreShippingZone.rates))
    )
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Shipping profile not found")
    return profile

@router.delete("/profiles/{profile_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_profile(
    profile_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    result = await db.execute(
        select(StoreShippingProfile)
        .where(StoreShippingProfile.profile_id == profile_id, StoreShippingProfile.tenant_id == user.tenant_id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Shipping profile not found")
    
    await db.delete(profile)
    await db.commit()
    return None

# --- Zones CRUD ---

@router.post("/profiles/{profile_id}/zones", response_model=ShippingZoneResponse, status_code=status.HTTP_201_CREATED)
async def create_zone(
    profile_id: str,
    req: ShippingZoneCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    # Verify profile exists
    prof_res = await db.execute(
        select(StoreShippingProfile).where(StoreShippingProfile.profile_id == profile_id, StoreShippingProfile.tenant_id == user.tenant_id)
    )
    if not prof_res.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Shipping profile not found")

    zone = StoreShippingZone(
        profile_id=profile_id,
        tenant_id=user.tenant_id,
        name=req.name,
        countries=[c.upper() for c in req.countries]
    )
    db.add(zone)
    await db.commit()
    await db.refresh(zone)
    return zone

@router.delete("/zones/{zone_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_zone(
    zone_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    result = await db.execute(
        select(StoreShippingZone).where(StoreShippingZone.zone_id == zone_id, StoreShippingZone.tenant_id == user.tenant_id)
    )
    zone = result.scalar_one_or_none()
    if not zone:
        raise HTTPException(status_code=404, detail="Shipping zone not found")
    
    await db.delete(zone)
    await db.commit()
    return None

# --- Rates CRUD ---

@router.post("/zones/{zone_id}/rates", response_model=ShippingRateResponse, status_code=status.HTTP_201_CREATED)
async def create_rate(
    zone_id: str,
    req: ShippingRateCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    # Verify zone exists
    zone_res = await db.execute(
        select(StoreShippingZone).where(StoreShippingZone.zone_id == zone_id, StoreShippingZone.tenant_id == user.tenant_id)
    )
    if not zone_res.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Shipping zone not found")

    rate = StoreShippingRate(
        zone_id=zone_id,
        tenant_id=user.tenant_id,
        name=req.name,
        price=req.price,
        min_value=req.min_value,
        max_value=req.max_value,
        min_weight=req.min_weight,
        max_weight=req.max_weight,
        rate_type=req.rate_type
    )
    db.add(rate)
    await db.commit()
    await db.refresh(rate)
    return rate

@router.delete("/rates/{rate_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_rate(
    rate_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    result = await db.execute(
        select(StoreShippingRate).where(StoreShippingRate.rate_id == rate_id, StoreShippingRate.tenant_id == user.tenant_id)
    )
    rate = result.scalar_one_or_none()
    if not rate:
        raise HTTPException(status_code=404, detail="Shipping rate not found")
    
    await db.delete(rate)
    await db.commit()
    return None

# --- Rate Blending Checkout Calculator ---

@router.post("/calculate", response_model=ShippingCalculateResponse)
async def calculate_shipping(
    req: ShippingCalculateRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="Tenant ID missing")

    # 1. Fetch Variant & Product details for checkout items
    variant_ids = [item.variant_id for item in req.items]
    if not variant_ids:
        return ShippingCalculateResponse(total_shipping_price=Decimal("0.0"), rates=[])

    result = await db.execute(
        select(Variant)
        .where(Variant.variant_id.in_(variant_ids), Variant.tenant_id == user.tenant_id)
        .options(selectinload(Variant.product))
    )
    variants = {v.variant_id: v for v in result.scalars().all()}

    # 2. Get the default general profile for fallback
    gen_profile_res = await db.execute(
        select(StoreShippingProfile)
        .where(StoreShippingProfile.tenant_id == user.tenant_id, StoreShippingProfile.is_general == True)
    )
    general_profile = gen_profile_res.scalar_one_or_none()
    general_profile_id = general_profile.profile_id if general_profile else None

    # Group cart items by shipping profile ID
    profile_groups = {}
    for item in req.items:
        v = variants.get(item.variant_id)
        if not v:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Variant {item.variant_id} not found")
        
        # If it doesn't require shipping (e.g. digital goods), skip it
        if not v.requires_shipping:
            continue

        # Get shipping profile ID
        prof_id = v.shipping_profile_id or general_profile_id
        if not prof_id:
            # Fallback if no general profile is seeded: just use a dummy key or raise error
            raise HTTPException(status_code=500, detail="Store shipping configuration is incomplete (missing general profile)")

        # Calculate weight and price
        # Weight fallback: variant weight -> product weight -> 0.0
        weight_val = v.weight_value
        if weight_val is None and v.product:
            weight_val = v.product.weight_value
        weight = Decimal(str(weight_val or 0.0)) * item.quantity
        price = v.price * item.quantity

        if prof_id not in profile_groups:
            profile_groups[prof_id] = {"weight": Decimal("0.0"), "price": Decimal("0.0"), "items_count": 0}
        
        profile_groups[prof_id]["weight"] += weight
        profile_groups[prof_id]["price"] += price
        profile_groups[prof_id]["items_count"] += item.quantity

    if not profile_groups:
        return ShippingCalculateResponse(total_shipping_price=Decimal("0.0"), rates=[])

    # 3. Process each profile group
    blended_rates = []
    total_price = Decimal("0.0")

    for prof_id, metrics in profile_groups.items():
        # Fetch profile with zones and rates
        prof_res = await db.execute(
            select(StoreShippingProfile)
            .where(StoreShippingProfile.profile_id == prof_id, StoreShippingProfile.tenant_id == user.tenant_id)
            .options(selectinload(StoreShippingProfile.zones).selectinload(StoreShippingZone.rates))
        )
        profile = prof_res.scalar_one_or_none()
        if not profile:
            raise HTTPException(status_code=400, detail=f"Shipping profile {prof_id} not found")

        # Find matching zone by country code
        matched_zone = None
        target_country = req.country_code.strip().upper()
        for zone in profile.zones:
            if target_country in [c.upper() for c in zone.countries]:
                matched_zone = zone
                break

        if not matched_zone:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"No shipping rates available for country {target_country} under profile '{profile.name}'"
            )

        # Filter rates in this zone based on thresholds
        matching_rates = []
        for rate in matched_zone.rates:
            matches = True
            
            if rate.rate_type == "weight_based":
                if rate.min_weight is not None and metrics["weight"] < rate.min_weight:
                    matches = False
                if rate.max_weight is not None and metrics["weight"] > rate.max_weight:
                    matches = False
            elif rate.rate_type == "price_based":
                if rate.min_value is not None and metrics["price"] < rate.min_value:
                    matches = False
                if rate.max_value is not None and metrics["price"] > rate.max_value:
                    matches = False
            
            if matches:
                matching_rates.append(rate)

        if not matching_rates:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"No matching shipping rates found for the cart value/weight in zone '{matched_zone.name}'"
            )

        # Select the cheapest matched rate
        selected_rate = min(matching_rates, key=lambda r: r.price)
        
        blended_rates.append(BlendedRateDetail(
            profile_name=profile.name,
            rate_name=selected_rate.name,
            price=selected_rate.price
        ))
        total_price += selected_rate.price

    return ShippingCalculateResponse(
        total_shipping_price=total_price,
        rates=blended_rates
    )
