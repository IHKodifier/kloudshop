# Architecture Pivot Audit: Pure API (FastAPI) vs Hybrid (FDC)

## 1. Assessment of the Pure API-Only Approach
Transitioning from a hybrid architecture (where Flutter communicates directly with the database for CRUD via Firebase Data Connect) to a **Pure API-only approach** (where Flutter communicates exclusively with Python FastAPI for *all* operations) is a highly strategic move, especially when utilizing AI agents and TDD.

### Weighing the Implications

| Aspect | Assessment |
| :--- | :--- |
| **Industry Best Practices** | **Significantly Improved.** The hybrid approach risks creating a "fat client" where business rules leak into the frontend. The Pure API approach adheres to classic 3-tier architecture (Client -> App Server -> Database). It prevents vendor lock-in (FDC is highly proprietary) and uses universally understood standards (REST/GraphQL via Python). |
| **App Security** | **Significantly Improved.** Security is centralized. In the hybrid model, RBAC and row-level security are split between FDC `@auth` rules and FastAPI code. In a Pure API model, 100% of authentication (Firebase JWTs) and authorization (RBAC) happens in your Python middleware. There is a single, impenetrable gatekeeper (FastAPI) backed by Firebase App Check. |
| **Maintainability & TDD** | **Massively Improved.** Because you specified Test-Driven Development (TDD) and AI hand-offs, a Pure API is superior. You can easily write `pytest` suites to mock and test FastAPI endpoints. Testing Firebase Data Connect requires complex emulator setups. Furthermore, having a single language (Python) for *all* backend logic ensures your AI agents don't get confused juggling FDC GraphQL schemas versus SQLAlchemy models. |
| **Dev Time & Cost** | **Slight Initial Increase / Long-term Decrease.** FDC's main selling point is saving time by auto-generated frontend SDKs. By removing it, the AI agents will have to manually write FastAPI CRUD routers, Pydantic schemas, and Flutter HTTP/Dio clients. *However*, because AI agents excel at writing boilerplate code, this penalty is negligible. Long-term, dev time decreases because debugging a single API layer is much faster than debugging a hybrid split. Cost also decreases as you don't need to provision or monitor the FDC service. |

---

## 2. Surgical Update Plan (Downstream Artifacts)

If we lock in this decision, the following artifacts must be surgically updated to purge Firebase Data Connect and establish FastAPI + SQLAlchemy as the sole backend authority.

### A. Architectural & Stack Artifacts
1. **`01b-tech-stack.md`**
   * **Action:** Remove all references to Firebase Data Connect (FDC). 
   * **Update:** Explicitly define that Cloud SQL is accessed *exclusively* via Python (using an ORM like SQLAlchemy or SQLModel + `asyncpg`). Define the API communication protocol (REST or GraphQL via Strawberry/FastAPI) for the Flutter client.
2. **`00-carry-forward-flags.md` & `04b-mvp-scope.md`**
   * **Action:** Ensure any notes relying on FDC auto-generation are removed and replaced with standard API endpoint development tasks.

### B. Schema Artifacts (`06` Series)
The `06-*.md` series files have already been successfully written and validated in **standard PostgreSQL DDL** syntax. The previous Hybrid FDC approach has been fully excised from the data models.
1. **`06a` through `06p`**
   * **Status:** ✅ Complete. Already converted to PostgreSQL DDL.
   * **Next Step:** AI agents will use these DDL files as the source of truth to write **Python SQLAlchemy classes** and **Pydantic models** in the `/backend` directory during Sprint execution.
2. **`06o-index-strategy.md`**
   * **Action:** Ensure the indexes are defined as SQLAlchemy/Alembic migration instructions during the infrastructure phase.

### C. Execution & Roadmap Artifacts
1. **`07-development-roadmap.md`**
   * **Action:** Update the Sprints. Remove references to "Defining FDC Schemas" or "Generating FDC SDKs".
   * **Update:** Replace with "Develop FastAPI CRUD Routers", "Define Pydantic Models", and "Generate OpenAPI/Swagger client for Flutter".
2. **`07a-agent-execution-tracker.md`**
   * **Action:** Update the exact task checklists to reflect the new API-only flow (e.g., creating Alembic migrations instead of pushing FDC schemas).

---
**Verdict:** Moving to a Pure API-only approach is highly recommended for your specific constraints (Solo Dev, AI-Driven, TDD). Let me know if you approve this pivot, and I will begin surgically updating the `01b` and `06` series artifacts to reflect the pure FastAPI/SQLAlchemy architecture.
