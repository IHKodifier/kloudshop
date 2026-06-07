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


