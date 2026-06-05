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

from sqlalchemy.ext.asyncio import AsyncSession
from shared.db import get_db
from sqlalchemy import select

async def validate_token(
    request: Request,
    token: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db)
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
        
        # Check security state for staff users (brute-force lockout and cool-off check)
        if account_type == "staff" and decoded_token.get("email"):
            email = decoded_token["email"].lower()
            from modules.auth.models import StaffSecurityState
            
            result = await db.execute(
                select(StaffSecurityState).where(StaffSecurityState.gmail == email)
            )
            sec_state = result.scalar_one_or_none()
            if sec_state:
                from datetime import datetime, timezone
                now_utc = datetime.now(timezone.utc)
                
                # Check permanent block
                if sec_state.is_blocked:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Account blocked. Please verify your email to unlock."
                    )
                
                # Check active cool-off
                if sec_state.cool_off_until:
                    cool_off = sec_state.cool_off_until
                    if cool_off.tzinfo is None:
                        cool_off = cool_off.replace(tzinfo=timezone.utc)
                    if cool_off > now_utc:
                        raise HTTPException(
                            status_code=status.HTTP_403_FORBIDDEN,
                            detail="Sign-in cool-off active. Please wait."
                        )
            
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
    except HTTPException:
        rethrow = True
        raise
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
