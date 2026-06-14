import pytest
from httpx import AsyncClient
import io
import json
import asyncio
from datetime import datetime
import openpyxl
from modules.catalog.models import Product, Variant, ImportJob
from shared.db import AsyncSessionLocal
from sqlalchemy import select

CSV_HEADER = "Handle,Title,Description,Status,Meta Title,Meta Description,Is Digital,Is Perishable,In Store Eligible,Weight Value,Weight Unit,Length,Width,Height,Dimension Unit,Age Verification Required,Minimum Age Years,Requires Prescription,SKU,Price,Stock,Compare At Price,Cost Per Item,Barcode,Taxable,Requires Shipping,Option1 Name,Option1 Value,Option2 Name,Option2 Value,Option3 Name,Option3 Value"

@pytest.mark.asyncio
async def test_import_template(client: AsyncClient, mock_firebase_user):
    """CSV-B-001 & CSV-B-002: Verify template returns valid headers."""
    headers = {"Authorization": "Bearer valid_token"}
    response = await client.get("/api/v1/products/import/template", headers=headers)
    assert response.status_code == 200
    assert response.headers["content-type"] == "text/csv; charset=utf-8"
    
    content = response.content.decode("utf-8-sig")
    first_line = content.splitlines()[0]
    expected_headers = CSV_HEADER.split(",")
    for h in expected_headers:
        assert h in first_line

@pytest.mark.asyncio
async def test_sku_exists_endpoint(client: AsyncClient, mock_firebase_user, db_session):
    """CSV-B-003: Check SKU existence check works."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # Pre-populate one variant
    async with AsyncSessionLocal() as db:
        prod = Product(
            tenant_id="t_abc",
            slug="existing-prod",
            title="Existing",
            created_by="test_user"
        )
        db.add(prod)
        await db.flush()
        v = Variant(
            product_id=prod.product_id,
            tenant_id="t_abc",
            sku="EXIST-SKU-1",
            price=10.0,
        )
        db.add(v)
        await db.commit()

    # Query sku-exists
    payload = {"skus": ["EXIST-SKU-1", "NON-EXIST-SKU-2"]}
    response = await client.post("/api/v1/products/sku-exists", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "EXIST-SKU-1" in data["duplicates"]
    assert "NON-EXIST-SKU-2" not in data["duplicates"]

@pytest.mark.asyncio
async def test_import_clean_csv(client: AsyncClient, mock_firebase_user, db_session):
    """CSV-B-004 & CSV-B-010: Successful import of clean CSV."""
    headers = {"Authorization": "Bearer valid_token"}
    
    csv_content = (
        CSV_HEADER + "\n" +
        "clean-prod,Clean Product,Desc,active,,,FALSE,FALSE,TRUE,0.5,kg,,,,,FALSE,,FALSE,CLEAN-SKU-1,15.50,10,20.00,5.00,,TRUE,TRUE,Color,Red,Size,M,,\n" +
        "clean-prod,,,,,,,,,,,,,,,,,,CLEAN-SKU-2,18.00,20,,,BarcodeX,TRUE,TRUE,Color,Blue,Size,L,,"
    )
    
    files = {"file": ("clean_products.csv", io.BytesIO(csv_content.encode("utf-8")), "text/csv")}
    data = {"conflict_strategy": "skip"}
    
    response = await client.post("/api/v1/products/import", files=files, data=data, headers=headers)
    assert response.status_code == 202
    job_data = response.json()
    job_id = job_data["job_id"]
    assert job_data["status"] == "pending"
    
    # Poll
    for _ in range(10):
        await asyncio.sleep(0.3)
        job_resp = await client.get(f"/api/v1/products/import/{job_id}", headers=headers)
        job_status = job_resp.json()["status"]
        if job_status in ("successful", "partial_success", "failed"):
            job_data = job_resp.json()
            break
            
    assert job_data["status"] == "successful"
    assert job_data["rows_total"] == 2
    assert job_data["rows_processed"] == 2
    assert job_data["rows_failed"] == 0
    assert job_data["rows_skipped"] == 0

@pytest.mark.asyncio
async def test_import_conflict_skip(client: AsyncClient, mock_firebase_user, db_session):
    """CSV-B-005: Upload with conflict_strategy=skip skips duplicate SKUs."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # Pre-populate variant with DUP-SKU-1
    async with AsyncSessionLocal() as db:
        prod = Product(
            tenant_id="t_abc",
            slug="dup-prod",
            title="Dup Product",
            created_by="test_user"
        )
        db.add(prod)
        await db.flush()
        v = Variant(
            product_id=prod.product_id,
            tenant_id="t_abc",
            sku="DUP-SKU-1",
            price=10.0,
        )
        db.add(v)
        await db.commit()

    # Two rows: Row 1 is a duplicate (skip); Row 2 is clean (import successfully)
    csv_content = (
        CSV_HEADER + "\n" +
        "dup-prod,Dup Product,,,,,,,,,,,,,,,,,DUP-SKU-1,99.99,50,,,,TRUE,TRUE,,,,,,,\n" +
        "clean-skip-prod,Clean Skip Product,,,,,,,,,,,,,,,,,CLEAN-SKIP-SKU-1,10.00,10,,,,TRUE,TRUE,,,,,,,"
    )
    
    files = {"file": ("dup.csv", io.BytesIO(csv_content.encode("utf-8")), "text/csv")}
    data = {"conflict_strategy": "skip"}
    
    response = await client.post("/api/v1/products/import", files=files, data=data, headers=headers)
    job_id = response.json()["job_id"]
    
    for _ in range(10):
        await asyncio.sleep(0.3)
        job_resp = await client.get(f"/api/v1/products/import/{job_id}", headers=headers)
        if job_resp.json()["status"] in ("successful", "partial_success", "failed"):
            job_data = job_resp.json()
            break
            
    assert job_data["status"] == "partial_success"  # since one skipped duplicate row and one imported row
    assert job_data["rows_skipped"] == 1
    assert job_data["rows_processed"] == 1
    assert "skipped" in job_data["error_log"][0]["error"].lower()

