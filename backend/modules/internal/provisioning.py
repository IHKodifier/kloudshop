from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import subprocess
import os
import anyio
from alembic.config import Config
from alembic import command

from shared.auth import UserClaims, validate_token
from shared.rbac import has_permissions
from shared.db import get_db
from modules.platform.models import Tenant
from sqlalchemy import select, text
from datetime import datetime
import uuid

router = APIRouter()

async def verify_gcp_connectivity():
    """
    Performs a 'peace of mind' test by creating and immediately deleting a GCS bucket.
    Ensures gcloud credentials and service account permissions are working.
    """
    test_id = str(uuid.uuid4())[:8]
    bucket_name = f"kloudshop-connectivity-test-{test_id}"
    
    def run_gcloud_tests():
        # Create bucket
        subprocess.run(["gsutil", "mb", f"gs://{bucket_name}"], check=True, capture_output=True, shell=(os.name == 'nt'))
        # Delete bucket immediately
        subprocess.run(["gsutil", "rb", f"gs://{bucket_name}"], check=True, capture_output=True, shell=(os.name == 'nt'))

    try:
        await anyio.to_thread.run_sync(run_gcloud_tests)
        return f"GCP Connectivity Verified (Test bucket {bucket_name} created and deleted)."
    except subprocess.CalledProcessError as e:
        raise Exception(f"GCP Connectivity Test failed: {e.stderr}")

@router.post("/provision-tenant", status_code=status.HTTP_201_CREATED)
async def provision_tenant(
    tenant_id: str,
    user: UserClaims = Depends(validate_token),
    db: AsyncSession = Depends(get_db)

):
    """
    Provisions isolated GCP resources and SQL schema for a new tenant.
    This is an internal idempotent operation.
    """
    from shared.db import engine
    is_sqlite = "sqlite" in engine.url.drivername
    
    
    # 0. Safety Check: Does this user already own a store?
    from modules.auth.models import StaffRoleAssignment
    existing_assignment = await db.execute(
        select(StaffRoleAssignment).where(
            StaffRoleAssignment.staff_user_id == user.uid,
            StaffRoleAssignment.is_owner == True
        )
    )
    if existing_assignment.scalar_one_or_none():
        raise HTTPException(
            status_code=400, 
            detail="You already own a provisioned store. Please refresh your session."
        )

    logs = []
    
    # 1. Connectivity Test (Peace of Mind)
    try:
        test_log = await verify_gcp_connectivity()
        logs.append(test_log)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    # 2. Run GCP Provisioning Script
    script_ext = "ps1" if os.name == "nt" else "sh"
    shell_cmd = "powershell" if os.name == "nt" else "bash"
    script_path = os.path.join(os.getcwd(), "..", "infrastructure", f"provision_tenant.{script_ext}")
    
    env = "dev" 
    
    try:
        cmd = [shell_cmd]
        if os.name == "nt":
            cmd.extend(["-ExecutionPolicy", "Bypass", "-File", script_path, "-TenantId", tenant_id, "-Environment", env])
        else:
            cmd.extend([script_path, tenant_id, env])
            
        def run_script():
            return subprocess.run(cmd, capture_output=True, text=True, check=True)
            
        result = await anyio.to_thread.run_sync(run_script)
        result_stdout = result.stdout
        logs.append(f"GCP Script Output: {result_stdout}")
    except subprocess.CalledProcessError as e:
        raise HTTPException(status_code=500, detail=f"GCP Provisioning failed: {e.stderr}")

    # 3. Create PostgreSQL Schema
    schema_name = f"tenant_{tenant_id}"
    if not is_sqlite:
        try:
            await db.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema_name}"))
            await db.commit()
            logs.append(f"Database schema {schema_name} verified.")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Database schema creation failed: {str(e)}")

    # 4. Run Alembic Migrations
    if not is_sqlite:
        alembic_cfg = Config("alembic.ini")
        try:
            def run_migrations():
                os.environ["ALEMBIC_SCHEMA"] = schema_name
                command.upgrade(alembic_cfg, "head")
            await anyio.to_thread.run_sync(run_migrations)
            logs.append(f"Alembic migrations applied to {schema_name}.")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Database migration failed: {str(e)}")

    # 5. Create Tenant Record
    try:
        tenant = await db.get(Tenant, tenant_id)
        if not tenant:
            tenant = Tenant(
                id=tenant_id,
                name=tenant_id.capitalize(),
                gcp_project_id="kloudshop-dev",
                gcp_bucket_name=f"gs://kloudshop-dev-{tenant_id}"
            )
            db.add(tenant)
            await db.commit()
            logs.append(f"Tenant record {tenant_id} created in platform schema.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create tenant record: {str(e)}")

    # 6. Set Custom Claims in Firebase & Create Staff Assignment
    try:
        from firebase_admin import auth as firebase_auth
        from modules.auth.models import StaffRoleAssignment
        
        # Update Firebase Custom Claims
        fb_user = firebase_auth.get_user(user.uid)
        claims = fb_user.custom_claims or {}
        claims.update({
            "tenant_id": tenant_id,
            "roles": ["owner"],
            "is_owner": True,
            "account_type": "merchant"
        })
        firebase_auth.set_custom_user_claims(user.uid, claims)
        logs.append(f"Custom claims (tenant_id={tenant_id}) applied to user {user.uid}.")

        # Record ownership in database
        result = await db.execute(
            select(StaffRoleAssignment).where(
                StaffRoleAssignment.staff_user_id == user.uid,
                StaffRoleAssignment.tenant_id == tenant_id
            )
        )
        assignment = result.scalar_one_or_none()
        if not assignment:
            assignment = StaffRoleAssignment(
                staff_user_id=user.uid,
                tenant_id=tenant_id,
                roles=["owner"],
                is_owner=True,
                accepted_at=datetime.utcnow()
            )
            db.add(assignment)
            await db.commit()
            logs.append(f"Staff role assignment created for owner {user.uid}.")
            
    except Exception as e:
        # We don't fail the whole request if claims fail (idempotency), but we log it
        logs.append(f"WARNING: Identity sync failed: {str(e)}")

    return {
        "status": "provisioned",
        "tenant_id": tenant_id,
        "refresh_token_required": True,
        "schema": schema_name if not is_sqlite else "shared (sqlite)",
        "logs": "\n".join(logs)
    }

