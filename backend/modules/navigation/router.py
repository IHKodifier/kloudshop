from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Dict, Optional

from shared.db import get_db
from shared.auth import UserClaims, validate_token
from modules.catalog.models import Product, Collection
from modules.storefront.models import StaticPage
from modules.policies.models import StorePolicy
from .models import StoreNavigationMenu, StoreNavigationItem
from .schemas import (
    NavigationMenuCreate, NavigationMenuResponse,
    NavigationItemCreate, NavigationItemResponse, NavigationItemTreeResponse,
    NavigationReorderRequest, LinkResolveResponse
)

router = APIRouter(tags=["Navigation"])

def build_menu_tree(items: List[StoreNavigationItem]) -> List[NavigationItemTreeResponse]:
    # 1. Map db items to Pydantic tree models
    node_map: Dict[str, NavigationItemTreeResponse] = {}
    for item in items:
        # Convert to dictionary and unpack, then create model
        # We manually convert to handle relationships
        node = NavigationItemTreeResponse(
            item_id=item.item_id,
            menu_id=item.menu_id,
            tenant_id=item.tenant_id,
            parent_id=item.parent_id,
            title=item.title,
            url=item.url,
            link_type=item.link_type,
            resource_id=item.resource_id,
            position=item.position,
            children=[]
        )
        node_map[item.item_id] = node

    # 2. Build tree structure
    root_nodes = []
    for item in items:
        node = node_map[item.item_id]
        if item.parent_id and item.parent_id in node_map:
            node_map[item.parent_id].children.append(node)
        else:
            root_nodes.append(node)

    # 3. Sort nodes by position
    def sort_tree(nodes: List[NavigationItemTreeResponse]):
        nodes.sort(key=lambda x: x.position)
        for node in nodes:
            sort_tree(node.children)

    sort_tree(root_nodes)
    return root_nodes

# --- Menu CRUD ---

@router.post("/menus", response_model=NavigationMenuResponse, status_code=status.HTTP_201_CREATED)
async def create_menu(
    req: NavigationMenuCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="Tenant ID missing")

    # Check for duplicate handles
    dup_res = await db.execute(
        select(StoreNavigationMenu).where(StoreNavigationMenu.tenant_id == user.tenant_id, StoreNavigationMenu.handle == req.handle)
    )
    if dup_res.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Menu with this handle already exists")

    menu = StoreNavigationMenu(
        tenant_id=user.tenant_id,
        name=req.name,
        handle=req.handle
    )
    db.add(menu)
    await db.commit()
    await db.refresh(menu)

    return NavigationMenuResponse(
        menu_id=menu.menu_id,
        tenant_id=menu.tenant_id,
        name=menu.name,
        handle=menu.handle,
        items=[]
    )

@router.get("/menus", response_model=List[NavigationMenuResponse])
async def list_menus(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="Tenant ID missing")

    menus_res = await db.execute(
        select(StoreNavigationMenu).where(StoreNavigationMenu.tenant_id == user.tenant_id)
    )
    menus = menus_res.scalars().all()

    # Load all items for these menus in a single query
    menu_ids = [m.menu_id for m in menus]
    items_res = await db.execute(
        select(StoreNavigationItem).where(StoreNavigationItem.menu_id.in_(menu_ids))
    )
    all_items = items_res.scalars().all()

    # Group items by menu_id
    items_by_menu = {}
    for item in all_items:
        if item.menu_id not in items_by_menu:
            items_by_menu[item.menu_id] = []
        items_by_menu[item.menu_id].append(item)

    response = []
    for menu in menus:
        menu_items = items_by_menu.get(menu.menu_id, [])
        tree = build_menu_tree(menu_items)
        response.append(NavigationMenuResponse(
            menu_id=menu.menu_id,
            tenant_id=menu.tenant_id,
            name=menu.name,
            handle=menu.handle,
            items=tree
        ))
    return response

