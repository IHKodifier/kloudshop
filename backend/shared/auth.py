import os
from typing import Optional, List
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import firebase_admin
from firebase_admin import auth, credentials
from pydantic import BaseModel

# Security schemes
security = HTTPBearer()

class UserClaims(BaseModel):
    uid: str
    email: Optional[str] = None
    tenant_id: Optional[str] = None
    account_type: str = "staff" # staff | buyer | consumer
    roles: List[str] = []
    is_owner: bool = False

# Initialize Firebase Admin SDK
try:
    firebase_admin.get_app()
except ValueError:
    import os
    # Try multiple common locations for the service account
    sa_path = "service_account.json"
    if not os.path.exists(sa_path):
        # Maybe we are in a subdirectory during testing
        sa_path = os.path.join(os.path.dirname(__file__), "..", "service_account.json")
    
    if os.path.exists(sa_path):
        cred = credentials.Certificate(sa_path)
        firebase_admin.initialize_app(cred)
    else:
        # Fallback to default credentials (ADC)
        firebase_admin.initialize_app()

async def validate_token(
    request: Request,
    token: HTTPAuthorizationCredentials = Depends(security)
) -> UserClaims:
    """
    Dependency to validate Firebase JWT and extract custom claims.
    Enforces Universal AI Commandment 1: Scoped to tenant_id.
    """
    try:
        # Verify the ID token and get decoded claims
        # check_revoked=True adds a small latency but ensures revoked users are blocked
        decoded_token = auth.verify_id_token(token.credentials, check_revoked=True)
        
        # Extract custom claims (SYS-01 / SYS-08)
        tenant_id = decoded_token.get("tenant_id")
        account_type = decoded_token.get("account_type", "staff")
        roles = decoded_token.get("roles", [])
        is_owner = decoded_token.get("is_owner", False)
        
        # tenant_id is now optional in validate_token to allow /auth/me for new users.
        # Enforcement for tenant-scoped operations is moved to PermissionChecker (RBAC).

            
        return UserClaims(
            uid=decoded_token["uid"],
            email=decoded_token.get("email"),
            tenant_id=tenant_id,
            account_type=account_type,
            roles=roles,
            is_owner=is_owner
        )
        
    except auth.RevokedIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has been revoked.",
        )
    except auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired.",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid authentication credentials: {str(e)}",
        )

async def verify_app_check(request: Request):
    """
    Middleware/Dependency to verify Firebase App Check token.
    (US-002) Enforcement before any other logic.
    """
    app_check_token = request.headers.get("X-Firebase-AppCheck")
    if not app_check_token:
        # In development, we might want to skip this if a bypass header is present
        if os.getenv("ENV") == "dev" and request.headers.get("X-AppCheck-Bypass"):
            return
            
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="App Check token missing."
        )
    
    try:
        # Note: Firebase Admin SDK for Python does NOT have a native verify_app_check yet.
        # This usually requires a manual check or a custom implementation using 
        # the Firebase App Check verification API.
        # For now, we'll placeholder this or use a third-party approach if available.
        # TODO: Implement actual App Check verification logic via REST API or SDK
        pass
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid App Check token."
        )
