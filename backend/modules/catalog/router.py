from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import selectinload
from typing import List, Optional
from shared.db import get_db
from shared.auth import UserClaims
from shared.rbac import has_permissions
from .models import Product, Variant, Collection, CollectionProduct, ImportJob, RedirectRule
from .schemas import (
    ProductCreate, ProductResponse, VariantCreate, ProductUpdate,
    CollectionCreate, CollectionResponse, CollectionUpdate, ProductAssignment,
    ImportJobResponse, RedirectRuleResponse
)
import csv
import io

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
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    """
    Update a product and its variants. If slug changes, create a 301 redirect.
    """
    # 1. Fetch existing product
    result = await db.execute(
        select(Product).options(selectinload(Product.variants)).where(
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
    if product_data.variants is not None:
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
                v_update_dict = v_data.model_dump(exclude_unset=True, exclude={"variant_id"})
                for key, value in v_update_dict.items():
                    setattr(variant, key, value)
            else:
                # Create new
                new_variant = Variant(
                    **v_data.model_dump(exclude={"variant_id"}),
                    product_id=product.product_id,
                    tenant_id=user.tenant_id
                )
                db.add(new_variant)

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
