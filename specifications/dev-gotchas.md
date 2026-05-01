# KloudShop Development Gotchas & Knowledge Store

This document tracks critical technical hurdles, root causes, and architectural workarounds identified during the development of the KloudShop platform. Use this as a reference to avoid repeating common pitfalls in future sprints.

---

## 1. Environment & IDE Configuration

### 🔴 The Admin/Chrome Sandbox Conflict
**Issue:** Running VS Code as an Administrator (often required for GCP SDK operations) causes Flutter Web debugging to hang indefinitely on a horizontal loading bar.
**Root Cause:** Chrome's security sandbox refuses to initialize if its parent process is elevated. This prevents the Dart debugger from attaching to the browser.
**Fix:** 
- Fix file permissions on the `Google Cloud SDK` installation folder (using `icacls`) so that the `gcloud` tools can be run by a normal user.
- **Never** run the IDE as Administrator unless absolutely necessary.
- Use the `web-server` device in `launch.json` for the most reliable IDE launch.

### 🔴 IPv6 "Localhost" Connection Refusal
**Issue:** Frontend requests to `http://localhost:8000` fail with `Failed to fetch` even when the server is healthy.
**Root Cause:** Modern browsers resolve `localhost` to IPv6 `::1`, while Uvicorn/FastAPI defaults to IPv4 `127.0.0.1`.
**Fix:** Hardcode the API base URL to use the explicit IPv4 address: `http://127.0.0.1:8000`.

---

## 2. FastAPI & Backend Architecture

### 🔴 Async Event Loop Freezes
**Issue:** Long-running operations (like GCP provisioning scripts) cause the entire API to become unresponsive, leading to network timeouts and "Failed to fetch" errors.
**Root Cause:** Calling synchronous blocking code (like `subprocess.run`) inside an `async def` route freezes the main event loop.
**Fix:** Always wrap blocking shell scripts or heavy I/O in `await anyio.to_thread.run_sync()`.

### 🔴 The CORS Wildcard Rejection
**Issue:** 401 Unauthorized or 500 Internal Server Error responses result in a "CORS Error" in the browser, masking the real error.
**Root Cause:** Combining `allow_origins=["*"]` with `allow_credentials=True` is illegal in many browsers. Furthermore, FastAPI's middleware can fail to properly reflect the origin during early exceptions, falling back to the forbidden `*` wildcard.
**Fix:** Use `allow_origin_regex` to dynamically mirror the requesting local port:
```python
allow_origin_regex=r"https?://(?:localhost|127\.0\.0\.1)(?::\d+)?"
```

### 🔴 Missing Tables in Local SQLite
**Issue:** Switching from PostgreSQL to SQLite (via `TESTING=1`) results in "no such table" errors for core platform models.
**Root Cause:** Alembic migrations are often bypassed for SQLite to avoid schema-creation conflicts (SQLite doesn't support schemas).
**Fix:** Implement automatic table creation in the FastAPI `lifespan` event specifically for SQLite runs:
```python
if "sqlite" in engine.url.drivername:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
```

---

## 3. Authentication & Firebase

### 🔴 JWT "Token Used Too Early"
**Issue:** `ApiService.getMe` returns a 401 Unauthorized immediately after a fresh login.
**Root Cause:** Clock skew. If the local backend server's clock is even 1 second behind Google's Auth servers, the token's `iat` (issued at) time will be in the "future," and the Firebase Admin SDK will strictly reject it.
**Fix:** If a 401 occurs instantly after login, wait 2–3 seconds and retry. Ensure system clocks are synced via NTP.

---

## 4. UI & Assets

### 🔴 404 Asset Loading Failures
**Issue:** Console logs filled with 404 errors for assets like `landing_hero_dark.png`.
**Root Cause:** Incorrect pathing in `pubspec.yaml` or missing conditional logic for Dark Mode asset variants.
**Fix:** Verify asset declarations in `pubspec.yaml` and ensure the `web/` directory is correctly mapped in the build configuration.