@pytest.mark.asyncio
async def test_import_conflict_overwrite(client: AsyncClient, mock_firebase_user, db_session):
    """CSV-B-006: Upload with conflict_strategy=overwrite updates existing variant."""
    headers = {"Authorization": "Bearer valid_token"}
    
    async with AsyncSessionLocal() as db:
        prod = Product(
            tenant_id="t_abc",
            slug="ow-prod",
            title="OW Product",
            created_by="test_user"
        )
        db.add(prod)
        await db.flush()
        v = Variant(
            product_id=prod.product_id,
            tenant_id="t_abc",
            sku="OW-SKU-1",
            price=10.0,
        )
        db.add(v)
        await db.commit()

    csv_content = (
        CSV_HEADER + "\n" +
        "ow-prod,OW Product,,,,,,,,,,,,,,,,,OW-SKU-1,99.99,50,,,,TRUE,TRUE,,,,,,,"
    )
    
    files = {"file": ("ow.csv", io.BytesIO(csv_content.encode("utf-8")), "text/csv")}
    data = {"conflict_strategy": "overwrite"}
    
    response = await client.post("/api/v1/products/import", files=files, data=data, headers=headers)
    job_id = response.json()["job_id"]
    
    for _ in range(10):
        await asyncio.sleep(0.3)
        job_resp = await client.get(f"/api/v1/products/import/{job_id}", headers=headers)
        if job_resp.json()["status"] in ("successful", "partial_success", "failed"):
            job_data = job_resp.json()
            break
            
    assert job_data["status"] == "successful"
    assert job_data["rows_overwritten"] == 1
    
    # Verify updated in DB
    async with AsyncSessionLocal() as db:
        res = await db.execute(select(Variant).where(Variant.sku == "OW-SKU-1"))
        v_updated = res.scalar_one()
        assert float(v_updated.price) == 99.99

