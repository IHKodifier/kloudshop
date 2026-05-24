# Deferred Non-Blocking Items — Post-Phase 8

> **Purpose:** This is a log of incomplete items from earlier sprints that are intentionally deferred.
> They do NOT block Phase 7 (UI Overhaul) or Phase 8 (Launch Readiness).
> Come back to these after the public launch or during a dedicated hardening sprint.
>
> **Created:** 2026-05-23 | **Last Updated:** 2026-05-23

---

## From Sprint 15 — Analytics & Dashboard (E09)

- [ ] **BigQuery Data Export Pipeline**
  - Stream order/event data from PostgreSQL to BigQuery for long-term analytics
  - Epic: E09 | Story: US-053 (extended)
  - Blocked by: Needs production data volume to be worthwhile
  - Priority: Medium

- [ ] **Vertex AI Demand Forecasting**
  - Implement demand forecasting using Vertex AI AutoML
  - Epic: E09 | Story: US-054
  - Blocked by: Requires 90+ days of real sales data and 100+ orders
  - Ships with: Disclaimer state already implemented ("AI forecasting improves as data builds")
  - Priority: Low (self-improving — activates with data)

- [ ] **Looker Studio Embedded BI Integration**
  - Embed Looker Studio dashboards via scoped BigQuery service account tokens
  - Epic: E09 | Story: US-055
  - Blocked by: BigQuery pipeline (above) must be active first
  - Ships with: Empty state overlay already implemented
  - Priority: Medium

---

## From Sprint 16 — Hygiene & Operations (E19 + E18)

- [ ] **Nightly Schema Drift Detection**
  - Cloud Scheduler job to compare live database schema vs Alembic `head`
  - Epic: E19 | Story: US-083
  - Implementation: Python script comparing `information_schema.columns` against Alembic metadata
  - Priority: High (production safety net)

- [ ] **GDPR Right-to-Erasure Pipeline**
  - PII anonymisation pipeline (not deletion) for GDPR Article 17 compliance
  - Epic: E19 | Story: US-084
  - Implementation: `/internal/gdpr-erasure` endpoint that scrubs PII fields, replaces with hashed placeholders
  - Required for: UK/EU market launch
  - Priority: High (legal compliance)

- [ ] **Production Canary Deployment Approval Flow**
  - GCP Cloud Deploy integration for staged rollouts with human approval gate
  - Epic: E18 | Story: US-080
  - Implementation: Cloud Deploy pipeline config + Platform Admin approval UI
  - Priority: Medium

- [ ] **SYS-18 Version Detection (Service Worker + version.json)**
  - Auto-detect new deployments via `version.json` polling
  - Show "Update Available" banner to active users
  - Implementation: Flutter service worker registration + version check interval
  - Priority: Low (nice-to-have for launch)

---

## From Sprint 18 — Consumer Storefront Parity (E17)

- [ ] **Mobile Responsive Audit (Core Web Vitals)**
  - Full responsive audit across 375px, 768px, 1024px, 1440px breakpoints
  - Lighthouse CWV compliance check for all storefront pages
  - Epic: E17 | Story: US-072
  - Priority: High (SEO impact)

---

## Notes

- Items marked **High priority** should be addressed in the first post-launch sprint
- **Vertex AI** and **Looker Studio** will self-activate as merchant data accumulates
- **GDPR erasure** is legally required before accepting UK/EU merchant signups in production
- **Schema drift** is a safety net that becomes critical once multiple tenants are live
