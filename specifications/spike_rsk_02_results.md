# Spike RSK-02 Results: Wildcard SSL Two-Level Validation

## 1. Problem Statement
KloudShop requires multi-level subdomains for the "Hybrid" tier (e.g., `wholesale.acmeco.kloudshop.biz`). However, standard SSL wildcards (GCP Managed Certs / Let's Encrypt) only support a single level of wildcards (`*.kloudshop.biz`).

## 2. Options Evaluated

| Option | Strategy | Subdomain Pattern | Cost | Complexity |
| :--- | :--- | :--- | :--- | :--- |
| **A** | **Flat (MVP)** | `acmeco-wholesale.kloudshop.biz` | $0 | Low |
| **B** | **Nested (Production)** | `wholesale.acmeco.kloudshop.biz` | $10/mo (Cloudflare) | Medium |

## 3. Decision
- **Pre-Launch/Dev:** Use **Option A (Flat)** to maintain zero infrastructure cost.
- **Post-Launch:** Transition to **Option B (Nested)** using Cloudflare's Advanced Certificate Manager ($10/mo flat for the entire `kloudshop.biz` zone).

## 4. Zero-Friction Transition Strategy
To ensure the switch from Option A to Option B is "config-only," the Backend routing logic (FastAPI) must use a flexible parser.

### Implementation Logic (Backend):
The `SubdomainMiddleware` will use a regex/delimiter strategy controlled by an environment variable.

```python
# Conceptual Subdomain Parsing Logic
SUBDOMAIN_STRATEGY = os.getenv("SUBDOMAIN_STRATEGY", "FLAT") # FLAT or NESTED

def parse_subdomain(host: str):
    subdomain = host.split(".kloudshop.biz")[0]
    
    if SUBDOMAIN_STRATEGY == "NESTED":
        # wholesale.acmeco
        parts = subdomain.split(".")
        sub_brand = parts[0] if len(parts) > 1 else None
        tenant_slug = parts[1] if len(parts) > 1 else parts[0]
    else:
        # acmeco-wholesale
        parts = subdomain.split("-")
        tenant_slug = parts[0]
        sub_brand = parts[1] if len(parts) > 1 else None
        
    return tenant_slug, sub_brand
```

### 5. Custom Domains
Merchant-owned custom domains (e.g., `acmeco.com`) are unaffected by this limitation. A single wildcard cert for `*.acmeco.com` correctly covers both `www.acmeco.com` and `wholesale.acmeco.com`.
