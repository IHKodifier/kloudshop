# Specifications Changelog


This changelog records the architecture, model, provider, and UI changes made during the development of **Phase 7 ownard phases**. It is structured to help future agents quickly grasp the codebase delta and verify existing functionality.

## introduced by Phase 7
### Journey 1: Authentication & Onboarding (Branch: phase7/j1-auth)

#### 1. New Models & Constants

### [gcp_region.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/models/gcp_region.dart) [NEW]
- **Purpose**: Modularizes the data structure of GCP datacenter regions, separating logic from data.
- **Contents**:
  - `GcpRegion` model class:
    - `id` (technical name, e.g., `us-east1`)
    - `name` (human-readable name, e.g., `US East`)
    - `location` (city/country representation, e.g., `South Carolina, USA`)
    - `continent` (geographic continent, e.g., `Americas`)
    - `latitude` and `longitude` (for proximity triangulation and map painting)
    - `customerTarget` (helper text sector, e.g., `Eastern US & Canada`)
  - `gcpRegions` constant `Map<String, GcpRegion>`: Pre-defines 35+ global Google Cloud regions with complete metadata coordinates and targeting help.

---

#### 2. State Providers & Authentication

### [provisioning_provider.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/providers/provisioning_provider.dart) [MODIFY]
- **Triangulation & IP Geolocation**:
  - Intercepts notifier initialization to hit the public IP API (`https://ipapi.co/json/`) and parse the user's lat/lng location.
  - Implements Haversine distance-based sorting (`getSortedRegions()`) to rearrange dropdown list options dynamically by proximity to the merchant.
- **Synchronization & Hang-state Resolution**:
  - Removed deprecated reactive claims refresh loops which were stuck on the "Your store is ready" screen due to Firebase token replication latency.
  - Refactored notifier synchronization to call Firebase's `.getIdToken(forceRefresh: true)` directly, guaranteeing claims propagation and triggering immediate redirect to the merchant dashboard.

---

#### 3. UI Views & Visual Adjustments

### [login_page.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/login_page.dart) [MODIFY]
- **Modal Dialog Proportions**:
  - Adjusted desktop flex proportions: Left Form column occupies **40%** (`flex: isDesktop ? 4 : 12`), and Right Graphic column occupies **60%** (`flex: 6`).
- **Above-The-Fold Compression**:
  - Reduced vertical gaps between brand logos, headings, inputs, and dividers to ensure **Sign In** and **Login with Google** buttons remain above the fold under the `680px` height constraint.
- **Graphic Alignment**:
  - Changed the right-pane column alignment to `MainAxisAlignment.end` and bottom padding to `32px` to draw quotes and stats widgets cleanly at the bottom edge.

### [provisioning_page.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/provisioning_page.dart) [MODIFY]
- **Placeholder Empty State**:
  - Displays a clean "No Region Selected" empty state on Step 4 before a primary node is chosen.
- **Adaptive Node Cards**:
  - Selecting a region dynamically populates interactive primary and failover status widgets.
- **Multi-Region Redundancy Accordion**:
  - Renders checkbox selectors for recommended backup nodes in the same continent.
  - Implements global region selection dropdown to add custom backups.
  - Calculates dynamic surcharge rate (+15% per node) with real-time billing cost feedback.
- **Overhauled GCP Region Dropdown**:
  - Implements a rich, multi-line row layout:
    - **Row 1**: Displays Name, City Location, and a green proximity distance badge (e.g. `(~123 km)`).
    - **Row 2**: Displays technical ID in a monospace code container (`robotoMono`), followed by target customer sectors.
    - **Highlighting**: Colors `Eastern Canada` targets in bold green (`AppTheme.brandEmerald500`) for visual appeal.
  - **Trailing 2D Map**: Renders a custom vector-drawn world map (`90x56` size) using `WorldMapPainter`. Draws ocean gradients, latitude/longitude navigation lines, continent outlines, and a sharp target crosshair (plus sign with a center dot and gap) matching AppTheme colors.
  - **Selected Representation**: Integrates `selectedItemBuilder` to display a neat, compact single-line string when the dropdown collapses.

