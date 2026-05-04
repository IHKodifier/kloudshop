# Session Handoff: Merchant Billing & Subscription Stability

## Current Status
We have successfully synchronized the platform's billing tiers with the official **DTC**, **B2B**, and **Hybrid** business models defined in the specifications. 

### Accomplishments
1. **Tier Reconciliation**: Replaced `basic/pro/enterprise` with `dtc/b2b/hybrid` in `backend/modules/billing/models.py`, `router.py`, and `frontend/lib/models/subscription.dart`.
2. **UI Stabilization**: Resolved a critical layout crash (unbounded height) in `BillingView` using `IntrinsicHeight`.
3. **Mock Billing Mode**: Enabled a development mode (`TESTING=1`) that allows the "Upgrade" flow to work without real Stripe keys.
4. **Auto-Upgrade**: The backend now automatically updates the database to the target tier when a "mock" checkout is initiated, enabling end-to-end testing of the tier-switching logic.
5. **Data Integrity**: Fixed a key mismatch between backend (`checkout_url`) and frontend (`url`) and updated the Dart model to handle all backend fields including `createdAt`.

## Outstanding Items
1. **Redirect Handling**: The mock redirect to `http://localhost:3000/dashboard?session_id=...` currently lands on a blank/unhandled route in Flutter. We need to ensure the router handles this or uses the standard fragment (`/#/dashboard`).
2. **Real Stripe Transition**: Once the flow is verified, the user needs to add real `STRIPE_SECRET_KEY` and `STRIPE_PRICE_...` variables to `backend/.env` to test the actual Stripe Checkout page.
3. **Feature Gating**: Implement the actual logic that restricts or enables features based on the `SubscriptionTier` (e.g., hiding the Wholesale Portal for DTC merchants).

---

## Resume Task Prompt (Copy & Paste to New Chat)

> I am continuing the stabilization of the Merchant Billing workflow and phase 4 of the 07a-agent-execution-tracker.md file.. we need to start the Sprint 13 (Social Commerce) features. preious agents have completed the base code for the sprint 11 and 12
> 
> **Context:**
> - We have already aligned the tiers to **DTC**, **B2B**, and **Hybrid**.
> - **Mock Mode** is active: if `TESTING=1` and Stripe keys are missing, the backend auto-upgrades the user and redirects to a mock URL.
> - Current Issue: The redirect URL `http://localhost:3000/dashboard?session_id=...` is not loading content correctly in the browser, even though a manual refresh shows the plan has been updated.
> 
> **Instructions for Antigravity:**
> 1. Review `frontend/lib/app.dart` and `dashboard_page.dart` to fix the routing/redirect issue so the dashboard loads correctly after a billing redirect.
> 2. Verify the `SubscriptionStatus` logic to ensure "Active" vs "Trialing" states are visually distinct and accurate.
> 3. Prepare to transition to real Stripe Test Mode by reviewing the required environment variables in `backend/shared/db.py`.
> 4. Update the `Agent Execution Tracker` (Sprint 7) to reflect that billing stabilization is 95% complete.

---
*Signed: Antigravity*
