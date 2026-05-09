import pytest
from httpx import AsyncClient
from shared.auth import UserClaims
from modules.orders.models import Order
from sqlalchemy import select

@pytest.mark.anyio
async def test_consumer_list_orders(client: AsyncClient, db_session, auth_override):
    # Setup
    consumer_uid = "consumer_123"
    auth_override(UserClaims(uid=consumer_uid, account_type="consumer"))
    
    order = Order(
        order_number="KS-101",
        tenant_id="t1",
        consumer_id=consumer_uid,
        email="consumer@example.com",
        subtotal=50.0,
        grand_total=55.0,
        payment_status="paid",
        fulfilment_status="unfulfilled"
    )
    db_session.add(order)
    
    other_order = Order(
        order_number="KS-102",
        tenant_id="t1",
        consumer_id="other_uid",
        email="other@example.com",
        subtotal=50.0,
        grand_total=55.0,
        payment_status="paid",
        fulfilment_status="unfulfilled"
    )
    db_session.add(other_order)
    await db_session.commit()

    # Execute
    response = await client.get("/api/v1/orders/consumer/orders")
    
    # Assert
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["order_number"] == "KS-101"

@pytest.mark.anyio
async def test_consumer_request_return(client: AsyncClient, db_session, auth_override):
    # Setup
    consumer_uid = "consumer_123"
    auth_override(UserClaims(uid=consumer_uid, account_type="consumer"))
    
    order = Order(
        order_number="KS-103",
        tenant_id="t1",
        consumer_id=consumer_uid,
        email="consumer@example.com",
        subtotal=50.0,
        grand_total=55.0,
        payment_status="paid",
        fulfilment_status="delivered" # Must be delivered to return
    )
    db_session.add(order)
    await db_session.commit()
    await db_session.refresh(order)

    # Execute
    return_data = {
        "reason": "Size too small",
        "items": [{"variant_id": "v1", "quantity": 1}],
        "description": "Please refund to original card"
    }
    response = await client.post(f"/api/v1/orders/consumer/orders/{order.order_id}/return", json=return_data)
    
    # Assert
    assert response.status_code == 200
    data = response.json()
    
    # Verify event was created
    assert any(e["event_type"] == "return_requested" for e in data["events"])
    assert "Size too small" in data["events"][-1]["description"]
