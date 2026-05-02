# Handoff: Sprint 10 - Platform Features

**Context ID**: `e332fb8e-ace6-4795-b2ec-5beb1550ea40`
**Phase**: 3 (Merchant Experience)
**Current Branch**: `phase3/merchant-experience`

## Current Status
- **Sprint 8 (Onboarding)**: COMPLETED. Merchant signup, tier selection, region selection, and AI CSV mapping engine are live and tested.
- **Sprint 9 (Themes)**: COMPLETED. Theme catalog, selection, and the Draft/Live WYSIWYG configuration engine (Design Tokens & Slots) are live and tested.
- **Core Infrastructure**: Database (SQLite for tests, PostgreSQL ready), RBAC, and Auth are stable.

## Required Tasks for Sprint 10
1. **Feature Catalog Engine**: Implement a toggle system for platform features (e.g., enable/disable AI, Export, etc.).
2. **AI Copywriter**: Create an endpoint for generating product titles and descriptions using brand voice profiles.
3. **Export Engine**: Implement asynchronous data export (CSV/JSON) for products, orders, and customers.
4. **Dynamic Pricing Rules**: Build a rules engine for automated pricing adjustments (Flash sales, stock-age).

## Handoff Instructions for Agent
1. **Reference Knowledge**: Read the `specifications/07a-agent-execution-tracker.md` to confirm completed items.
2. **Setup**: Ensure the `onboarding` and `themes` modules are correctly registered in `main.py`.
3. **Plan**: Create an implementation plan for Sprint 10 following the existing modular pattern.
4. **Execute**: Proceed with TDD-first implementation of the Platform Features module.

---
**Verification Proof (Sprint 9)**:
- `backend/tests/test_themes.py` -> 1/1 PASS
- `backend/tests/test_onboarding.py` -> 1/1 PASS
