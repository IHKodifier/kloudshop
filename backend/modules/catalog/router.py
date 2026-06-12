from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks, UploadFile, File, Form
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import selectinload
from typing import List, Optional, Dict
from shared.db import get_db, AsyncSessionLocal
from shared.auth import UserClaims
from shared.rbac import has_permissions
from .models import Product, Variant, Collection, CollectionProduct, ImportJob, RedirectRule, ColorPreset
from .schemas import (
    ProductCreate, ProductResponse, VariantCreate, ProductUpdate,
    CollectionCreate, CollectionResponse, CollectionUpdate, ProductAssignment,
    ImportJobResponse, RedirectRuleResponse, ColorPresetCreate, ColorPresetResponse,
    SkuExistsRequest, SkuExistsResponse
)
import csv
import io
import os
import re
import json
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation

router = APIRouter()

@router.post("/", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
async def create_product(
    product_data: ProductCreate,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    """
    Create a new product with its variants.
    Enforces catalog:write permission and tenant scoping.
    """
    # 1. Create Product
    product_dict = product_data.model_dump(exclude={"variants"})
    new_product = Product(
        **product_dict,
        tenant_id=user.tenant_id,
        created_by=user.uid
    )
    
    try:
        db.add(new_product)
        await db.flush() # Get product_id for variants
        
        # 2. Create Variants
        for v_data in product_data.variants:
            new_variant = Variant(
                **v_data.model_dump(),
                product_id=new_product.product_id,
                tenant_id=user.tenant_id
            )
            db.add(new_variant)
        
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        error_msg = str(e.orig).lower()
        if "variants.sku" in error_msg or "uix_variant_tenant_sku" in error_msg:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A variant with this SKU already exists in your catalog."
            )
        if "products.slug" in error_msg or "uix_product_tenant_slug" in error_msg:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A product with this URL slug already exists."
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Database integrity error: {str(e.orig)}"
        )
    
    await db.refresh(new_product)
    
    # Re-fetch with variants to ensure they are loaded
    result = await db.execute(
        select(Product).options(selectinload(Product.variants)).where(Product.product_id == new_product.product_id)
    )
    # 3. Trigger Google Shopping update
    background_tasks.add_task(trigger_google_shopping_update, user.tenant_id, new_product.product_id)

    return result.scalars().first()

@router.get("/", response_model=List[ProductResponse])
async def list_products(
    limit: int = 100,
    offset: int = 0,
    search: Optional[str] = None,
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:read"])
):
    """
    List products for the authenticated tenant.
    Supports pagination and filtering by status.
    """
    query = select(Product).options(selectinload(Product.variants)).where(Product.tenant_id == user.tenant_id)
    
    if status:
        query = query.where(Product.status == status)
        
    if search:
        # Simple search for now
        query = query.where(Product.title.ilike(f"%{search}%"))
        
    query = query.offset(offset).limit(limit)
    
    result = await db.execute(query)
    products = result.scalars().all()
    
    return products

