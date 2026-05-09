import pytest
from httpx import AsyncClient
from main import app
from modules.orders.models import Order
from modules.auth.models import ConsumerUser
from sqlalchemy import select

@pytest.mark.anyio
async def test_register_consumer_links_order(client: AsyncClient, db_session, mock_firebase_auth):
    # 1. Setup: Create a guest order
    tenant_id = "test-tenant"
    order_id = "ORD-LINK-001"
    
    guest_order = Order(
        order_id=order_id,
        order_number="KS-TEST-001",
        tenant_id=tenant_id,
        email="guest@example.com",
        subtotal=100.0,
        grand_total=100.0,
        currency="USD",
        payment_status="paid",
        shipping_name="John Doe",
        shipping_address1="123 Guest St"
    )
    db_session.add(guest_order)
    await db_session.commit()

    # 2. Execute: Register consumer with this order_id
    registration_data = {
        "email": "guest@example.com",
        "password": "securepassword123",
        "tenant_id": tenant_id,
        "full_name": "John Doe",
        "shipping_address": {"address1": "123 Guest St"},
        "order_id": order_id
    }
    
    # We mock firebase_admin.auth to avoid real API calls
    # For now, we assume the environment has mocks or we just check the DB logic
    response = await client.post("/api/v1/auth/consumers/register", json=registration_data)
    
    # Assert
    assert response.status_code == 201
    
    # 3. Verify: Check if order is linked in DB
    result = await db_session.execute(select(Order).where(Order.order_id == order_id))
    updated_order = result.scalar_one()
    assert updated_order.consumer_id is not None
    
    # Verify consumer profile
    result = await db_session.execute(select(ConsumerUser).where(ConsumerUser.email == "guest@example.com"))
    consumer = result.scalar_one()
    assert consumer.full_name == "John Doe"
    assert consumer.uid == updated_order.consumer_id