@pytest.mark.asyncio
async def test_import_conflict_custom_sku(client: AsyncClient, mock_firebase_user, db_session):
    """CSV-B-007: Upload with conflict_strategy=custom_sku renames duplicate SKU."""
    headers = {"Authorization": "Bearer valid_token"}
    
    async with AsyncSessionLocal() as db:
        prod = Product(
            tenant_id="t_abc",
            slug="cs-prod",
            title="CS Product",
            created_by="test_user"
        )
        db.add(prod)
        await db.flush()
        v = Variant(
            product_id=prod.product_id,
            tenant_id="t_abc",
            sku="CS-SKU-1",
            price=10.0,
        )
        db.add(v)
        await db.commit()

    csv_content = (
        CSV_HEADER + "\n" +
        "cs-prod,CS Product,,,,,,,,,,,,,,,,,CS-SKU-1,12.00,10,,,,TRUE,TRUE,,,,,,,"
    )
    
    files = {"file": ("cs.csv", io.BytesIO(csv_content.encode("utf-8")), "text/csv")}
    data = {
        "conflict_strategy": "custom_sku",
        "custom_sku_map_json": json.dumps({"CS-SKU-1": "CS-SKU-1-RENAMED"})
    }
    
    response = await client.post("/api/v1/products/import", files=files, data=data, headers=headers)
    job_id = response.json()["job_id"]
    
    for _ in range(10):
        await asyncio.sleep(0.3)
        job_resp = await client.get(f"/api/v1/products/import/{job_id}", headers=headers)
        if job_resp.json()["status"] in ("successful", "partial_success", "failed"):
            job_data = job_resp.json()
            break
            
    assert job_data["status"] == "successful"
    assert job_data["rows_custom_sku"] == 1
    
    # Verify new variant exists
    async with AsyncSessionLocal() as db:
        res = await db.execute(select(Variant).where(Variant.sku == "CS-SKU-1-RENAMED"))
        v_new = res.scalar_one_or_none()
        assert v_new is not None
        assert float(v_new.price) == 12.00