@router.post("/seed-demo-data")
async def seed_demo_data(
    user: UserClaims = Depends(validate_token),
    db: AsyncSession = Depends(get_db)
):
    """
    Seeds mock orders and customers for the current tenant.
    Enables verification of the Orders and Customers listing grids.
    """
    from modules.catalog.models import Product, Variant
    from modules.orders.models import Order, OrderItem, OrderEvent
    from modules.inventory.models import StockLocation, Inventory
    from modules.storefront.models import BrandProfile
    import random
    from datetime import timedelta
    from decimal import Decimal

    tenant_id = user.tenant_id
    if not tenant_id:
        raise HTTPException(status_code=400, detail="User has no tenant_id assigned.")

    # 0. Ensure Brand Profile exists (required for public storefront)
    brand_res = await db.execute(select(BrandProfile).where(BrandProfile.tenant_id == tenant_id))
    brand_profile = brand_res.scalars().first()
    if not brand_profile:
        brand_profile = BrandProfile(
            tenant_id=tenant_id,
            brand_name=tenant_id.capitalize(),
            slug=tenant_id,
            is_published=True,
            primary_color="#000000",
            secondary_color="#FFFFFF"
        )
        db.add(brand_profile)
        await db.flush()
    elif not brand_profile.is_published:
        brand_profile.is_published = True
        await db.flush()

    # 1. Ensure we have at least one stock location
    loc_res = await db.execute(select(StockLocation).where(StockLocation.is_active == True))
    location = loc_res.scalars().first()
    if not location:
        location = StockLocation(
            tenant_id=tenant_id,
            name="Main Warehouse",
            is_default=True,
            is_active=True
        )
        db.add(location)
        await db.flush()

    # 2. Ensure we have at least one product and variant
    prod_res = await db.execute(select(Product).where(Product.tenant_id == tenant_id))
    product = prod_res.scalars().first()
    if not product:
        product = Product(
            tenant_id=tenant_id,
            title="Demo Product",
            slug="demo-product",
            status="active",
            created_by=user.uid
        )
        db.add(product)
        await db.flush()
        
        variant = Variant(
            product_id=product.product_id,
            tenant_id=tenant_id,
            sku="DEMO-SKU-01",
            price=Decimal("99.99"),
            is_active=True
        )
        db.add(variant)
        await db.flush()
        
        # Add inventory
        inv = Inventory(
            tenant_id=tenant_id,
            variant_id=variant.variant_id,
            stock_location_id=location.stock_location_id,
            quantity_on_hand=500
        )
        db.add(inv)
    else:
        var_res = await db.execute(select(Variant).where(Variant.product_id == product.product_id))
        variant = var_res.scalars().first()

    # 3. Generate 10 Mock Orders
    mock_customers = [
        ("alice@example.com", "Alice Smith"),
        ("bob@example.com", "Bob Johnson"),
        ("charlie@example.com", "Charlie Brown"),
        ("diana@example.com", "Diana Prince"),
        ("ethan@example.com", "Ethan Hunt")
    ]
    
    orders_created = 0
    now = datetime.utcnow()
    
    for i in range(10):
        email, name = random.choice(mock_customers)
        status_choice = random.choice(["unfulfilled", "fulfilled", "refunded"])
        payment_status = "paid" if status_choice != "refunded" else "refunded"
        days_ago = random.randint(0, 30)
        placed_at = now - timedelta(days=days_ago)
        
        order_number = f"DEMO-{random.randint(1000, 9999)}"
        
        # Check if order number already exists (highly unlikely for 10)
        check_order = await db.execute(select(Order).where(Order.order_number == order_number))
        if check_order.scalar_one_or_none():
            continue
            
        new_order = Order(
            order_number=order_number,
            tenant_id=tenant_id,
            email=email,
            payment_status=payment_status,
            fulfilment_status=status_choice if status_choice != "refunded" else "unfulfilled",
            currency="USD",
            subtotal=variant.price,
            tax_total=variant.price * Decimal("0.08"),
            grand_total=variant.price * Decimal("1.08"),
            shipping_name=name,
            shipping_city="Kloud City",
            shipping_country="US",
            placed_at=placed_at
        )
        db.add(new_order)
        await db.flush()
        
        # Add Order Item
        item = OrderItem(
            order_id=new_order.order_id,
            variant_id=variant.variant_id,
            product_id=product.product_id,
            title=product.title,
            sku=variant.sku,
            quantity=1,
            unit_price=variant.price,
            total_price=variant.price
        )
        db.add(item)
        
        # Add Event
        event = OrderEvent(
            order_id=new_order.order_id,
            event_type="payment_confirmed",
            description="Demo order created via Seeding.",
            created_at=placed_at
        )
        db.add(event)
        
        if status_choice == "fulfilled":
            event_f = OrderEvent(
                order_id=new_order.order_id,
                event_type="order_fulfilled",
                description="Demo fulfilment completed.",
                created_at=placed_at + timedelta(hours=random.randint(2, 48))
            )
            db.add(event_f)
            
        orders_created += 1

    await db.commit()
    return {"status": "seeded", "orders_created": orders_created}