---

#### 4. Verification & UAT Tests
- **Dart Analyzer**: Checked with `flutter analyze`. Verified **0 compilation errors or style warnings** in all modified and new files.
- **Proximity check**: Dropdown correctly sorts nearby nodes (e.g., North America regions for NA users).
- **Onboarding completion**: Proceeding past the final step instantly triggers token validation and redirects users to `/dashboard` without hanging.
- **Theme check**: The crosshair colors change dynamically (`Colors.white` in Dark Mode, `AppTheme.brandTeal900` in Light Mode) to maintain visibility on the customized 2D world map.

---

#### 5. User Login Auditing, Brute-Force Lockout, and Account Recovery (Security Enhancements)

- **Security Auditing & Geolocation Triangulation**:
  - Automatically logs successful logins of owners, merchants, and staff into the database.
  - Enriches log records with client IP address, browser user agent string, tenant ID, and coordinates (latitude, longitude, country, region, city) fetched via geolocation triangulation.
  - Mocked regional coordinates (Montreal, Eastern Canada) for developer localhost environments to guarantee zero-cost local development.

- **Cooldown & Brute-Force Prevention Rules**:
  - **180-Second Cool-Off**: Triggered after every single failed sign-in attempt. Disables login form fields and sign-in buttons across all client applications.
  - **Cross-Device Sync**: Checks the security state of a Gmail address upon field focus to disable login inputs and start a countdown timer locally if a cool-off is active on another device.
  - **3-Strike Lockout**: Automatically blocks/locks the user's account if 3 failed login attempts occur within a 24-hour cycle.
  - **Multi-Day Lockout**: Automatically blocks/locks the user's account if even a single failed login attempt is recorded on 3 or more distinct calendar days.

- **Account Recovery & Unblocking**:
  - **Self-Service Verification Link**: Generates a secure unblock link (`http://localhost:3000/unblock?token=<token>`) sent via email on demand.
  - **180-Second Token TTL**: The verification link expires and becomes invalid exactly 180 seconds after generation.
  - **24-Hour Request Limit**: Limits unblock request emails to a maximum of 3 requests per 24-hour cycle to prevent email spam.
  - **Owner/Admin Assistant Flow**: Authenticated managers/owners can unblock staff members directly from the merchant dashboard via `POST /auth/staff/{uid}/unblock`.

- **New Database Models & Classes**:
  - **`StaffLoginHistory`** ([models.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/auth/models.py)):
    - `login_id` (`String`, Primary Key): UUID representation of the login event.
    - `staff_user_id` (`String` -> foreign key to `staff_users.uid`): ID of the staff user who signed in.
    - `tenant_id` (`String`): Current tenant context.
    - `ip_address` (`String`): Originating client IP.
    - `user_agent` (`String`): Client browser agent header.
    - `country_code`, `country_name`, `region_name`, `city_name` (`String`): Location metadata.
    - `latitude`, `longitude` (`String`): Geo-coordinates for mapping/distance triangulation.
    - `created_at` (`DateTime`): Timestamp of the audit event.
  - **`StaffSecurityState`** ([models.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/auth/models.py)):
    - `gmail` (`String`, Primary Key): Lowercase staff/owner email address.
    - `failed_attempts_count` (`Integer`): Current consecutive failures within the window.
    - `last_failed_attempt_at` (`DateTime`): Timestamp of last failure.
    - `cool_off_until` (`DateTime`): Expiry timestamp of the active 180s cool-off block.
    - `failed_days_count` (`Integer`): Number of distinct calendar days with failed attempts.
    - `last_failed_day` (`String`): Stored calendar date format (`YYYY-MM-DD`).
    - `is_blocked` (`Boolean`): Lockout state flag.
    - `unblock_token` (`String`): Short-lived unblock identifier token.
    - `unblock_token_expires_at` (`DateTime`): Expiry timestamp of unblock token (180s TTL).
    - `unblock_request_count` (`Integer`): Count of unblock emails sent in the current 24h cycle.
    - `last_unblock_request_at` (`DateTime`): Timestamp of last unblock email.
    - `updated_at` (`DateTime`): Database row modification timestamp.

