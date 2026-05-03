import logging
from typing import List, Optional

logger = logging.getLogger("notifications")

async def send_b2b_approval_notification(tenant_id: str, order_id: str, grand_total: float, approver_roles: List[str]):
    """
    Sends FCM notifications to staff members who have the necessary roles for approval.
    """
    message = f"B2B Order {order_id} requires approval. Total: {grand_total}"
    # Log the notification (placeholder for actual FCM logic)
    print(f"--- [FCM NOTIFICATION MOCK] ---")
    print(f"Tenant: {tenant_id}")
    print(f"Order: {order_id}")
    print(f"Amount: {grand_total}")
    print(f"Message: {message}")
    print(f"Target Roles: {approver_roles}")
    print(f"-------------------------------")
    
    logger.info(f"[FCM MOCK] Sent to roles {approver_roles} for tenant {tenant_id}")
