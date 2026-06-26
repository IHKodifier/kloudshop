import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from modules.navigation.models import StoreNavigationMenu, StoreNavigationItem
from modules.catalog.models import Product, Collection
from modules.storefront.models import StaticPage
from modules.policies.models import StorePolicy

@pytest.mark.asyncio
async def test_navigation_reorder_and_resolver(client: AsyncClient, mock_firebase_user, db_session: AsyncSession):
    headers = {"Authorization": "Bearer valid_token"}

    # 1. Create a menu
    menu_resp = await client.post("/api/v1/navigation/menus", json={"name": "Header Menu", "handle": "header"}, headers=headers)
    assert menu_resp.status_code == 201
    menu_id = menu_resp.json()["menu_id"]

    # 2. Add navigation items
    item1_resp = await client.post(
        f"/api/v1/navigation/menus/{menu_id}/items",
        json={"title": "Home", "url": "/", "link_type": "custom", "position": 0},
        headers=headers
    )
    item1_id = item1_resp.json()["item_id"]

    item2_resp = await client.post(
        f"/api/v1/navigation/menus/{menu_id}/items",
        json={"title": "Shop", "url": "/collections/all", "link_type": "custom", "position": 1},
        headers=headers
    )
    item2_id = item2_resp.json()["item_id"]

    # 3. Add sub-item under Shop (item2_id)
    item3_resp = await client.post(
        f"/api/v1/navigation/menus/{menu_id}/items",
        json={"title": "New Arrivals", "url": "/collections/new", "link_type": "custom", "position": 0, "parent_id": item2_id},
        headers=headers
    )
    item3_id = item3_resp.json()["item_id"]

    # Retrieve menu and verify tree structure
    menu_get = await client.get(f"/api/v1/navigation/menus/{menu_id}", headers=headers)
    assert menu_get.status_code == 200
    menu_data = menu_get.json()
    assert len(menu_data["items"]) == 2 # Home and Shop
    shop_item = next(i for i in menu_data["items"] if i["item_id"] == item2_id)
    assert len(shop_item["children"]) == 1
    assert shop_item["children"][0]["item_id"] == item3_id

    # 4. Test reordering: move Home (item1_id) to be under Shop (item2_id) at position 1
    reorder_payload = {
        "items": [
            {"item_id": item1_id, "parent_id": item2_id, "position": 1},
            {"item_id": item2_id, "parent_id": None, "position": 0},
            {"item_id": item3_id, "parent_id": item2_id, "position": 0}
        ]
    }
    reorder_resp = await client.post(f"/api/v1/navigation/menus/{menu_id}/reorder", json=reorder_payload, headers=headers)
    assert reorder_resp.status_code == 200

    # Retrieve menu and verify reordered tree structure
    menu_get_after = await client.get(f"/api/v1/navigation/menus/{menu_id}", headers=headers)
    after_data = menu_get_after.json()
    assert len(after_data["items"]) == 1 # Only Shop is at root now
    root_shop = after_data["items"][0]
    assert root_shop["item_id"] == item2_id
    assert len(root_shop["children"]) == 2
    assert root_shop["children"][0]["item_id"] == item3_id # position 0
    assert root_shop["children"][1]["item_id"] == item1_id # position 1

    # 5. Seed a product, collection, page, policy for resolver test
    product = Product(tenant_id="t_abc", title="Super Widget", slug="super-widget", created_by="staff_1")
    collection = Collection(tenant_id="t_abc", title="Summer Gear", slug="summer-gear")
    page = StaticPage(tenant_id="t_abc", title="About Us", slug="about-us", body={"html": "We are KloudShop."}, status="published", created_by="staff_1")
    policy = StorePolicy(tenant_id="t_abc", policy_type="refund", draft_content="Refund policy", published_content="Refund policy", is_active=True, version=1)
    
    db_session.add_all([product, collection, page, policy])
    await db_session.commit()
    await db_session.refresh(product)
    await db_session.refresh(collection)
    await db_session.refresh(page)
    await db_session.refresh(policy)

    # 6. Test Resolver
    # Product resolve
    r_prod = await client.get(f"/api/v1/navigation/resolve?link_type=product&resource_id={product.product_id}", headers=headers)
    assert r_prod.status_code == 200
    assert r_prod.json()["relative_url"] == "/products/super-widget"
    assert r_prod.json()["title"] == "Super Widget"

    # Collection resolve
    r_coll = await client.get(f"/api/v1/navigation/resolve?link_type=collection&resource_id={collection.collection_id}", headers=headers)
    assert r_coll.status_code == 200
    assert r_coll.json()["relative_url"] == "/collections/summer-gear"
    assert r_coll.json()["title"] == "Summer Gear"

    # Page resolve
    r_page = await client.get(f"/api/v1/navigation/resolve?link_type=page&resource_id={page.page_id}", headers=headers)
    assert r_page.status_code == 200
    assert r_page.json()["relative_url"] == "/pages/about-us"
    assert r_page.json()["title"] == "About Us"

    # Policy resolve
    r_poly = await client.get(f"/api/v1/navigation/resolve?link_type=policy&resource_id={policy.policy_id}", headers=headers)
    assert r_poly.status_code == 200
    assert r_poly.json()["relative_url"] == "/policies/refund"
    assert r_poly.json()["title"] == "Refund Policy"

    # Custom url resolve
    r_cust = await client.get("/api/v1/navigation/resolve?link_type=custom&custom_url=/contact", headers=headers)
    assert r_cust.status_code == 200
    assert r_cust.json()["relative_url"] == "/contact"