- **New Backend API Endpoints & Pydantic Schemas**:
  - `GET /api/v1/auth/login-status/{gmail}`: Checks active block and remaining cool-off seconds for an email.
  - `POST /api/v1/auth/failed-login-alert` (Payload: `FailedLoginAlert`): Receives failures from client apps, updates security state (increments attempts, tracks days, initiates cool-offs/locks), and triggers background alert emails.
    - Schema **`FailedLoginAlert`** ([schemas.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/auth/schemas.py)): `email: EmailStr`, `tenant_id: Optional[str]`, `user_agent: Optional[str]`.
  - `POST /api/v1/auth/unblock/request` (Payload: `UnblockRequest`): Validates block status, checks rate limits, generates unblock tokens, and sends verification emails.
    - Schema **`UnblockRequest`** ([schemas.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/auth/schemas.py)): `email: EmailStr`.
  - `POST /api/v1/auth/unblock/verify` (Payload: `UnblockVerify`): Validates recovery token expiration and resets security states on success.
    - Schema **`UnblockVerify`** ([schemas.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/auth/schemas.py)): `token: str`.
  - `POST /api/v1/auth/staff/{uid}/unblock`: Restricts unblocking of locked staff to authenticated admins/owners. Re-secured by verifying the target user belongs to the caller's tenant boundary, returning 403 Forbidden on mismatch.

- **New Client-Side API & UI Integration**:
  - `ApiService` methods ([api_service.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/services/api_service.dart)):
    - `getLoginStatus(String gmail)`: Calls status checks.
    - `sendFailedLoginAlert({required String email, String? tenantId, String? userAgent})`: Logs failures.
    - `requestUnblock(String email)`: Generates unblock email tokens.
    - `verifyUnblock(String token)`: Verifies token-based unblocks.
  - `LoginPage` controller & widgets ([login_page.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/login_page.dart)): FocusNode listener for pre-flight check, active countdown timer state, glassmorphic security alert box, and failed sign-in interception.
  - `UnblockVerificationPage` ([unblock_verification_page.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/unblock_verification_page.dart)): Renders glassmorphic Web view that decodes token parameter from email links and unlocks accounts asynchronously.
  - `App` routing ([app.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/app.dart)): Registered the `/unblock` route pattern.

- **Verification & Lockout Unit Tests**:
  - Created [test_auth_lockout.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/tests/test_auth_lockout.py) implementing 6 comprehensive unit tests:
    - `test_failed_login_alert_cool_off`: Prevents login re-attempts during active 180s cool-offs.
    - `test_failed_login_alert_lockout_3_strikes`: Locks out account on 3 strikes.
    - `test_failed_login_alert_lockout_3_distinct_days`: Locks out account on failures across 3+ calendar days.
    - `test_unblock_email_rate_limit_and_verify`: Limits unblock requests to 3 per 24 hours.
    - `test_unblock_token_ttl`: Verifies that unblock tokens expire after 180 seconds.
    - `test_admin_unblock_staff_tenant_boundary` [NEW]: Verifies cross-tenant admin unblock attempts fail with 403 Forbidden.
  - Restrained AnyIO testing loop context ([conftest.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/tests/conftest.py)) to run exclusively on `asyncio` backend to resolve dependencies errors (missing `trio` module).
  - Successfully verified execution with all 6/6 lockout tests and all 11/11 existing auth tests passing cleanly.

