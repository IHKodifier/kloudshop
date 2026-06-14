# Variant Management Test Scenarios

This document outlines the test scenarios to verify the correctness of the variant generation, reconciliation, collapsing, and metadata preservation logic. All scenarios use the **"Premium Coffee Mug"** product.

---

## Scenario: VT-001 (Zero Options to Single Option Transition)

- **Objective**: Verify that a fresh product starting with zero options creates a default base variant with a slug-based SKU, and adding a single option category with values correctly generates permutations using the base SKU as a template/prefix.
- **Initial Setup**:
  1. Open the **New Product** page.
  2. Step 1: Set Product Title to `Premium Coffee Mug` (slug generates as `premium-coffee-mug`).
  3. Step 3: Verify Color option category starts with zero selected values (shows: **"No color options defined for this product."**).
  4. Expand the sole active variant card (titled **"Default Variant"**) and verify:
     - SKU: Empty (placeholder `SKU`)
     - Price: `$0.00`
     - Stock: `0`
     - Option values: Empty
- **Test Steps**:
  1. Under the **Default Variant** details, enter the SKU: `MUG-PREMIUM`.
  2. Under the **Color** options category, click the circular preset color chip for **"Pure white"** (adds `Pure white` to selected list).
  3. Click the **Generate Variants** button.
  4. Select **Intelligent Reconciliation** when prompted.
- **Expected Outcome**:
  - The variant generator runs and prompts a success dialog showing that **1 variant** was generated.
  - The variant list now displays a single active collapsible card.
  - The card header title (SKU) is: `MUG-PREMIUM-PURE-WHITE`.
  - Next to the SKU in the card header, there is an option value chip displaying: `Color: Pure white`.
  - Inside the expanded card details, the price is preserved as `$0.00` and stock as `0`.

---

## Scenario: VT-002 (Reconciliation of Pricing and Stock on Option Addition)

- **Objective**: Verify that when adding options to a configured variant list, existing configurations (such as prices, stock levels, images) are preserved and correctly matched/propagated to new option permutations using **Intelligent Reconciliation**.
- **Initial Setup**:
  1. Option Category **Color** has selected values: `Pure white`, `Jet black`.
  2. Variants Generated:
     - `PREMIUM-COFFEE-MUG-PURE-WHITE`: Configure Price to `$15.00` and Stock to `10`.
     - `PREMIUM-COFFEE-MUG-JET-BLACK`: Configure Price to `$18.00` and Stock to `25`.
- **Test Steps**:
  1. Click **Add Option Category** at the bottom of the card.
  2. Name the new category: `Size`.
  3. Inside the `Size` option card, type `S` in **Add Value** and click the add icon.
  4. Type `M` in **Add Value** and click the add icon.
  5. Click **Generate Variants**.
  6. Select **Intelligent Reconciliation** in the pop-up modal.
- **Expected Outcome**:
  - Success dialog shows **4 variants** generated:
    1. `PREMIUM-COFFEE-MUG-PURE-WHITE-S`
    2. `PREMIUM-COFFEE-MUG-PURE-WHITE-M`
    3. `PREMIUM-COFFEE-MUG-JET-BLACK-S`
    4. `PREMIUM-COFFEE-MUG-JET-BLACK-M`
  - Expand each card and verify that:
    - Both `PURE-WHITE-S` and `PURE-WHITE-M` have inherited Price: `$15.00` and Stock: `10` (or split/copied from the original `PURE-WHITE` variant).
    - Both `JET-BLACK-S` and `JET-BLACK-M` have inherited Price: `$18.00` and Stock: `25`.
    - Variant custom images and shipping overrides are preserved from their respective color parents.

---

## Scenario: VT-003 (Collapse to Simple Product - Stock Aggregation)

- **Objective**: Verify that deleting all active option values collapses the product back to a single default base variant, and automatically aggregates (sums) the stock count of all active variants.
- **Initial Setup**:
  1. Option Category **Color** has: `Pure white`, `Jet black`.
  2. Variant configurations:
     - `PREMIUM-COFFEE-MUG-PURE-WHITE`: Price: `$12.50`, Stock: `15`
     - `PREMIUM-COFFEE-MUG-JET-BLACK`: Price: `$15.00`, Stock: `30`
