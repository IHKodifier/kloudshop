import json
import logging
from datetime import datetime, timezone
from typing import Dict, Any, Optional

logger = logging.getLogger("analytics")

async def track_event(
    tenant_id: str,
    event_type: str,
    data: Dict[str, Any],
    visitor_id: Optional[str] = None,
    user_id: Optional[str] = None
):
    """
    Track an event for BigQuery sync.
    In production, this would publish to Pub/Sub.
    For now, it logs to stdout for the Dataflow pipeline to pick up or for debugging.
    """
    event = {
        "tenant_id": tenant_id,
        "event_type": event_type,
        "event_timestamp": datetime.now(timezone.utc).isoformat(),
        "visitor_id": visitor_id,
        "user_id": user_id,
        "data": data
    }
    
    # Mocking Pub/Sub publish for Sprint 14
    # In a real GCP environment, this would use google-cloud-pubsub
    logger.info(f"ANALYTICS_EVENT: {json.dumps(event)}")
    
    # For testing purposes, we can also print to console
    print(f"ANALYTICS_EVENT: {event_type} for tenant {tenant_id}")