- Updated modal display duration for variant toggle from 3000ms to 1500ms in `product_variants_section.dart`.
- Added ignore entry for `backend/backend/storage/media/` to `.gitignore`.
- Resolved concurrent image upload race condition in `media_gallery_uploader.dart` and `compact_media_list_uploader.dart` by implementing local state tracking (`_localImages`) and generating unique upload IDs.
- Updated the Variants & Pricing section header to show both active and total variant counts in the format "active of total" (e.g. "2 active of 4").
- **Global Lottie Switches Integration**:
  - Replaced standard Flutter `Switch` widgets with `LottieToggle` in `dashboard_page.dart` (Theme Mode switcher) and `provisioning_page.dart` (Multi-region redundancy switch).
  - Defined `LottieToggle.defaultDuration` (preset to `1800ms`) inside `lib/widgets/lottie_toggle.dart` as the single point of control for toggle animation speed app-wide.
  - Documented toggle components and global configuration rules in the design guidelines.
- **Product Compliance Controls (Step 2)**:
  - Replaced legacy switches for Perishable and Digital products in `product_classification_card.dart` with `LottieSwitchListTile`.
  - Added new `LottieSwitchListTile` controls for **Age-Gated Product** and **Prescription Required**.
  - Implemented a responsive `LayoutBuilder` grid inside `product_classification_card.dart` that displays controls in two columns on desktop viewports and stacks them on narrow viewports.
  - Rendered a conditional **MINIMUM AGE** input field that defaults to `21` when Age-Gating is enabled, and automatically clears and hides when disabled.
  - Added field-level and save-level validators in `product_editor_view.dart` to block form submission if the minimum age is not a positive integer (> 0).
- **Variant Shipping Overrides (Step 3)**:
  - Replaced the text link configuration buttons in `product_variants_section.dart` with `LottieSwitchListTile` for independent variant-level shipping overrides.
  - Implemented clear-on-disable behavior: toggling the switch OFF immediately clears and hides the custom dimensions/weights, resetting the variant to inherit main product specs.
  - Fixed provider state mapping in `product_editor_provider.dart` to dynamically initialize `show_shipping_overrides` to `true` if any pre-existing override weight or dimension values are present in the `ProductVariant` model.
- **Design Guidelines Relocation**:
  - Relocated light and dark design documents to `specifications/design/` (creating `light-design.md` and `dark-DESIGN.md` as the gold standards).
  - Updated color YAML tokens to match the actual high-contrast green colors (`#124B47` for Primary brand teal, `#047857` / `#34D399` for Success emerald greens) in `app_theme.dart`.
- **Intelligent Variant Reconciliation**:
  - Implemented overlapping option matching, sorting priority, database ID (`variant_id`) preservation, and custom SKU suffix propagation in [product_editor_provider.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/providers/product_editor_provider.dart). *(Note: Base variant ID preservation during Simple -> Variable transitions is [DEPRECATED - Superseded by No-Options Base Variant Behavior in product_variations_logic.md]).*
  - Added glassmorphic choice dialog (Intelligent Reconciliation vs. Fresh Generation) when option schemas change in [product_editor_variants_step.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/widgets/product/product_editor_variants_step.dart).
- **SKU Modification Warnings & Email Reports**:
  - Added inline warnings below modified SKU input fields in [product_variants_section.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/widgets/product/product_variants_section.dart).
  - Implemented the glassmorphic "SKU Modifications Detected" warning dialog with an email report checkbox in [product_editor_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/product_editor_view.dart) when saving SKU changes.
  - Added `email_sku_report` query parameter, variant SKU change comparison, and `send_sku_change_report_email` background task in [router.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/catalog/router.py).
  - Connected the `emailSkuReport` flag in [api_service.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/services/api_service.dart) and updated [product_editor_provider.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/providers/product_editor_provider.dart) to pass it during save.
- **Verification & Testing**:
  - Added `test_update_product_sku_report` unit test to [test_catalog.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/tests/test_catalog.py).
  - Verified that all 8 backend catalog tests pass cleanly, and the frontend compiles without errors under `flutter analyze`.
