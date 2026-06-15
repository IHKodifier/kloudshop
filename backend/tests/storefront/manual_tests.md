# Storefront Features — Manual Test Suite

This document defines a series of manual test cases to thoroughly verify the storefront and visual builder features of kloudShop.

---

## 📋 Table of Contents
1. [Test Group 1: Storefront Brand Profiles](#test-group-1-storefront-brand-profiles)
2. [Test Group 2: Static Pages Management](#test-group-2-static-pages-management)
3. [Test Group 3: Catalog & Search Routing](#test-group-3-catalog--search-routing)
4. [Test Group 4: Shipping Rate Calculation Engine](#test-group-4-shipping-rate-calculation-engine)
5. [Test Group 5: Theme Layout Cloning & A/B Testing](#test-group-5-theme-layout-cloning--ab-testing)

---

### Test Group 1: Storefront Brand Profiles

#### Test Case SF-BP-001: Admin Store Identity Update & Seeding
*   **Objective**: Initialize the database and verify that store administrators can update their store name and profile details.
*   **Prerequisites**: Access to a tenant administrator account.
*   **Steps**:
    1.  Log in to the Admin Dashboard.
    2.  Navigate to **Settings** (bottom of the left sidebar) -> **Store Details** (first sub-navigation tab on the left).
    3.  **Database Seeding**: Because you have a clean database, you must initialize the test products and profile. Scroll to the bottom left and click **Seed Demo Data** under the *Demo Utilities* section.
        *   *Note*: If it returns a database lock/error on the first click, simply click it a second time. It will succeed and display a success snackbar "Store seeded successfully!".
    4.  Enter the following details:
        *   **Store Name**: Change the name to `Vibe Skool Coffee` (or you can choose to leave it as `Enigmatekinc`).
        *   **Store Industry**: Select `Luxury Apparel & Gear` or another industry from the dropdown.
    5.  Click the **Save Settings** button at the bottom right.
*   **Expected Results**:
    *   Settings details are saved successfully.
    *   A success snackbar "Settings saved successfully!" is shown.

#### Test Case SF-BP-002: Public Brand Profile Retrieval
*   **Objective**: Verify that public storefront visitors can retrieve the brand profile.
*   **Context**: The URL path always uses your unique **Store ID** (which is `enigmatekinc`) as the URL slug. Changing the "Store Name" in SF-BP-001 does *not* change the URL path slug.
*   **Steps**:
    1.  Open a private/incognito browser tab (no active admin session).
    2.  Navigate to the public brand profile API route in your browser address bar:
        *   **If you left the Store Name as `Enigmatekinc`**:
            `http://127.0.0.1:8000/api/v1/storefront/enigmatekinc/profile`
        *   **If you changed the Store Name to `Vibe Skool Coffee`**:
            `http://127.0.0.1:8000/api/v1/storefront/enigmatekinc/profile` (The URL path slug remains `enigmatekinc`).
*   **Expected Results**:
    *   Status code: `200 OK`.
    *   The returned JSON payload's `brand_name` matches your Store Name from SF-BP-001:
        *   *If name was left default*: `"brand_name": "Enigmatekinc"`
        *   *If name was changed*: `"brand_name": "Vibe Skool Coffee"` (or whatever name was entered)
        *   `slug` is `"enigmatekinc"`
        *   `is_published` is `true`

#### Test Case SF-BP-003: Public Retrieval of Non-Existent Store
*   **Objective**: Verify graceful failure for non-existent brand slugs.
*   **Steps**:
    1.  Open a browser tab.
    2.  Access `GET /api/v1/storefront/nonexistent-store-slug/profile`
*   **Expected Results**:
    *   Status code: `404 Not Found`.
    *   Error payload: `{"detail": "Storefront profile not found"}`.
    *   **Future Requirement**: The public storefront UI should render a premium, user-friendly 404 page stating "Storefront does not exist" rather than just showing a raw JSON error response.

---

### Test Group 2: Static Pages Management

#### Test Case SF-SP-001: Create and Publish Page via Swagger UI
*   **Objective**: Verify store administrators can create a custom static page. Since there is currently no direct frontend UI page for "Pages" in the Admin Dashboard, we test this using Swagger UI with a retrieved admin auth token.
*   **Prerequisites**: Access to the Admin Dashboard (user must be logged in).
*   **Steps**:
    1.  **Extract Bearer Token**:
        *   Open the Admin Dashboard in your browser.
        *   Open Browser Developer Tools (usually by pressing `F12` or `Ctrl + Shift + I` / `Cmd + Option + I`).
        *   Navigate to the **Network** tab and filter by **Fetch/XHR**.
        *   Trigger any action on the dashboard (e.g. click a settings tab or refresh the page) to send requests to the backend.
        *   Select a backend request targeting `http://127.0.0.1:8000/api/v1/...` (such as `details` or `profile`).
        *   Look under the **Headers** tab, find the **Request Headers** section, and locate `Authorization`.
        *   Copy the long token string (everything after the `Bearer ` prefix. E.g. starting with `eyJhbGciOiJSUz...`).
    2.  **Authorize in Swagger UI**:
        *   Open a new tab and go to `http://127.0.0.1:8000/docs`.
        *   Click the green **Authorize** button at the top right of the page.
        *   Paste the copied token string into the Value input field (Note: Paste only the raw token string starting with `eyJ...`, *without* the `Bearer ` prefix, as Swagger automatically handles it).
        *   Click **Authorize** and then click **Close**.
    3.  **Execute Create Page Request**:
        *   Find the **Storefront** section in the Swagger documentation and expand **POST /api/v1/storefront/pages**.
        *   Click **Try it out** on the right side.
        *   Enter the following JSON payload under `Request body`:
            ```json
            {
              "title": "About Vibe Skool",
              "slug": "about-us",
              "body": {
                "content": "Welcome to Vibe Skool Coffee, where education meets caffeination."
              },
              "page_type": "custom",
              "status": "published",
              "show_in_nav": true,
              "nav_label": "About Us"
            }
            ```
        *   Click **Execute**.
*   **Expected Results**:
    *   Status code: `200 OK`.
    *   Response body is returned showing the generated `page_id` and the created page details.

#### Test Case SF-SP-002: Public View of Published Page
*   **Objective**: Retrieve a published static page publicly.
*   **Steps**:
    1.  Open a private/incognito browser tab (or run an unauthenticated request).
    2.  Access the public storefront pages API route:
        `http://127.0.0.1:8000/api/v1/storefront/enigmatekinc/pages/about-us` (The URL path slug remains `enigmatekinc`).
*   **Expected Results**:
    *   Status code: `200 OK`.
    *   The returned JSON contains the page title `"About Vibe Skool"` and body content matching the created page.

#### Test Case SF-SP-003: Draft Page Restriction
*   **Objective**: Ensure draft pages are not accessible publicly.
*   **Steps**:
    1.  Go back to the Swagger UI tab (authenticated).
    2.  Find **POST /api/v1/storefront/pages** and click **Try it out**.
    3.  Enter the following JSON payload under `Request body`:
        ```json
        {
          "title": "Secret Menu",
          "slug": "secret-menu",
          "body": {
            "content": "Secret coffee blend recipes."
          },
          "page_type": "custom",
          "status": "draft",
          "show_in_nav": false
        }
        ```
    4.  Click **Execute** and confirm it returns `200 OK`.
    5.  In an unauthenticated/incognito browser tab, request the draft page:
        `http://127.0.0.1:8000/api/v1/storefront/enigmatekinc/pages/secret-menu`
*   **Expected Results**:
    *   Status code: `404 Not Found`.
    *   Response payload: `{"detail": "Page not found"}`.

---

### Test Group 3: Catalog & Search Routing

#### Test Case SF-CS-001: Storefront Catalog Search
*   **Objective**: Verify product search retrieves relevant items under the store brand.
*   **Steps**:
    1.  Ensure the store catalog has items (seeded in SF-BP-001, which yields `Demo Product`).
    2.  Access the public search endpoint in your browser:
        `http://127.0.0.1:8000/api/v1/storefront/enigmatekinc/search?q=demo` (The URL path slug remains `enigmatekinc`).
*   **Expected Results**:
    *   Status code: `200 OK`.
    *   Returned array lists matching products (like `Demo Product` matching `demo`) with title, SKU, images, and prices.

---

### Test Group 4: Shipping Rate Calculation Engine

#### Test Case SF-SR-001: Standard Shipping Rates (Under Threshold)
*   **Objective**: Test shipping calculations for low-value orders.
*   **Steps**:
    1.  Submit shipping rate request for standard items totaling **$45.00**:
        ```json
        {
          "country": "US",
          "items": [
            {
              "price": 15.00,
              "quantity": 3
            }
          ]
        }
        ```
        `POST /api/v1/storefront/shipping/rates`
*   **Expected Results**:
    *   Calculated shipping rate is non-zero (e.g. `$5.00` or `$10.00` based on default setup).
    *   Service level returned indicates "Standard Shipping".

#### Test Case SF-SR-002: Free Shipping Threshold Eligibility
*   **Objective**: Verify that orders of $100.00 or higher trigger free shipping.
*   **Steps**:
    1.  Submit shipping rate request totaling **$120.00**:
        ```json
        {
          "country": "US",
          "items": [
            {
              "price": 40.00,
              "quantity": 3
            }
          ]
        }
        ```
        `POST /api/v1/storefront/shipping/rates`
*   **Expected Results**:
    *   Rate matches: `0.0` (Free).
    *   Display name includes the word `"Free"` (e.g., `"Free Standard Shipping"`).

---

### Test Group 5: Theme Layout Cloning & A/B Testing

#### Test Case SF-TL-001: Clone Layout from Visual Builder
*   **Objective**: Verify cloning active layout in the WYSIWYG editor.
*   **Steps**:
    1.  Open the WYSIWYG Builder.
    2.  Observe the header displays the active layout name (e.g., "Active Theme").
    3.  Click **Clone Layout** in the toolbar.
    4.  Enter the name `Sidebar Option B` and confirm.
*   **Expected Results**:
    *   A modal appears indicating "Layout Cloned Successfully".
    *   The modal exposes a Copy Share Link (e.g. `http://.../#/preview?configId=UUID`).
    *   Clicking **Copy Link** writes the URL to the clipboard.

#### Test Case SF-TL-002: Public Layout Preview Sharing
*   **Objective**: View a shared layout preview without authentication.
*   **Steps**:
    1.  Copy the generated preview URL from the previous step.
    2.  Open an incognito window and paste the URL.
*   **Expected Results**:
    *   The page loads immediately with no login wall.
    *   Displays a premium banner: `Previewing Layout: Sidebar Option B`.
    *   The canvas is populated with mock products and lorem ipsum descriptions (strictly isolated from active merchant inventory).

#### Test Case SF-TL-003: Theme Library Layout Dashboard
*   **Objective**: CRUD layout configs via the Theme Library.
*   **Steps**:
    1.  Navigate to the **Theme Library**.
    2.  Verify the card `Sidebar Option B` is listed under the **Custom Layouts & A/B Test Clones** section.
    3.  Click **Rename**, change the name to `Green Theme Test`, and verify the card updates.
    4.  Click **Publish** on `Green Theme Test`.
*   **Expected Results**:
    *   `Green Theme Test` displays status label **Active**.
    *   The former active layout is downgraded to status label **Draft**.
    *   The **Delete** button is now disabled for `Green Theme Test` (active layouts cannot be deleted).