@router.put("/{product_id}", response_model=ProductResponse)
async def update_product(
    product_id: str,
    product_data: ProductUpdate,
    background_tasks: BackgroundTasks,
    email_sku_report: bool = False,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    """
    Update a product and its variants. If slug changes, create a 301 redirect.
    """
    # 1. Fetch existing product
    result = await db.execute(
        select(Product).options(
            selectinload(Product.variants).selectinload(Variant.inventory_items)
        ).where(
            Product.product_id == product_id,
            Product.tenant_id == user.tenant_id
        )
    )
    product = result.scalars().first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    old_slug = product.slug
    new_slug = product_data.slug

    # 2. Update Product fields
    update_dict = product_data.model_dump(exclude_unset=True, exclude={"variants"})
    for key, value in update_dict.items():
        setattr(product, key, value)

    # 3. Handle Variants Reconciliation
    sku_changes = []
    collapsed_variants = []
    if product_data.variants is not None:
        has_old_options = any(len(v.option_values or {}) > 0 for v in product.variants if v.is_active)
        has_new_options = any(len(v_data.option_values or {}) > 0 for v_data in product_data.variants if getattr(v_data, 'is_active', True))
        
        if has_old_options and not has_new_options:
            for v in product.variants:
                if len(v.option_values or {}) > 0 and v.is_active:
                    collapsed_variants.append({
                        "sku": v.sku,
                        "option_values": v.option_values,
                        "price": float(v.price),
                        "compare_at_price": float(v.compare_at_price) if v.compare_at_price is not None else None,
                        "stock": sum(item.quantity_on_hand for item in v.inventory_items)
                    })

        existing_variants_map = {v.variant_id: v for v in product.variants}
        incoming_variant_ids = {v.variant_id for v in product_data.variants if v.variant_id}
        
        # a. Delete variants not in incoming list
        for v_id in list(existing_variants_map.keys()):
            if v_id not in incoming_variant_ids:
                await db.delete(existing_variants_map[v_id])
        
        # b. Update or Create variants
        for v_data in product_data.variants:
            if v_data.variant_id and v_data.variant_id in existing_variants_map:
                # Update existing
                variant = existing_variants_map[v_data.variant_id]
                # Track SKU change before writing update
                if v_data.sku and v_data.sku != variant.sku:
                    sku_changes.append({
                        "option_values": variant.option_values,
                        "old_sku": variant.sku,
                        "new_sku": v_data.sku
                    })
                v_update_dict = v_data.model_dump(exclude_unset=True, exclude={"variant_id"})
                for key, value in v_update_dict.items():
                    setattr(variant, key, value)
            else:
                # Create new
                # Ensure all default values are populated by converting to VariantCreate
                v_dict = v_data.model_dump(exclude={"variant_id"}, exclude_none=True)
                v_create = VariantCreate(**v_dict)
                new_variant = Variant(
                    **v_create.model_dump(),
                    product_id=product.product_id,
                    tenant_id=user.tenant_id
                )
                product.variants.append(new_variant)

    # 4. Handle slug change -> 301 Redirect
    if new_slug and new_slug != old_slug:
        old_path = f"/products/{old_slug}"
        new_path = f"/products/{new_slug}"

        # Flatten chains: if something already redirects to old_path, update it to new_path
        existing_chains = await db.execute(
            select(RedirectRule).where(
                RedirectRule.tenant_id == user.tenant_id,
                RedirectRule.destination_path == old_path
            )
        )
        for chain in existing_chains.scalars().all():
            chain.destination_path = new_path

        # Create new redirect rule
        existing_rule = await db.execute(
            select(RedirectRule).where(
                RedirectRule.tenant_id == user.tenant_id,
                RedirectRule.source_path == old_path
            )
        )
        rule = existing_rule.scalars().first()
        if rule:
            rule.destination_path = new_path
            rule.is_auto_generated = True
        else:
            new_rule = RedirectRule(
                tenant_id=user.tenant_id,
                source_path=old_path,
                destination_path=new_path,
                redirect_type=301,
                is_auto_generated=True,
                created_by=user.uid
            )
            db.add(new_rule)

    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        error_msg = str(e.orig).lower()
        if "variants.sku" in error_msg or "uix_variant_tenant_sku" in error_msg:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A variant with this SKU already exists in your catalog."
            )
        if "products.slug" in error_msg or "uix_product_tenant_slug" in error_msg:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A product with this URL slug already exists."
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Database integrity error: {str(e.orig)}"
        )
    
    # Re-fetch to return full object with updated variants
    result = await db.execute(
        select(Product).options(selectinload(Product.variants)).where(
            Product.product_id == product_id,
            Product.tenant_id == user.tenant_id
        )
    )
    product = result.scalars().first()

    # 5. Trigger Google Shopping update
    background_tasks.add_task(trigger_google_shopping_update, user.tenant_id, product.product_id)

    # 6. Send SKU report email if requested and SKUs changed
    if email_sku_report and sku_changes:
        background_tasks.add_task(send_sku_change_report_email, user.email, product.title, product.slug, sku_changes)

    # 7. Send Collapse Report email if variants were collapsed to simple product
    if collapsed_variants:
        background_tasks.add_task(send_collapse_variant_report_email, user.email, product.title, product.slug, collapsed_variants)

    return product

@router.get("/redirects", response_model=List[RedirectRuleResponse])
async def list_redirects(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:read"])
):
    """
    List 301 redirects for the tenant.
    """
    result = await db.execute(
        select(RedirectRule).where(RedirectRule.tenant_id == user.tenant_id)
    )
    return result.scalars().all()

# --- Background Tasks ---

async def trigger_google_shopping_update(tenant_id: str, product_id: str):
    """
    Placeholder for Google Shopping feed update.
    In production, this would trigger a Cloud Run job or update a GCS XML feed.
    """
    print(f"DEBUG: Triggering Google Shopping update for tenant {tenant_id}, product {product_id}")
    # TODO: Implement XML feed regeneration logic

async def send_sku_change_report_email(email: str, product_title: str, product_slug: str, changes: list):
    """
    Simulates sending an email report of variant SKU changes to the merchant.
    """
    print(f"DEBUG: Sending SKU change report email to {email} for product '{product_title}' (slug: {product_slug})")
    for change in changes:
        opt_str = " / ".join(f"{k}: {v}" for k, v in change["option_values"].items())
        print(f"  - Variant ({opt_str}): {change['old_sku']} -> {change['new_sku']}")

async def send_collapse_variant_report_email(email: str, product_title: str, product_slug: str, variants: list):
    """
    Simulates sending an email report of deactivated variants during options collapse to the merchant.
    """
    print(f"DEBUG: Sending Collapse Variant Report email to {email} for product '{product_title}' (slug: {product_slug})")
    print("  Deactivated Variants Archive:")
    for v in variants:
        opt_str = " / ".join(f"{k}: {v}" for k, v in v["option_values"].items())
        print(f"  - SKU: {v['sku']} ({opt_str}) | Price: {v['price']} | Compare-At: {v['compare_at_price']} | Stock: {v['stock']}")

# --- Collections ---

@router.post("/collections", response_model=CollectionResponse, status_code=status.HTTP_201_CREATED)
async def create_collection(
    collection_data: CollectionCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    new_collection = Collection(
        **collection_data.model_dump(),
        tenant_id=user.tenant_id
    )
    try:
        db.add(new_collection)
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Database integrity error: {str(e.orig)}"
        )
    await db.refresh(new_collection)
    return new_collection