- **Test Steps**:
  1. Click the trash icon next to the **Color** category input field (configured with tooltip: *Don't use color for this product*).
  2. Verify all selected color chips (`Pure white` and `Jet black`) are removed and the bold banner appears: **No color options defined for this product.**
  3. Click **Generate Variants**.
  4. A dialog pops up: *"Collapse to Simple Product? Deleting all options will collapse this product back into a single default variant."*
  5. Click **Confirm Collapse**.
- **Expected Outcome**:
  - The variant list collapses to a single variant.
  - The card header is named **"Default Variant"** (or inherits the base SKU template `PREMIUM-COFFEE-MUG`).
  - No option value chips are present in the card header.
  - Expand the card and check the values:
    - Price: `$12.50` (copied from the original default/first active variant).
    - Stock: `45` (automatically aggregated: `15 + 30`).

---

## Scenario: VT-004 (Fresh Generation vs Reconciliation)

- **Objective**: Verify that selecting **Fresh Generation** discards all custom variant configurations and resets them to baseline defaults, whereas **Intelligent Reconciliation** preserves them.
- **Initial Setup**:
  1. Option Category **Color** has: `Pure white`, `Jet black`.
  2. Variant configurations:
     - `PREMIUM-COFFEE-MUG-PURE-WHITE`: Price: `$25.00`, Stock: `50`
     - `PREMIUM-COFFEE-MUG-JET-BLACK`: Price: `$30.00`, Stock: `80`
- **Test Steps**:
  1. Add a custom option category: `Material`.
  2. Add value to `Material`: `Ceramic`.
  3. Click **Generate Variants**.
  4. Select **Fresh Generation** in the modal.
- **Expected Outcome**:
  - Success dialog shows **2 variants** generated:
    1. `PREMIUM-COFFEE-MUG-PURE-WHITE-CERAMIC`
    2. `PREMIUM-COFFEE-MUG-JET-BLACK-CERAMIC`
  - Expand the cards and verify:
    - Price for both variants is reset to `$0.00`.
    - Stock for both variants is reset to `0`.
    - Any customized images or overrides are completely cleared.

---

## Scenario: VT-005 (Deletion of Option Values / Partial Match Reconciliation)

- **Objective**: Verify that removing a specific option value (e.g. removing `Metallic silver` from `Color` list) correctly deactivates/retires the variant in the database while leaving other active variants unaffected.
- **Initial Setup**:
  1. Option Category **Color** has: `Pure white`, `Jet black`, `Metallic silver`.
  2. All 3 variants are generated and saved (assigned with internal database IDs).
  3. Variant configurations:
     - `PURE-WHITE`: Price `$10.00`, Stock `100`
     - `JET-BLACK`: Price `$12.00`, Stock `120`
     - `METALLIC-SILVER`: Price `$15.00`, Stock `80`
- **Test Steps**:
  1. Delete the `Metallic silver` chip from the Color selection.
  2. Click **Generate Variants**.
  3. Choose **Intelligent Reconciliation**.
- **Expected Outcome**:
  - The variant list displays 2 active variants: `PURE-WHITE` and `JET-BLACK`, retaining their prices (`$10.00` / `$12.00`) and stock (`100` / `120`).
  - The `METALLIC-SILVER` variant is removed from the visible active list on the UI, but under the hood (in the provider's state), its status is updated to `is_active: false` so that the database registers its deletion upon saving the product.

---

## Scenario: VT-006 (Renaming a Custom Option Category)

- **Objective**: Verify that renaming a **custom** option category (e.g. `Size` → `Dimensions`) propagates correctly to the variant card headers without resetting configured details. Note: the built-in **Color** option category is permanently locked and cannot be renamed — this test must NOT use Color for this purpose.
- **Initial Setup**:
  1. Open the **New Product** page.
  2. Step 1: Set Product Title to `Premium Coffee Mug`.
  3. Step 3: Click **Add Option Category** and name it `Size`.
  4. Inside the `Size` option card, add value `Standard` and value `Large`.
  5. Click **Generate Variants** and select **Fresh Generation**.
  6. Two variants are generated:
     - `PREMIUM-COFFEE-MUG-STANDARD`: Configure Price to `$12.00`, Stock to `40`.
     - `PREMIUM-COFFEE-MUG-LARGE`: Configure Price to `$16.00`, Stock to `20`.
- **Test Steps**:
  1. Click the **Option Name** text field of the `Size` category card.
  2. Clear the text and type `Dimensions`.
  3. Click **Generate Variants** and select **Intelligent Reconciliation**.
- **Expected Outcome**:
  - Both variant cards remain visible with their prices and stock preserved:
    - `PREMIUM-COFFEE-MUG-STANDARD`: Price `$12.00`, Stock `40` ✅
    - `PREMIUM-COFFEE-MUG-LARGE`: Price `$16.00`, Stock `20` ✅
  - The option value chip in each variant card header now reads `Dimensions: Standard` and `Dimensions: Large` (instead of `Size: Standard` / `Size: Large`).
- **Also Verify (Color Lock)**:
  - Confirm the **Color** option name field shows "Color" as static read-only text with a 🔒 lock icon.
  - Confirm clicking on that field does **not** allow typing or editing.
  - Confirm there is **no trash/delete icon** next to the Color option header row.