@pytest.mark.asyncio
async def test_import_validation_failures(client: AsyncClient, mock_firebase_user, db_session):
    """CSV-B-008, CSV-B-009, CSV-B-011, CSV-B-013: Verify error reporting and validation checks."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # Row 1: price < 0
    # Row 2: compare_at_price <= price
    # Row 3: missing Title (slug is present, but title is blank, which fails product validation)
    csv_content = (
        CSV_HEADER + "\n" +
        "bad-prod-1,Bad 1,,,,,,,,,,,,,,,,,BAD-SKU-1,-5.00,10,,,,TRUE,TRUE,,,,,,,\n" +
        "bad-prod-2,Bad 2,,,,,,,,,,,,,,,,,BAD-SKU-2,10.00,10,8.00,,,TRUE,TRUE,,,,,,,\n" +
        "bad-prod-3,,,,,,,,,,,,,,,,,,BAD-SKU-3,10.00,10,,,,TRUE,TRUE,,,,,,,"
    )
    
    files = {"file": ("bad.csv", io.BytesIO(csv_content.encode("utf-8")), "text/csv")}
    
    response = await client.post("/api/v1/products/import", files=files, headers=headers)
    job_id = response.json()["job_id"]
    
    for _ in range(10):
        await asyncio.sleep(0.3)
        job_resp = await client.get(f"/api/v1/products/import/{job_id}", headers=headers)
        if job_resp.json()["status"] in ("successful", "partial_success", "failed"):
            job_data = job_resp.json()
            break
            
    assert job_data["status"] == "failed"
    assert job_data["rows_failed"] == 3
    assert len(job_data["error_log"]) == 3
    
    errors = [e["error"] for e in job_data["error_log"]]
    assert any("price" in err.lower() for err in errors)
    assert any("compare_at_price" in err.lower() for err in errors)
    assert any("missing required field" in err.lower() for err in errors)

@pytest.mark.asyncio
async def test_import_no_stock_log(client: AsyncClient, mock_firebase_user, db_session):
    """CSV-B-012: Rows with no stock are logged to no_stock_log."""
    headers = {"Authorization": "Bearer valid_token"}
    
    csv_content = (
        CSV_HEADER + "\n" +
        "nostock-prod,No Stock Product,,,,,,,,,,,,,,,,,NOSTOCK-SKU,10.00,,,,,TRUE,TRUE,,,,,,,"
    )
    
    files = {"file": ("nostock.csv", io.BytesIO(csv_content.encode("utf-8")), "text/csv")}
    
    response = await client.post("/api/v1/products/import", files=files, headers=headers)
    job_id = response.json()["job_id"]
    
    for _ in range(10):
        await asyncio.sleep(0.3)
        job_resp = await client.get(f"/api/v1/products/import/{job_id}", headers=headers)
        if job_resp.json()["status"] in ("successful", "partial_success", "failed"):
            job_data = job_resp.json()
            break
            
    assert job_data["status"] == "successful"
    assert len(job_data["no_stock_log"]) == 1
    assert job_data["no_stock_log"][0]["sku"] == "NOSTOCK-SKU"

@pytest.mark.asyncio
async def test_import_unlimited_options(client: AsyncClient, mock_firebase_user, db_session):
    """CSV-B-014: Parse arbitrary option columns (e.g. Option7 Name/Value)."""
    headers = {"Authorization": "Bearer valid_token"}
    
    headers_with_7 = CSV_HEADER + ",Option7 Name,Option7 Value"
    csv_content = (
        headers_with_7 + "\n" +
        "opt-prod,Opt Product,,,,,,,,,,,,,,,,,OPT-SKU-1,10.00,10,,,,TRUE,TRUE,Color,Red,Size,M,,,Heat,High"
    )
    
    files = {"file": ("options.csv", io.BytesIO(csv_content.encode("utf-8")), "text/csv")}
    
    response = await client.post("/api/v1/products/import", files=files, headers=headers)
    job_id = response.json()["job_id"]
    
    for _ in range(10):
        await asyncio.sleep(0.3)
        job_resp = await client.get(f"/api/v1/products/import/{job_id}", headers=headers)
        if job_resp.json()["status"] in ("successful", "partial_success", "failed"):
            job_data = job_resp.json()
            break
            
    assert job_data["status"] == "successful"
    
    # Verify DB product schema & variant option values
    async with AsyncSessionLocal() as db:
        res_prod = await db.execute(select(Product).where(Product.slug == "opt-prod"))
        prod = res_prod.scalar_one()
        assert any(o["name"] == "Heat" for o in prod.options_schema)
        
        res_var = await db.execute(select(Variant).where(Variant.sku == "OPT-SKU-1"))
        var = res_var.scalar_one()
        assert var.option_values["Heat"] == "High"

@pytest.mark.asyncio
async def test_import_history_endpoint(client: AsyncClient, mock_firebase_user, db_session):
    """CSV-B-015: History endpoint returns jobs for tenant sorted by date desc."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # Create two jobs
    async with AsyncSessionLocal() as db:
        job1 = ImportJob(
            tenant_id="t_abc",
            status="successful",
            created_at=datetime(2026, 6, 1)
        )
        job2 = ImportJob(
            tenant_id="t_abc",
            status="failed",
            created_at=datetime(2026, 6, 2)
        )
        db.add(job1)
        db.add(job2)
        await db.commit()
        
    response = await client.get("/api/v1/products/import/history", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 2
    # Newest first
    assert data[0]["status"] == "failed"
    assert data[1]["status"] == "successful"

@pytest.mark.asyncio
async def test_import_xlsx_file(client: AsyncClient, mock_firebase_user, db_session):
    """CSV-B-016: Parse XLSX file bytes successfully."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # Create XLSX in-memory
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.append(CSV_HEADER.split(","))
    ws.append([
        "xlsx-prod", "XLSX Product", "Desc", "draft", "", "",
        "FALSE", "FALSE", "TRUE", "", "", "", "", "", "",
        "FALSE", "", "FALSE",
        "XLSX-SKU-1", "12.50", "15", "", "",
        "", "TRUE", "TRUE",
        "Color", "Green", "", "", "", ""
    ])
    
    xlsx_bytes = io.BytesIO()
    wb.save(xlsx_bytes)
    xlsx_bytes.seek(0)
    
    files = {"file": ("xlsx_products.xlsx", xlsx_bytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")}
    
    response = await client.post("/api/v1/products/import", files=files, headers=headers)
    assert response.status_code == 202
    job_id = response.json()["job_id"]
    
    for _ in range(10):
        await asyncio.sleep(0.3)
        job_resp = await client.get(f"/api/v1/products/import/{job_id}", headers=headers)
        if job_resp.json()["status"] in ("successful", "partial_success", "failed"):
            job_data = job_resp.json()
            break
            
    assert job_data["status"] == "successful"
    assert job_data["rows_total"] == 1
    assert job_data["rows_processed"] == 1
