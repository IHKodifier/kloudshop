from decimal import Decimal
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from modules.shipping.models import StoreShippingProfile, StoreShippingZone, StoreShippingRate
from modules.catalog.models import Product, Variant

@pytest.mark.asyncio
async def test_shipping_calculation_blending_success(client: AsyncClient, mock_firebase_user, db_session: AsyncSession):
    headers = {"Authorization": "Bearer valid_token"}

    # 1. Seed general profile
    gen_profile = StoreShippingProfile(
        tenant_id="t_abc",
        name="General Profile",
        is_general=True
    )
    db_session.add(gen_profile)
    await db_session.commit()
    await db_session.refresh(gen_profile)

    # 2. Seed custom profile
    heavy_profile = StoreShippingProfile(
        tenant_id="t_abc",
        name="Heavy Furniture Profile",
        is_general=False
    )
    db_session.add(heavy_profile)
    await db_session.commit()
    await db_session.refresh(heavy_profile)

    # 3. Seed zones
    gen_zone = StoreShippingZone(
        profile_id=gen_profile.profile_id,
        tenant_id="t_abc",
        name="General US Zone",
        countries=["US"]
    )
    db_session.add(gen_zone)
    
    heavy_zone = StoreShippingZone(
        profile_id=heavy_profile.profile_id,
        tenant_id="t_abc",
        name="Heavy US Zone",
        countries=["US"]
    )
    db_session.add(heavy_zone)
    await db_session.commit()
    await db_session.refresh(gen_zone)
    await db_session.refresh(heavy_zone)

    # 4. Seed rates
    # General: $5 flat rate, or $0 (free) for orders > $100
    r1 = StoreShippingRate(
        zone_id=gen_zone.zone_id,
        tenant_id="t_abc",
        name="Standard Light Shipping",
        price=Decimal("5.00"),
        rate_type="flat"
    )
    db_session.add(r1)
    
    # Heavy: $50 standard weight-based rate
    r2 = StoreShippingRate(
        zone_id=heavy_zone.zone_id,
        tenant_id="t_abc",
        name="Heavy Freight Shipping",
        price=Decimal("50.00"),
        rate_type="flat"
    )
    db_session.add(r2)
    await db_session.commit()

    # 5. Create products & variants
    p1 = Product(tenant_id="t_abc", title="T-Shirt", slug="t-shirt", created_by="staff_1")
    db_session.add(p1)
    await db_session.commit()
    await db_session.refresh(p1)

    v1 = Variant(
        product_id=p1.product_id,
        tenant_id="t_abc",
        sku="TSHIRT-S",
        price=Decimal("20.00"),
        weight_value=Decimal("0.5"),
        weight_unit="kg",
        requires_shipping=True,
        taxable=True,
        shipping_profile_id=gen_profile.profile_id
    )
    db_session.add(v1)

    v2 = Variant(
        product_id=p1.product_id,
        tenant_id="t_abc",
        sku="HEAVY-SOFA",
        price=Decimal("500.00"),
        weight_value=Decimal("50.0"),
        weight_unit="kg",
        requires_shipping=True,
        taxable=True,
        shipping_profile_id=heavy_profile.profile_id
    )
    db_session.add(v2)
    await db_session.commit()
    await db_session.refresh(v1)
    await db_session.refresh(v2)

    # 6. Calculate shipping
    payload = {
        "country_code": "US",
        "items": [
            {"variant_id": v1.variant_id, "quantity": 2}, # Gen profile, total cost = $40, weight = 1.0kg -> matches $5 rate
            {"variant_id": v2.variant_id, "quantity": 1}  # Heavy profile, total cost = $500, weight = 50kg -> matches $50 rate
        ]
    }
    
    response = await client.post("/api/v1/shipping/calculate", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert Decimal(str(data["total_shipping_price"])) == Decimal("55.00")
    assert len(data["rates"]) == 2
    
    rate_names = [r["rate_name"] for r in data["rates"]]
    assert "Standard Light Shipping" in rate_names
    assert "Heavy Freight Shipping" in rate_names