@router.get("/collections", response_model=List[CollectionResponse])
async def list_collections(
    limit: int = 100,
    offset: int = 0,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:read"])
):
    query = select(Collection).where(Collection.tenant_id == user.tenant_id)
    query = query.offset(offset).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()

@router.get("/collections/{collection_id}", response_model=CollectionResponse)
async def get_collection(
    collection_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:read"])
):
    result = await db.execute(
        select(Collection).where(
            Collection.collection_id == collection_id,
            Collection.tenant_id == user.tenant_id
        )
    )
    collection = result.scalars().first()
    if not collection:
        raise HTTPException(status_code=404, detail="Collection not found")
    return collection

@router.put("/collections/{collection_id}", response_model=CollectionResponse)
async def update_collection(
    collection_id: str,
    collection_data: CollectionUpdate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    result = await db.execute(
        select(Collection).where(
            Collection.collection_id == collection_id,
            Collection.tenant_id == user.tenant_id
        )
    )
    collection = result.scalars().first()
    if not collection:
        raise HTTPException(status_code=404, detail="Collection not found")
    
    update_data = collection_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(collection, key, value)
    
    await db.commit()
    await db.refresh(collection)
    return collection

@router.delete("/collections/{collection_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_collection(
    collection_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    result = await db.execute(
        select(Collection).where(
            Collection.collection_id == collection_id,
            Collection.tenant_id == user.tenant_id
        )
    )
    collection = result.scalars().first()
    if not collection:
        raise HTTPException(status_code=404, detail="Collection not found")
    
    await db.delete(collection)
    await db.commit()
    return None

@router.post("/collections/{collection_id}/products", status_code=status.HTTP_200_OK)
async def assign_products_to_collection(
    collection_id: str,
    assignment: ProductAssignment,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    # 1. Verify collection exists and belongs to tenant
    result = await db.execute(
        select(Collection).where(
            Collection.collection_id == collection_id,
            Collection.tenant_id == user.tenant_id
        )
    )
    collection = result.scalars().first()
    if not collection:
        raise HTTPException(status_code=404, detail="Collection not found")
    
    # 2. Verify products exist and belong to tenant
    result = await db.execute(
        select(Product).where(
            Product.product_id.in_(assignment.product_ids),
            Product.tenant_id == user.tenant_id
        )
    )
    products = result.scalars().all()
    if len(products) != len(assignment.product_ids):
        raise HTTPException(status_code=400, detail="One or more products not found or unauthorized")
    
    # 3. Create assignments (ignore duplicates for now)
    for product_id in assignment.product_ids:
        # Check if already assigned to avoid IntegrityError on primary key
        existing = await db.execute(
            select(CollectionProduct).where(
                CollectionProduct.collection_id == collection_id,
                CollectionProduct.product_id == product_id
            )
        )
        if not existing.scalars().first():
            db.add(CollectionProduct(collection_id=collection_id, product_id=product_id))
    
    await db.commit()
    return {"message": f"Successfully assigned {len(products)} products to collection"}

@router.delete("/collections/{collection_id}/products/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_product_from_collection(
    collection_id: str,
    product_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    # Verify collection belongs to tenant
    coll_result = await db.execute(
        select(Collection).where(
            Collection.collection_id == collection_id,
            Collection.tenant_id == user.tenant_id
        )
    )
    if not coll_result.scalars().first():
        raise HTTPException(status_code=404, detail="Collection not found")
        
    result = await db.execute(
        select(CollectionProduct).where(
            CollectionProduct.collection_id == collection_id,
            CollectionProduct.product_id == product_id
        )
    )
    assignment = result.scalars().first()
    if not assignment:
        raise HTTPException(status_code=404, detail="Product not found in collection")
    
    await db.delete(assignment)
    await db.commit()
    return None

# --- Bulk Import ---

async def background_import_task(job_id: str, content: bytes, tenant_id: str, user_id: str, db_factory):
    """
    Process CSV import in background.
    Simple AI Mapping: Look for 'title', 'price', 'sku' etc.
    """
    async with db_factory() as db:
        job = await db.get(ImportJob, job_id)
        if not job:
            return
        
        job.status = 'processing'
        await db.commit()
        
        try:
            reader = csv.DictReader(io.StringIO(content.decode('utf-8')))
            rows = list(reader)
            job.rows_total = len(rows)
            await db.commit()
            
            for i, row in enumerate(rows):
                try:
                    # Simple Mapping (AI placeholder)
                    # Mapping logic could be enhanced with LLM later
                    title = row.get('title') or row.get('name') or row.get('Title')
                    price = row.get('price') or row.get('Price') or row.get('amount')
                    sku = row.get('sku') or row.get('SKU') or row.get('id')
                    
                    if not title or not price or not sku:
                        raise ValueError(f"Missing required fields in row {i+1}")
                    
                    # Create Product
                    new_product = Product(
                        title=title,
                        slug=title.lower().replace(" ", "-"), # Basic slugification
                        tenant_id=tenant_id,
                        created_by=user_id,
                        status='draft'
                    )
                    db.add(new_product)
                    await db.flush()
                    
                    # Create Variant
                    new_variant = Variant(
                        sku=sku,
                        price=float(price),
                        product_id=new_product.product_id,
                        tenant_id=tenant_id
                    )
                    db.add(new_variant)
                    
                    job.rows_processed += 1
                except Exception as e:
                    job.rows_failed += 1
                    log = job.error_log.copy() if job.error_log else []
                    log.append({"row": i+1, "error": str(e)})
                    job.error_log = log
                
                # Commit every 10 rows for progress
                if i % 10 == 0:
                    await db.commit()
            
            job.status = 'completed'
            await db.commit()
            
        except Exception as e:
            job.status = 'failed'
            log = job.error_log.copy() if job.error_log else []
            log.append({"row": 0, "error": f"Critical failure: {str(e)}"})
            job.error_log = log
            await db.commit()

@router.post("/bulk-import", response_model=ImportJobResponse, status_code=status.HTTP_202_ACCEPTED)
async def start_bulk_import(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    """
    Start a bulk import job from CSV.
    """
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="Only CSV files are supported for now")
    
    content = await file.read()
    
    new_job = ImportJob(
        tenant_id=user.tenant_id,
        status='pending'
    )
    db.add(new_job)
    await db.commit()
    await db.refresh(new_job)
    
    # We pass the content directly for now (small files)
    # In production, we'd save to storage and pass URI
    from shared.db import AsyncSessionLocal
    background_tasks.add_task(
        background_import_task,
        new_job.job_id,
        content,
        user.tenant_id,
        user.uid,
        AsyncSessionLocal
    )
    
    return new_job

@router.get("/import-jobs/{job_id}", response_model=ImportJobResponse)
async def get_import_job(
    job_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:read"])
):
    result = await db.execute(
        select(ImportJob).where(
            ImportJob.job_id == job_id,
            ImportJob.tenant_id == user.tenant_id
        )
    )
    job = result.scalars().first()
    if not job:
        raise HTTPException(status_code=404, detail="Import job not found")
    return job

# --- Color Presets CRUD ---

@router.post("/color-presets", response_model=ColorPresetResponse, status_code=status.HTTP_201_CREATED)
async def create_color_preset(
    preset_data: ColorPresetCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    """
    Create a new color preset for the merchant's tenant.
    """
    new_preset = ColorPreset(
        name=preset_data.name,
        hex_code=preset_data.hex_code,
        tenant_id=user.tenant_id
    )
    try:
        db.add(new_preset)
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A color preset with this name already exists."
        )
    await db.refresh(new_preset)
    return new_preset

@router.get("/color-presets", response_model=List[ColorPresetResponse])
async def list_color_presets(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:read"])
):
    """
    List all color presets for the tenant.
    """
    import uuid
    result = await db.execute(
        select(ColorPreset).where(ColorPreset.tenant_id == user.tenant_id).order_by(ColorPreset.name)
    )
    presets = result.scalars().all()
    if not presets:
        default_data = [
            ("Pure white", "#ffffff"),
            ("Jet black", "#000000"),
            ("Metallic silver", "#c0c0c0"),
        ]
        presets = []
        for name, hex_code in default_data:
            new_preset = ColorPreset(
                preset_id=str(uuid.uuid4()),
                tenant_id=user.tenant_id,
                name=name,
                hex_code=hex_code,
            )
            db.add(new_preset)
            presets.append(new_preset)
        try:
            await db.commit()
            for p in presets:
                await db.refresh(p)
        except Exception:
            await db.rollback()
            result = await db.execute(
                select(ColorPreset).where(ColorPreset.tenant_id == user.tenant_id).order_by(ColorPreset.name)
            )
            presets = result.scalars().all()
            
    return presets

@router.delete("/color-presets/{preset_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_color_preset(
    preset_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    """
    Delete a color preset for the tenant.
    """
    result = await db.execute(
        select(ColorPreset).where(
            ColorPreset.preset_id == preset_id,
            ColorPreset.tenant_id == user.tenant_id
        )
    )
    preset = result.scalars().first()
    if not preset:
        raise HTTPException(status_code=404, detail="Color preset not found")
    await db.delete(preset)
    await db.commit()
    return None

@router.put("/color-presets/{preset_id}", response_model=ColorPresetResponse)
async def update_color_preset(
    preset_id: str,
    preset_data: ColorPresetCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    """
    Update an existing color preset for the tenant.
    """
    result = await db.execute(
        select(ColorPreset).where(
            ColorPreset.preset_id == preset_id,
            ColorPreset.tenant_id == user.tenant_id
        )
    )
    preset = result.scalars().first()
    if not preset:
        raise HTTPException(status_code=404, detail="Color preset not found")
    
    preset.name = preset_data.name
    preset.hex_code = preset_data.hex_code
    
    try:
        await db.commit()
        await db.refresh(preset)
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A color preset with this name already exists."
        )
    return preset


# ─────────────────────────────────────────────────────────────────────────────
# CSV / XLSX BULK IMPORT
# ─────────────────────────────────────────────────────────────────────────────

CSV_TEMPLATE_HEADERS = [
    "Handle", "Title", "Description", "Status",
    "Meta Title", "Meta Description",
    "Is Digital", "Is Perishable", "In Store Eligible",
    "Weight Value", "Weight Unit", "Length", "Width", "Height", "Dimension Unit",
    "Age Verification Required", "Minimum Age Years", "Requires Prescription",
    "SKU", "Price", "Stock", "Compare At Price", "Cost Per Item",
    "Barcode", "Taxable", "Requires Shipping",
    "Option1 Name", "Option1 Value",
    "Option2 Name", "Option2 Value",
    "Option3 Name", "Option3 Value",
]

DEV_REPORT_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "scratch", "import_reports")


def _send_import_report(job: ImportJob, initiated_by_email: str, csv_bytes: bytes, filename: str):
    """Dev: print to console + save to scratch/import_reports. Prod: real email."""
    now_str = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    started = job.processing_started_at.strftime("%Y-%m-%d %H:%M:%S UTC") if job.processing_started_at else "N/A"
    completed = job.processing_completed_at.strftime("%Y-%m-%d %H:%M:%S UTC") if job.processing_completed_at else now_str

    no_stock_lines = "\n".join(
        f"  - Handle: {r.get('handle','?')} | SKU: {r.get('sku','?')} | Title: {r.get('title','?')}"
        for r in (job.no_stock_log or [])
    ) or "  (none — all imported products had stock values)"

    error_lines = "\n".join(
        f"  - Row {r.get('row','?')}: SKU \"{r.get('sku','?')}\" — {r.get('error','?')}"
        for r in (job.error_log or [])
    ) or "  (none)"

    skipped_lines = "\n".join(
        f"  - Row {r.get('row','?')}: SKU \"{r.get('sku','?')}\" — already existed (user chose Skip)"
        for r in (job.error_log or []) if r.get("reason") == "skipped_duplicate"
    ) or "  (none)"

    subject = f"KloudShop Import Report — {now_str[:10]} — \"{filename}\""
    body = f"""
{'='*70}
KLOUDSHOP BULK IMPORT REPORT
{'='*70}

AUDIT TRAIL
-----------
Initiated By:              {initiated_by_email}
Initiated On:              {job.created_at.strftime('%Y-%m-%d %H:%M:%S UTC') if job.created_at else 'N/A'}
Processing Started On:     {started}
Processing Completed On:   {completed}
Source File:               {filename}
Source File Size:          {(job.source_filesize_bytes or 0) / 1024:.1f} KB
Conflict Strategy:         {job.conflict_strategy or 'N/A'}

IMPORT SUMMARY
--------------
Total Rows in File:                          {job.rows_total}
Successfully Imported (clean):               {job.rows_processed}
Successfully Resolved (Overwrite):           {job.rows_overwritten}
Successfully Resolved (Custom SKU Rename):   {job.rows_custom_sku}
Skipped (Duplicate — user chose Skip):       {job.rows_skipped}
Failed (validation/DB errors):               {job.rows_failed}
Final Status:                                {job.status.upper()}

PRODUCTS WITHOUT STOCK (need manual inventory update)
-----------------------------------------------------
{no_stock_lines}

SKIPPED DUPLICATES (V2 Import Hint — review these)
--------------------------------------------------
{skipped_lines}

FAILED ROWS
-----------
{error_lines}

Attachment: {filename} (original source file)
{'='*70}
"""

    # DEV: print to console + save report to disk
    print(f"\n📧 [IMPORT REPORT] To: {initiated_by_email}")
    print(f"Subject: {subject}")
    print(body)

    try:
        os.makedirs(DEV_REPORT_DIR, exist_ok=True)
        safe_ts = now_str[:19].replace(" ", "_").replace(":", "-")
        report_path = os.path.join(DEV_REPORT_DIR, f"{safe_ts}_{filename}.report.txt")
        csv_path = os.path.join(DEV_REPORT_DIR, f"{safe_ts}_{filename}")
        with open(report_path, "w", encoding="utf-8") as f:
            f.write(body)
        with open(csv_path, "wb") as f:
            f.write(csv_bytes)
        print(f"[IMPORT REPORT] Saved to: {report_path}")
        print(f"[IMPORT REPORT] Source CSV saved to: {csv_path}\n")
    except Exception as e:
        print(f"[IMPORT REPORT] Failed to save to disk: {e}")

    # PROD: uncomment and configure real email sending here:
    # send_email(to=initiated_by_email, subject=subject, body=body, attachment=(filename, csv_bytes))


def _parse_bool(val: str) -> bool:
    return val.strip().upper() in ("TRUE", "1", "YES")


def _parse_decimal(val: str) -> Optional[Decimal]:
    try:
        return Decimal(val.strip()) if val.strip() else None
    except InvalidOperation:
        return None


def _parse_csv_bytes(file_bytes: bytes, filename: str) -> List[Dict]:
    """Parse CSV or XLSX bytes into a list of row dicts."""
    if filename.lower().endswith(".xlsx"):
        try:
            import openpyxl
            wb = openpyxl.load_workbook(io.BytesIO(file_bytes), read_only=True, data_only=True)
            ws = wb.active
            rows = list(ws.iter_rows(values_only=True))
            if not rows:
                return []
            headers = [str(c).strip() if c is not None else "" for c in rows[0]]
            return [
                {headers[i]: (str(cell).strip() if cell is not None else "") for i, cell in enumerate(row)}
                for row in rows[1:]
                if any(cell is not None for cell in row)
            ]
        except Exception as e:
            raise ValueError(f"XLSX parse error: {e}")
    else:
        text = file_bytes.decode("utf-8-sig", errors="replace")
        reader = csv.DictReader(io.StringIO(text))
        return [dict(row) for row in reader]


def _detect_option_columns(headers: List[str]) -> List[int]:
    """Return sorted list of N for all Option{N} Name/Value pairs found in headers."""
    ns = set()
    for h in headers:
        if not h or not isinstance(h, str):
            continue
        m = re.match(r'^Option(\d+) (Name|Value)$', h.strip())
        if m:
            ns.add(int(m.group(1)))
    return sorted(ns)


async def _process_import_job(
    job_id: str,
    file_bytes: bytes,
    filename: str,
    conflict_strategy: str,
    custom_sku_map: Dict[str, str],
    initiated_by_uid: str,
    initiated_by_email: str,
    tenant_id: str,
):
    """Background task: parse file, upsert products+variants+inventory, update job, send report."""
    async with AsyncSessionLocal() as db:
        # Load job
        result = await db.execute(select(ImportJob).where(ImportJob.job_id == job_id))
        job = result.scalar_one_or_none()
        if not job:
            return

        job.status = "processing"
        job.processing_started_at = datetime.now(timezone.utc)
        await db.commit()

        try:
            rows = _parse_csv_bytes(file_bytes, filename)
        except Exception as e:
            job.status = "failed"
            job.processing_completed_at = datetime.now(timezone.utc)
            job.error_log = [{"row": 0, "sku": "", "error": f"File parse error: {e}"}]
            job.rows_failed = 1
            await db.commit()
            return

        if not rows:
            job.status = "failed"
            job.processing_completed_at = datetime.now(timezone.utc)
            job.error_log = [{"row": 0, "sku": "", "error": "File is empty or has no data rows"}]
            job.rows_failed = 1
            await db.commit()
            return

        headers = list(rows[0].keys())
        option_ns = _detect_option_columns(headers)
        job.rows_total = len(rows)
        await db.commit()

        # Group rows by Handle
        product_groups: Dict[str, List] = {}
        for row in rows:
            handle = row.get("Handle", "").strip()
            if handle:
                product_groups.setdefault(handle, [])
                product_groups[handle].append(row)
            # rows with no handle at all: carry last handle (Shopify-style blank repeat)
            elif product_groups:
                last_handle = list(product_groups.keys())[-1]
                product_groups[last_handle].append(row)

        error_log = []
        no_stock_log = []
        rows_processed = 0
        rows_skipped = 0
        rows_overwritten = 0
        rows_custom_sku_count = 0
        rows_failed = 0
        global_row_idx = 1  # 1-based for user-facing error messages

        for handle, group_rows in product_groups.items():
            first_row = group_rows[0]
            title = first_row.get("Title", "").strip()

            # Validate required product fields
            if not handle or not title:
                for gr in group_rows:
                    rows_failed += 1
                    error_log.append({"row": global_row_idx, "sku": "", "error": "Missing required field: Handle or Title"})
                    global_row_idx += 1
                continue

            # Build options_schema from option columns dynamically
            option_names_seen = []
            for n in option_ns:
                opt_name = first_row.get(f"Option{n} Name", "").strip()
                if opt_name and opt_name not in option_names_seen:
                    option_names_seen.append(opt_name)

            options_schema = [{"name": name, "values": []} for name in option_names_seen]

            # Upsert Product
            prod_result = await db.execute(
                select(Product).where(Product.tenant_id == tenant_id, Product.slug == handle)
            )
            product = prod_result.scalar_one_or_none()

            if not product:
                product = Product(
                    tenant_id=tenant_id,
                    slug=handle,
                    title=title,
                    description=first_row.get("Description", "").strip() or None,
                    status=first_row.get("Status", "draft").strip() or "draft",
                    meta_title=first_row.get("Meta Title", "").strip() or None,
                    meta_description=first_row.get("Meta Description", "").strip() or None,
                    is_digital=_parse_bool(first_row.get("Is Digital", "FALSE")),
                    is_perishable=_parse_bool(first_row.get("Is Perishable", "FALSE")),
                    in_store_eligible=_parse_bool(first_row.get("In Store Eligible", "TRUE")),
                    weight_value=_parse_decimal(first_row.get("Weight Value", "")),
                    weight_unit=first_row.get("Weight Unit", "").strip() or None,
                    length_value=_parse_decimal(first_row.get("Length", "")),
                    width_value=_parse_decimal(first_row.get("Width", "")),
                    height_value=_parse_decimal(first_row.get("Height", "")),
                    dimension_unit=first_row.get("Dimension Unit", "").strip() or None,
                    age_verification_required=_parse_bool(first_row.get("Age Verification Required", "FALSE")),
                    minimum_age_years=int(first_row["Minimum Age Years"].strip()) if first_row.get("Minimum Age Years", "").strip().isdigit() else None,
                    requires_prescription=_parse_bool(first_row.get("Requires Prescription", "FALSE")),
                    options_schema=options_schema,
                    created_by=initiated_by_uid,
                )
                db.add(product)
                try:
                    await db.flush()
                except IntegrityError:
                    await db.rollback()
                    for gr in group_rows:
                        rows_failed += 1
                        error_log.append({"row": global_row_idx, "sku": gr.get("SKU", ""), "error": f"Slug '{handle}' already exists and could not be upserted"})
                        global_row_idx += 1
                    continue
            else:
                # Update product options_schema if new options found
                if options_schema:
                    product.options_schema = options_schema

            # Process variant rows
            for row in group_rows:
                raw_sku = row.get("SKU", "").strip()
                sku = raw_sku.strip("-")  # defensive trim
                price_str = row.get("Price", "").strip()

                if not sku or not price_str:
                    rows_failed += 1
                    error_log.append({"row": global_row_idx, "sku": raw_sku, "error": "Missing required field: SKU or Price"})
                    global_row_idx += 1
                    continue

                price = _parse_decimal(price_str)
                if price is None or price < 0:
                    rows_failed += 1
                    error_log.append({"row": global_row_idx, "sku": sku, "error": f"Invalid price: '{price_str}'"})
                    global_row_idx += 1
                    continue

                compare_at = _parse_decimal(row.get("Compare At Price", ""))
                if compare_at is not None and compare_at <= price:
                    rows_failed += 1
                    error_log.append({"row": global_row_idx, "sku": sku, "error": f"compare_at_price ({compare_at}) must be greater than price ({price})"})
                    global_row_idx += 1
                    continue

                # Build option_values map from dynamic columns
                option_values = {}
                for n in option_ns:
                    opt_name = (first_row if row.get(f"Option{n} Name", "").strip() == "" else row).get(f"Option{n} Name", "").strip()
                    if not opt_name:
                        opt_name = first_row.get(f"Option{n} Name", "").strip()
                    opt_val = row.get(f"Option{n} Value", "").strip()
                    if opt_name and opt_val:
                        option_values[opt_name] = opt_val

                # Check for existing variant with this SKU
                existing_result = await db.execute(
                    select(Variant).where(Variant.tenant_id == tenant_id, Variant.sku == sku)
                )
                existing_variant = existing_result.scalar_one_or_none()

                if existing_variant:
                    effective_strategy = conflict_strategy
                    final_sku = sku

                    if effective_strategy == "skip":
                        rows_skipped += 1
                        error_log.append({"row": global_row_idx, "sku": sku, "error": "SKU already exists — skipped (user chose Skip)", "reason": "skipped_duplicate"})
                        global_row_idx += 1
                        continue
                    elif effective_strategy == "overwrite":
                        existing_variant.price = price
                        existing_variant.compare_at_price = compare_at
                        existing_variant.cost_per_item = _parse_decimal(row.get("Cost Per Item", ""))
                        existing_variant.option_values = option_values
                        rows_overwritten += 1
                        variant_to_stock = existing_variant
                    elif effective_strategy == "custom_sku":
                        new_sku = custom_sku_map.get(sku, "").strip().strip("-")
                        if not new_sku:
                            rows_failed += 1
                            error_log.append({"row": global_row_idx, "sku": sku, "error": "Custom SKU rename not provided for this duplicate"})
                            global_row_idx += 1
                            continue
                        final_sku = new_sku
                        rows_custom_sku_count += 1
                        variant_to_stock = Variant(
                            product_id=product.product_id,
                            tenant_id=tenant_id,
                            sku=final_sku,
                            barcode=row.get("Barcode", "").strip() or None,
                            price=price,
                            compare_at_price=compare_at,
                            cost_per_item=_parse_decimal(row.get("Cost Per Item", "")),
                            option_values=option_values,
                            taxable=_parse_bool(row.get("Taxable", "TRUE")),
                            requires_shipping=_parse_bool(row.get("Requires Shipping", "TRUE")),
                            is_active=True,
                        )
                        db.add(variant_to_stock)
                    else:
                        # Fallback: skip
                        rows_skipped += 1
                        error_log.append({"row": global_row_idx, "sku": sku, "error": "SKU already exists — skipped (fallback)", "reason": "skipped_duplicate"})
                        global_row_idx += 1
                        continue
                else:
                    variant_to_stock = Variant(
                        product_id=product.product_id,
                        tenant_id=tenant_id,
                        sku=sku,
                        barcode=row.get("Barcode", "").strip() or None,
                        price=price,
                        compare_at_price=compare_at,
                        cost_per_item=_parse_decimal(row.get("Cost Per Item", "")),
                        option_values=option_values,
                        taxable=_parse_bool(row.get("Taxable", "TRUE")),
                        requires_shipping=_parse_bool(row.get("Requires Shipping", "TRUE")),
                        is_active=True,
                    )
                    db.add(variant_to_stock)
                    rows_processed += 1

                # Seed inventory if Stock column provided
                stock_str = row.get("Stock", "").strip()
                if stock_str and stock_str.isdigit():
                    # Import inventory module lazily to avoid circular imports
                    try:
                        from modules.inventory.models import Inventory
                        await db.flush()  # ensure variant_id exists
                        inv_result = await db.execute(
                            select(Inventory).where(
                                Inventory.variant_id == variant_to_stock.variant_id,
                                Inventory.tenant_id == tenant_id
                            )
                        )
                        inv = inv_result.scalar_one_or_none()
                        if inv:
                            inv.quantity = int(stock_str)
                        else:
                            inv = Inventory(
                                tenant_id=tenant_id,
                                variant_id=variant_to_stock.variant_id,
                                quantity=int(stock_str),
                            )
                            db.add(inv)
                    except Exception:
                        pass  # Inventory module may not exist yet; skip silently
                else:
                    no_stock_log.append({"handle": handle, "sku": sku, "title": title})

                global_row_idx += 1

        # Final flush
        try:
            await db.flush()
            await db.commit()
        except Exception as e:
            await db.rollback()
            rows_failed += 1
            error_log.append({"row": 0, "sku": "", "error": f"DB commit error: {e}"})

        # Determine final status
        total_attempted = rows_processed + rows_overwritten + rows_custom_sku_count + rows_skipped + rows_failed
        if rows_failed == 0 and rows_skipped == 0:
            final_status = "successful"
        elif rows_processed + rows_overwritten + rows_custom_sku_count == 0:
            final_status = "failed"
        else:
            final_status = "partial_success"

        # Update job
        result2 = await db.execute(select(ImportJob).where(ImportJob.job_id == job_id))
        job = result2.scalar_one_or_none()
        if job:
            job.status = final_status
            job.rows_total = total_attempted
            job.rows_processed = rows_processed
            job.rows_skipped = rows_skipped
            job.rows_overwritten = rows_overwritten
            job.rows_custom_sku = rows_custom_sku_count
            job.rows_failed = rows_failed
            job.error_log = error_log
            job.no_stock_log = no_stock_log
            job.processing_completed_at = datetime.now(timezone.utc)
            await db.commit()

        # Send email report
        _send_import_report(job, initiated_by_email, file_bytes, filename)


@router.get("/import/template")
async def download_import_template(
    user: UserClaims = has_permissions(["catalog:write"])
):
    """Download a pre-filled CSV template with all supported import column headers."""
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(CSV_TEMPLATE_HEADERS)
    # Write one example product row + one variant row
    writer.writerow([
        "example-product", "Example Product", "Product description here", "draft",
        "Example Product | My Store", "A great example product.",
        "FALSE", "FALSE", "TRUE",
        "0.5", "kg", "", "", "", "",
        "FALSE", "", "FALSE",
        "EXAMPLE-SKU-001", "19.99", "100", "24.99", "10.00",
        "", "TRUE", "TRUE",
        "Color", "Red", "Size", "M", "", "",
    ])
    writer.writerow([
        "example-product", "", "", "",
        "", "", "", "", "",
        "", "", "", "", "", "",
        "", "", "",
        "EXAMPLE-SKU-002", "19.99", "50", "", "10.00",
        "", "TRUE", "TRUE",
        "Color", "Blue", "Size", "L", "", "",
    ])
    csv_content = output.getvalue().encode("utf-8-sig")  # BOM for Excel compatibility
    return StreamingResponse(
        io.BytesIO(csv_content),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=kloudshop_import_template.csv"},
    )


@router.post("/sku-exists", response_model=SkuExistsResponse)
async def check_sku_exists(
    payload: SkuExistsRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    """Check which SKUs from the provided list already exist in this tenant's catalog."""
    if not payload.skus:
        return SkuExistsResponse(duplicates=[])
    result = await db.execute(
        select(Variant.sku).where(
            Variant.tenant_id == user.tenant_id,
            Variant.sku.in_(payload.skus)
        )
    )
    found = [row[0] for row in result.all()]
    return SkuExistsResponse(duplicates=found)


@router.post("/import", response_model=ImportJobResponse, status_code=status.HTTP_202_ACCEPTED)
async def upload_csv_import(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    conflict_strategy: str = Form("skip"),
    custom_sku_map_json: str = Form("{}"),
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    """
    Upload a .csv or .xlsx file to bulk-import products and variants.
    Returns an ImportJob immediately; processing runs in the background.
    Poll GET /import/{job_id} to track progress.
    """
    if conflict_strategy not in ("skip", "overwrite", "custom_sku"):
        raise HTTPException(status_code=400, detail="conflict_strategy must be 'skip', 'overwrite', or 'custom_sku'")

    try:
        custom_sku_map: Dict[str, str] = json.loads(custom_sku_map_json)
    except Exception:
        raise HTTPException(status_code=400, detail="custom_sku_map_json must be valid JSON")

    filename = file.filename or "import.csv"
    file_bytes = await file.read()
    filesize = len(file_bytes)

    job = ImportJob(
        tenant_id=user.tenant_id,
        initiated_by=user.uid,
        source_filename=filename,
        source_filesize_bytes=filesize,
        conflict_strategy=conflict_strategy,
        status="pending",
        rows_total=0,
        rows_processed=0,
        rows_failed=0,
    )
    db.add(job)
    await db.commit()
    await db.refresh(job)

    background_tasks.add_task(
        _process_import_job,
        job.job_id,
        file_bytes,
        filename,
        conflict_strategy,
        custom_sku_map,
        user.uid,
        user.email or user.uid,
        user.tenant_id,
    )

    return job


@router.get("/import/history", response_model=List[ImportJobResponse])
async def get_import_history(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    """Returns all import jobs for this tenant, newest first."""
    result = await db.execute(
        select(ImportJob)
        .where(ImportJob.tenant_id == user.tenant_id)
        .order_by(ImportJob.created_at.desc())
    )
    return result.scalars().all()


@router.get("/import/{job_id}", response_model=ImportJobResponse)
async def get_import_job(
    job_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    """Poll the status of a specific import job."""
    result = await db.execute(
        select(ImportJob).where(
            ImportJob.job_id == job_id,
            ImportJob.tenant_id == user.tenant_id
        )
    )
    job = result.scalar_one_or_none()
    if not job:
        raise HTTPException(status_code=404, detail="Import job not found")
    return job