- **No-Options Base Variant & Transition Specifications**:
  - Documented the architecture, transition logic, auto-generated SKU rules, deactivation details, and the Collapse Variant Report details in the specifications document [product_variations_logic.md](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/specifications/product_variations_logic.md).

---

### Journey 2: Catalog Enhancements & Bulk CSV Import (Branch: phase7/j2-catalog)

#### 1. New Models & Database Schema
- **ImportJob Audit Fields** ([models.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/catalog/models.py) & [a3f1e8b2c904_import_job_audit_fields.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/migrations/versions/a3f1e8b2c904_import_job_audit_fields.py)):
  - Added audit and progress-tracking columns to `ImportJob`:
    - `initiated_by` (`String`): Email of the merchant initiating the import.
    - `processing_started_at` (`DateTime`): Timestamp when parsing/import processing started.
    - `processing_completed_at` (`DateTime`): Timestamp when the job finished or failed.
    - `source_filename` (`String`): The name of the uploaded CSV/XLSX file.
    - `source_filesize_bytes` (`Integer`): Size of the uploaded file.
    - `conflict_strategy` (`String`): Selected duplication resolution (e.g. `skip`, `overwrite`, `custom_sku`).
    - `rows_skipped` (`Integer`): Count of skipped rows.
    - `rows_overwritten` (`Integer`): Count of overwritten rows.
    - `rows_custom_sku` (`Integer`): Count of rows matching custom SKUs.
    - `no_stock_log` (`JSON`): List of variants that had no stock defined during import (notifying merchant that stock value was not available and they need to update the inventory manually).

---

#### 2. Backend API Endpoints & Async Background Task
- **New Endpoints** ([router.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/catalog/router.py)):
  - `GET /api/v1/catalog/import/template`: Streams a standard CSV import template with basic headers and examples.
  - `POST /api/v1/catalog/import/check-sku-exists` (Payload: `SkuExistsRequest`): Verifies if a list of SKUs already exists in the tenant catalog for client-side pre-flight duplicate checking.
  - `POST /api/v1/catalog/import/upload`: Multipart file upload parsing both CSV and XLSX formats. Creates an `ImportJob` record in `pending` status, and triggers the asynchronous background processing task.
  - `GET /api/v1/catalog/import/jobs/{job_id}`: Retrieves real-time progress of a specific import job.
  - `GET /api/v1/catalog/import/jobs`: Lists all historical import jobs for the current tenant.
- **Asynchronous Processing Task (`_process_import_job`)**:
  - Operates sequentially on rows, extracting product handles, categories, tags, SKU, prices, compare-at prices, stock, and dynamic variant options (supporting up to 9 dynamic levels of product options).
  - Implements three conflict resolution strategies:
    - **Skip**: Skips row ingestion if the SKU exists.
    - **Overwrite**: Updates existing product, variant, pricing, options, and stock values.
    - **Custom SKU**: Renames duplicate SKUs on-the-fly based on client-provided mappings.
  - Sends a completion summary email report at the end of the run containing metrics and details of variants created/modified, and a list of variants imported with missing stock values.

---

#### 3. Frontend Providers, Services & State Management
- **API Client Extensions** ([api_service.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/services/api_service.dart)):
  - Implemented client methods for downloading templates, checking SKU availability, posting multipart form data, polling job progress, and fetching import job lists.
- **CSV/XLSX Import State Manager** ([csv_import_provider.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/providers/csv_import_provider.dart)):
  - Parses uploaded text bytes (CSV) or parses spreadsheet structures using the `excel` package (XLSX).
  - Groups variant rows by product handles to present a unified previews layout.
  - Resolves duplicate SKU check queries, tracks chosen strategies, and manages inline text field overrides for custom SKU mapping.
  - Runs periodic timers to poll `/jobs/{id}` progress endpoints.
- **Import History Manager** ([import_history_provider.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/providers/import_history_provider.dart)):
  - Caches historically executed jobs, manages unviewed alert notifications with status badges, and automatically initiates background polling when active import tasks are running.

