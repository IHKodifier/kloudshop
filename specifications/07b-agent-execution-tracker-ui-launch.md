# Agent Execution Tracker (SSOT) - Phase 7 & 8

> **Purpose:** This is the Single Source of Truth (SSOT) for all AI Agents working on KloudShop's final phases.
> *Note: Phases 1 through 6 are completed and tracked in `07a-agent-execution-tracker.md` (Archived).*
>
> **Rule for Agents — MANDATORY SESSION START PROTOCOL:**
> 1. Read `00-MASTER-PRD.md` first (vision, commandments, architecture, epic map).
> 2. Read this file to find your assigned task and current sprint status.
> 3. Read `08a-api-specification.md` for the exact endpoint contract before writing any code.
> 4. Check `04b-mvp-scope.md` to confirm your story is MVP — do not implement Post-MVP features.
> 5. **Always update this tracker before handing back to the Human.**

---

## Current Environment Status

| Environment | GCP/Firebase Project | Git Branch | Status |
|-------------|----------------------|------------|--------|
| **Dev** | `kloudshop-dev` | `phase6/storefront-parity-ssr` | MVP Backend/Functional COMPLETE ✅ |
| **Staging** | `kloudshop-staging` | `dev` | Stable for QA |
| **Prod** | `kloudshop-prod` | `main` | Pending Phase 8 |

---

## Active Sprint: PHASE 7 — Premium UI/UX "Surgical" Overhaul (Sprint 19)

> [!IMPORTANT]
> Focus **only** on the active sprint. The backend is solid. Now we shift from functional Flutter UI to the designed "Premium" look.
> Implement Glassmorphism, advanced typography (Outfit/Inter), and fluid animations.
> Do NOT build simple minimum viable product screens here. Aesthetics are PARAMOUNT.

### Sprint 19 — Designer UI Implementation
- [x] **Dashboard Overview Restore:** Restore the charts and cards in the Dashboard Overview that were missing or flickering. Ensure they correctly reflect seeded demo data.
- [x] **Product Gallery Multi-image:** Expand the single `image_url` support to a full multi-image `List<String>` gallery in Catalog/Product Editor.
- [x] **Core Brand Identity:** Replace all skeletal components with premium, design-system-compliant UI tokens.
- [x] **Merchant Dashboard Overhaul:** Full high-fidelity overhaul of the admin interface (Dark mode, glassmorphism, fluid transitions).
- [x] **Landing Page Overhaul:** Complete conversion-focused 8-section architecture with Alpine Emerald styling.
- [ ] **Premium UI Upgrade - Core Views:** Apply "Alpine Emerald" styling, glassmorphism, Outfit/Inter typography, and `HoverScale` micro-animations to all remaining views:
  - [ ] Onboarding / Provisioning Page
  - [ ] Catalog View
  - [ ] Orders View
  - [ ] Customers View
  - [ ] Settings View
  - [ ] Billing View
  - [ ] Blog View
  - [ ] Themes View
- [ ] **Storefront Themes:** Implement pixel-perfect designer versions of all default storefront templates.
- [ ] **Global Visual Audit:** Manual "Surgical" pass on every single screen to ensure 100% parity with design taste.

---

## Phase 8 Checklist — Launch Readiness (Sprints 20–21)

#### Sprint 20 — Production Infrastructure (E19 + E20)
- [ ] **Custom Domains:** CNAME verification and SSL auto-provisioning.
- [ ] **Platform Production:** Final terraform/scripts for `kloudshop-prod`.
- [ ] **Final UAT:** End-to-end "Minimum Value Loop" (Sign up → Design → Sell) using Mock Mode.

#### Sprint 21 — Production Handover (POST-LLC SETUP)
- [ ] **Stripe Live Mode:** Transition from Mock Billing to real Stripe once UK LLC is verified.
- [ ] **Connect Platform:** Final Live integration for merchant payouts and transaction fee collection.
- [ ] **Security Audit:** Pentesting RBAC and data isolation boundaries.
- [ ] **Public Launch:** Merge `dev` to `main` and activate marketing site.

---

## Agent Handoff Protocol

### When completing a task:
1. Verify all unit/integration tests pass.
2. Confirm implementation aligns perfectly with modern design standards.
3. Update this checklist: `[ ]` → `[x]`.
4. Update `Current Environment Status` table if infra/env changed.
5. Commit code with descriptive conventional commits.
6. Prompt the Human to run manual verification via IDE debugger or approve the next task.