@router.get("/menus/{menu_id}", response_model=NavigationMenuResponse)
async def get_menu(
    menu_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    menu_res = await db.execute(
        select(StoreNavigationMenu).where(StoreNavigationMenu.menu_id == menu_id, StoreNavigationMenu.tenant_id == user.tenant_id)
    )
    menu = menu_res.scalar_one_or_none()
    if not menu:
        raise HTTPException(status_code=404, detail="Navigation menu not found")

    items_res = await db.execute(
        select(StoreNavigationItem).where(StoreNavigationItem.menu_id == menu_id)
    )
    menu_items = items_res.scalars().all()
    tree = build_menu_tree(menu_items)

    return NavigationMenuResponse(
        menu_id=menu.menu_id,
        tenant_id=menu.tenant_id,
        name=menu.name,
        handle=menu.handle,
        items=tree
    )

@router.delete("/menus/{menu_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_menu(
    menu_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    menu_res = await db.execute(
        select(StoreNavigationMenu).where(StoreNavigationMenu.menu_id == menu_id, StoreNavigationMenu.tenant_id == user.tenant_id)
    )
    menu = menu_res.scalar_one_or_none()
    if not menu:
        raise HTTPException(status_code=404, detail="Navigation menu not found")
    
    await db.delete(menu)
    await db.commit()
    return None

# --- Item CRUD ---

@router.post("/menus/{menu_id}/items", response_model=NavigationItemResponse, status_code=status.HTTP_201_CREATED)
async def create_navigation_item(
    menu_id: str,
    req: NavigationItemCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    # Verify menu exists
    menu_res = await db.execute(
        select(StoreNavigationMenu).where(StoreNavigationMenu.menu_id == menu_id, StoreNavigationMenu.tenant_id == user.tenant_id)
    )
    if not menu_res.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Navigation menu not found")

    # Verify parent item exists if provided
    if req.parent_id:
        parent_res = await db.execute(
            select(StoreNavigationItem).where(StoreNavigationItem.item_id == req.parent_id, StoreNavigationItem.menu_id == menu_id)
        )
        if not parent_res.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Parent navigation item not found in this menu")

    item = StoreNavigationItem(
        menu_id=menu_id,
        tenant_id=user.tenant_id,
        parent_id=req.parent_id,
        title=req.title,
        url=req.url,
        link_type=req.link_type,
        resource_id=req.resource_id,
        position=req.position
    )
    db.add(item)
    await db.commit()
    await db.refresh(item)
    return item

@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_navigation_item(
    item_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    item_res = await db.execute(
        select(StoreNavigationItem).where(StoreNavigationItem.item_id == item_id, StoreNavigationItem.tenant_id == user.tenant_id)
    )
    item = item_res.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Navigation item not found")

    await db.delete(item)
    await db.commit()
    return None

# --- Reordering Endpoint ---

@router.post("/menus/{menu_id}/reorder", status_code=status.HTTP_200_OK)
async def reorder_menu_items(
    menu_id: str,
    req: NavigationReorderRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    # Verify menu exists
    menu_res = await db.execute(
        select(StoreNavigationMenu).where(StoreNavigationMenu.menu_id == menu_id, StoreNavigationMenu.tenant_id == user.tenant_id)
    )
    if not menu_res.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Navigation menu not found")

    # Fetch all items in this menu to map and validate
    items_res = await db.execute(
        select(StoreNavigationItem).where(StoreNavigationItem.menu_id == menu_id)
    )
    items_map = {item.item_id: item for item in items_res.scalars().all()}

    # Update parent_id and positions
    for reorder_info in req.items:
        item = items_map.get(reorder_info.item_id)
        if not item:
            raise HTTPException(status_code=400, detail=f"Navigation item {reorder_info.item_id} not found in this menu")
        
        # Verify parent_id is valid in this menu
        if reorder_info.parent_id and reorder_info.parent_id not in items_map:
            raise HTTPException(status_code=400, detail=f"Parent item {reorder_info.parent_id} not found in this menu")

        item.parent_id = reorder_info.parent_id
        item.position = reorder_info.position

    await db.commit()
    return {"message": "Navigation menu items reordered successfully"}

# --- Polymorphic Route Resolver ---

@router.get("/resolve", response_model=LinkResolveResponse)
async def resolve_navigation_link(
    link_type: str,
    resource_id: Optional[str] = None,
    custom_url: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="Tenant ID missing")

    if link_type == "custom" or not resource_id:
        return LinkResolveResponse(
            relative_url=custom_url or "/",
            title="Custom Link"
        )

    if link_type == "product":
        prod_res = await db.execute(
            select(Product).where(Product.product_id == resource_id, Product.tenant_id == user.tenant_id)
        )
        product = prod_res.scalar_one_or_none()
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")
        return LinkResolveResponse(
            relative_url=f"/products/{product.slug}",
            title=product.title
        )

    elif link_type == "collection":
        coll_res = await db.execute(
            select(Collection).where(Collection.collection_id == resource_id, Collection.tenant_id == user.tenant_id)
        )
        collection = coll_res.scalar_one_or_none()
        if not collection:
            raise HTTPException(status_code=404, detail="Collection not found")
        return LinkResolveResponse(
            relative_url=f"/collections/{collection.slug}",
            title=collection.title
        )

    elif link_type == "page":
        # Search page in static_pages
        page_res = await db.execute(
            select(StaticPage).where(StaticPage.page_id == resource_id, StaticPage.tenant_id == user.tenant_id)
        )
        page = page_res.scalar_one_or_none()
        if not page:
            raise HTTPException(status_code=404, detail="Static page not found")
        return LinkResolveResponse(
            relative_url=f"/pages/{page.slug}",
            title=page.title
        )

    elif link_type == "policy":
        policy_res = await db.execute(
            select(StorePolicy).where(StorePolicy.policy_id == resource_id, StorePolicy.tenant_id == user.tenant_id)
        )
        policy = policy_res.scalar_one_or_none()
        if not policy:
            raise HTTPException(status_code=404, detail="Store policy not found")
        return LinkResolveResponse(
            relative_url=f"/policies/{policy.policy_type}",
            title=f"{policy.policy_type.replace('_', ' ').title()} Policy"
        )

    else:
        raise HTTPException(status_code=400, detail="Invalid link_type specified")