---

#### 4. Cross-Platform Save File Download Helper
- **Cross-Platform Conditional Compilation** ([download_helper.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/utils/download_helper/download_helper.dart), `download_helper_none.dart`, `download_helper_web.dart`):
  - Integrates conditional compilation using `dart.library.html` to separate web actions from mobile/desktop platforms.
  - **Web**: Creates a download link blob directly and clicks it programmatically.
  - **Desktop/Mobile**: Leverages `FilePicker.platform.saveFile()` to let users select output targets and writes raw template bytes.

---

#### 5. UI Views & Visual Enhancements
- **Import Dialog Wizard** ([csv_import_dialog.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/csv_import_dialog.dart)):
  - Implements a responsive 3-step import wizard overlay card with frosted glassmorphic styles.
  - **Step 1 (Idle)**: Interactive Drag-and-Drop / Browse zone using `desktop_drop`, including template download indicators.
  - **Step 2 (Preview & Strategies)**: Displays expandable list cards grouping variants. Renders radio selection strategies (Skip, Overwrite, Custom SKU) and dynamic lists of text fields for custom SKU renaming when the strategy is active.
  - **Step 3 (Progress / Result)**: Live progress bar tracking processed, skipped, and failed count states. Shows summary cards upon completion, showing success colors and detailed logs / warning notifications.
  - **Missing Title Validation**: Updated row errors parsing to explicitly list and highlight in bold red any missing product title rows if handles are present.
  - **Missing Stock Warning Logs**: Rendered warning listings for products imported with missing stock values using the aggregated `noStockLog` in the finished screen.
- **Import History Card** ([import_history_panel.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/widgets/import_history_panel.dart)):
  - Notification-center style overlay panel popping from the toolbar.
  - Shows historic listings of jobs, processing items with live pulsing dots, and triggers detailed modal reports displaying validation warnings or skipped reasons.
  - **Missing Stock History Reports**: Decodes and displays the "Products Without Stock" log section inside the detailed history report modal.
- **Toolbar Integration** ([catalog_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/catalog_view.dart)):
  - Added a frosted "Import CSV" button and a History icon button with unviewed badge counters to the catalog overview header.
- **Always-On Variant Stock Editor** ([product_variants_section.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/widgets/product/product_variants_section.dart)):
  - Removed the `widget.isNewProduct` check on the variants list items card. Stock values are now visible and editable for existing catalog variants as well. Labeled dynamically as "Initial Stock" for new variants or "Stock" for existing variants.

---

#### 6. Root-Level Static Asset Routing & Logging Fixes
- **Static Asset Fallthrough Router** ([ssr_router.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/ssr_router.py)):
  - Resolved root-level single-path parameter routing conflicts where paths matching `/{tenant}` intercepted Flutter web bootstrapping requests (e.g. `/flutter_bootstrap.js`, `/manifest.json`, `/flutter.js`, `/version.json`).
  - Added a check verifying if the requested name matches an existing file in `frontend/build/web` and returning it using `FileResponse`. Added explicit exclusions for `/docs`, `/redoc`, `/openapi.json`, and `/api` endpoints.
- **Windows CLI Unicode Logging Fix** ([router.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/catalog/router.py)):
  - Replaced the `📧` envelope emoji in the terminal logging output of `_send_import_report` to avoid throwing `UnicodeEncodeError` exceptions on Windows consoles utilizing CP1252 character maps.

---

#### 7. Verification & Automated Tests
- **Backend Tests**: Verified using `pytest` on [test_csv_import.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/tests/test_csv_import.py) and [test_bulk_import.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/tests/test_bulk_import.py) covering 13 critical integration scenarios (including strategy logic, stock defaults, and option schema construction). **13/13 tests pass successfully**.
- **Frontend Analysis**: Validated with `flutter analyze` ensuring zero compiler errors or warnings.



