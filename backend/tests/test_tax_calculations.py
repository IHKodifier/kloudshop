from decimal import Decimal
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from modules.platform.models import Tenant
from modules.tax.models import StoreTaxRate
from modules.catalog.models import Product, Variant

@pytest.mark.asyncio
async def test_tax_calculation_manual_fallback(client: AsyncClient, mock_firebase_user, db_session: AsyncSession):
    headers = {"Authorization": "Bearer valid_token"}

    # 1. Update tenant to disable stripe_tax_enabled (default is False/missing)
    tenant_res = await db_session.execute(select(Tenant).where(Tenant.id == "t_abc"))
    tenant = tenant_res.scalar_one_or_none()
    if not tenant:
        tenant = Tenant(id="t_abc", name="Acme", config={"stripe_tax_enabled": False})
        db_session.add(tenant)
    else:
        cfg = dict(tenant.config or {})
        cfg["stripe_tax_enabled"] = False
        tenant.config = cfg
    await db_session.commit()

    # 2. Seed manual tax rate (e.g. US, state CA = 8%, US general = 5%)
    r1 = StoreTaxRate(tenant_id="t_abc", country_code="US", state_code="CA", tax_percentage=Decimal("8.00"), is_active=True)
    r2 = StoreTaxRate(tenant_id="t_abc", country_code="US", state_code=None, tax_percentage=Decimal("5.00"), is_active=True)
    db_session.add_all([r1, r2])
    await db_session.commit()

    # 3. Seed product and variants
    p1 = Product(tenant_id="t_abc", title="Book", slug="book", created_by="staff_1")
    db_session.add(p1)
    await db_session.commit()
    await db_session.refresh(p1)

    v_taxable = Variant(
        product_id=p1.product_id, tenant_id="t_abc", sku="TAXABLE-BK", price=Decimal("10.00"), requires_shipping=True, taxable=True
    )
    v_nontaxable = Variant(
        product_id=p1.product_id, tenant_id="t_abc", sku="NONTAXABLE-BK", price=Decimal("50.00"), requires_shipping=True, taxable=False
    )
    db_session.add_all([v_taxable, v_nontaxable])
    await db_session.commit()
    await db_session.refresh(v_taxable)
    await db_session.refresh(v_nontaxable)

    # 4. Request tax calculation for CA (California)
    payload_ca = {
        "country_code": "US",
        "state_code": "CA",
        "items": [
            {"variant_id": v_taxable.variant_id, "quantity": 2}, # 2 * 10 = $20. Tax = $20 * 8% = $1.60
            {"variant_id": v_nontaxable.variant_id, "quantity": 1} # Taxable is False -> $0 tax
        ]
    }
    
    resp_ca = await client.post("/api/v1/tax/calculate", json=payload_ca, headers=headers)
    assert resp_ca.status_code == 200
    data_ca = resp_ca.json()
    assert data_ca["calculation_mode"] == "manual_fallback"
    assert Decimal(str(data_ca["total_tax_amount"])) == Decimal("1.60")
    assert Decimal(str(data_ca["tax_rate_percentage"])) == Decimal("8.00")

    # 5. Request tax calculation for NY (New York - fallback to US general)
    payload_ny = {
        "country_code": "US",
        "state_code": "NY",
        "items": [
            {"variant_id": v_taxable.variant_id, "quantity": 2} # 2 * 10 = $20. Tax = $20 * 5% = $1.00
        ]
    }
    
    resp_ny = await client.post("/api/v1/tax/calculate", json=payload_ny, headers=headers)
    assert resp_ny.status_code == 200
    data_ny = resp_ny.json()
    assert Decimal(str(data_ny["total_tax_amount"])) == Decimal("1.00")
    assert Decimal(str(data_ny["tax_rate_percentage"])) == Decimal("5.00")

@pytest.mark.asyncio
async def test_tax_calculation_stripe_automated(client: AsyncClient, mock_firebase_user, db_session: AsyncSession):
    headers = {"Authorization": "Bearer valid_token"}

    # 1. Update tenant to enable stripe_tax_enabled
    tenant_res = await db_session.execute(select(Tenant).where(Tenant.id == "t_abc"))
    tenant = tenant_res.scalar_one_or_none()
    if not tenant:
        tenant = Tenant(id="t_abc", name="Acme", config={"stripe_tax_enabled": True})
        db_session.add(tenant)
    else:
        cfg = dict(tenant.config or {})
        cfg["stripe_tax_enabled"] = True
        tenant.config = cfg
    await db_session.commit()

    # 2. Seed variant
    p1 = Product(tenant_id="t_abc", title="Shirt", slug="shirt", created_by="staff_1")
    db_session.add(p1)
    await db_session.commit()
    await db_session.refresh(p1)

    v1 = Variant(
        product_id=p1.product_id, tenant_id="t_abc", sku="SHIRT-M", price=Decimal("100.00"), requires_shipping=True, taxable=True
    )
    db_session.add(v1)
    await db_session.commit()
    await db_session.refresh(v1)

    # 3. Request calculation
    payload = {
        "country_code": "US",
        "state_code": "NY",
        "items": [
            {"variant_id": v1.variant_id, "quantity": 1} # $100 * 8.5% Stripe simulated = $8.50
        ]
    }
    
    response = await client.post("/api/v1/tax/calculate", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["calculation_mode"] == "stripe_automated"
    assert Decimal(str(data["total_tax_amount"])) == Decimal("8.50")
    assert Decimal(str(data["tax_rate_percentage"])) == Decimal("8.50")
