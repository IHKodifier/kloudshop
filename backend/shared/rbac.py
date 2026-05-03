from typing import List, Set
from fastapi import Depends, HTTPException, status
from .auth import UserClaims, validate_token

# Define Permissions
MERCHANT_PERMISSIONS = {
    "catalog:read", "catalog:write",
    "orders:read", "orders:write",
    "inventory:read", "inventory:write",
    "supplier:read", "supplier:write",
    "po:read", "po:write",
    "storefront:read", "storefront:write",
    "settings:read", "settings:write",
    "billing:read", "billing:write", "billing:manage",
    "users:read", "users:write",
    "auth:invite", "auth:revoke",
    "features:read", "features:write",
}

PLATFORM_PERMISSIONS = {
    "internal:provision",
    "admin:platform",
}

# Role-to-Permission Mapping
ROLE_PERMISSIONS = {
    "owner": MERCHANT_PERMISSIONS, # Full merchant access
    "admin": MERCHANT_PERMISSIONS, # Full merchant access
    "store_manager": {
        "catalog:read", "catalog:write",
        "orders:read", "orders:write",
        "inventory:read", "inventory:write",
        "supplier:read", "supplier:write",
        "po:read", "po:write",
        "settings:read",
    },
    "inventory_manager": {
        "catalog:read", "catalog:write",
        "inventory:read", "inventory:write",
        "supplier:read", "supplier:write",
        "po:read", "po:write",
    },
    "customer_support": {
        "catalog:read",
        "orders:read", "orders:write",
        "users:read",
    },
    "b2b_account_manager": {
        "catalog:read",
        "orders:read", "orders:write",
        "users:read", "users:write",
    },
    "buyer": {
        "catalog:read",
        "orders:read", "orders:write",
    },
    "consumer": {
        "orders:read",
    },
    "platform_admin": PLATFORM_PERMISSIONS
}

class PermissionChecker:
    def __init__(self, required_permissions: List[str]):
        self.required_permissions = required_permissions

    def __call__(self, user: UserClaims = Depends(validate_token)):
        # Ensure tenant_id is present for tenant-scoped operations
        if not user.tenant_id and user.account_type != "platform_admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Tenant context required for this operation."
            )

        user_permissions: Set[str] = set()
        
        # Owners automatically get all merchant-level permissions
        if user.is_owner:
            user_permissions.update(MERCHANT_PERMISSIONS)

        # Add permissions from assigned roles
        for role in user.roles:
            permissions = ROLE_PERMISSIONS.get(role, set())
            user_permissions.update(permissions)

        # Check if all required permissions are met
        missing_permissions = [p for p in self.required_permissions if p not in user_permissions]
        
        if missing_permissions:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Missing required permissions: {', '.join(missing_permissions)}"
            )
            
        return user

def has_permissions(permissions: List[str]):
    return Depends(PermissionChecker(permissions))
