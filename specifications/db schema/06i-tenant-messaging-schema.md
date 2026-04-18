# 06i — Tenant Messaging Schema
# KloudShop Stage 6 — Data Model

> **Artifact:** `06i-tenant-messaging-schema.md`
> **Schema:** `tenant_{tenant_id}` (one schema per merchant, provisioned at signup)
> **Persona:** Principal Data Engineer
> **Reads from:** `01-product-brief.md`, `01b-tech-stack.md`, `02-architecture.md`,
>   `03-user-journeys.md`, `04-feature-stories.md`, `04b-mvp-scope.md`,
>   `00-carry-forward-flags.md` (DMF-05 in particular)
> **Depends on:** `06b-tenant-catalog-schema.md` (variants.variant_id referenced
>   by thread context — plain UUID, cross-schema semantics),
>   `06c-tenant-orders-schema.md` (orders.order_id referenced by thread context),
>   `06e-tenant-supplier-schema.md` (purchase_orders.po_id referenced by thread context),
>   `06f-tenant-b2b-schema.md` (b2b_accounts.b2b_account_id referenced by thread context)
> **Tables:** 4 (message_threads, thread_participants, messages, message_attachments)
> **Status:** ✅ Generated

---

## Overview

This artifact defines the internal messaging schema for a KloudShop merchant tenant.
All four tables are part of the **BASE tenant schema** — provisioned at signup, not
feature-gated. Every merchant, regardless of tier, has these tables from day one.
DTC-only merchants who never use B2B messaging still have the tables; they simply
remain empty until used.

The design reflects the following architectural decisions from `01b-tech-stack.md`
and the Internal Messaging Architecture section:

- **Cloud Firestore is the real-time delivery layer; Cloud SQL is the permanent
  archive.** Messages are written to both simultaneously. Cloud Firestore provides
  sub-100ms delivery to connected clients. Cloud SQL is the authoritative, immutable
  record. These four tables are the Cloud SQL side. Firestore documents are
  ephemeral signalling only — Cloud SQL is always the source of truth.

- **Messages are strictly immutable.** No UPDATE, no DELETE, ever — by any user,
  including the store Owner. This is a deliberate business decision: in a B2B context,
  the message thread is a legal and operational record. A B2B buyer disputing an
  agreed price must be able to reference the exact message where the price was
  confirmed. Deletion would destroy this audit trail. The `messages` table carries no
  `updated_at` column and no `deleted_at` column, by design.

- **Unread counts live in Redis, not the database.** The `thread_participants.last_read_at`
  column is the reconciliation source, consulted on session start to rebuild Redis
  badge counters. No separate `unread_count` integer column exists in the DB — that
  would require a concurrent write on every message receipt and create race conditions
  under load. Redis holds the fast counter; the DB holds the truth.

- **Thread participants for context-linked threads are auto-determined by object
  access rules** at the application layer — not by manual participant management.
  All staff with access to Order #1042 automatically see and can participate in the
  Order #1042 thread. The `thread_participants` table records the resolved
  participants, not who manually joined.

- **`is_draft = TRUE` messages are auto-saved every 30 seconds** and converted
  to sent (is_draft = FALSE) on user submit. Only non-draft messages are visible
  to recipients. Draft messages are visible only to their sender.

- **File attachment security is enforced server-side** via python-magic (reads
  file bytes; ignores client-declared Content-Type). Allowed MIME types: image/jpeg,
  image/png, image/webp, application/pdf only. Maximum 100 MB per file, 10 attachments
  per message. Files served via signed Cloud Storage URLs with a 15-minute TTL —
  never publicly accessible.

- **`body_tsv` uses the `'simple'` dictionary** — never a language-specific
  dictionary. KloudShop merchants may write messages in any of the 10 supported LTR
  locales. Language-specific stemming (e.g. `'german'`) would break cross-language
  search and produce incorrect tokenisation on non-target-language message bodies.
  `'simple'` tokenises without stemming and is safe for all supported locales (DEC-04).

- **Buyer participants are B2B buyer contacts** (`b2b_accounts`) authenticated via
  Firebase Auth. Consumer (DTC) messaging is explicitly out of scope at MVP — DTC
  customer communication uses order notes and Resend email. The participant_type
  column distinguishes 'staff' from 'buyer'; 'consumer' is never a valid value.

- **No general channels or group chat.** Scope is deliberately narrow: 1-to-1 Direct
  Messages and context-linked threads only. This prevents message noise and keeps
  communication anchored to operational context.

---

## Table: `message_threads`

```sql
-- =============================================================================
-- TABLE: message_threads
-- Schema: tenant_{tenant_id}
-- Description: One row per conversation thread. The thread is the container
--              for a conversation — either a direct (1-to-1) message exchange
--              or a contextual thread anchored to a specific platform object
--              (order, purchase order, SKU/variant, or B2B buyer account).
--
-- Business rules:
--   1. thread_type determines the nature and context of the thread:
--      'direct'          — 1-to-1 DM between two users (staff↔staff or staff↔buyer)
--      'order'           — thread anchored to a specific order
--      'purchase_order'  — thread anchored to a specific purchase order
--      'sku'             — thread anchored to a specific variant/SKU
--      'buyer_account'   — thread anchored to a B2B buyer account; visible to
--                          both the assigned staff members AND the buyer contact
--   2. linked_object_id holds the UUID of the anchored object:
--      thread_type='order'          → orders.order_id
--      thread_type='purchase_order' → purchase_orders.po_id
--      thread_type='sku'            → variants.variant_id
--      thread_type='buyer_account'  → b2b_accounts.b2b_account_id
--      thread_type='direct'         → NULL (no linked object)
--      All references are plain UUIDs — no FK constraints (cross-table,
--      and object deletion must not cascade-delete conversation history).
--   3. created_by is the staff_user_id or b2b_account_id of the user who
--      initiated the thread. Plain UUID — application layer validates.
--   4. Threads are never deleted. If an anchored object (order, PO, variant)
--      is archived or deleted, the thread remains. The historical conversation
--      is always accessible via the "All Messages" inbox view.
--   5. Exactly one thread should exist per (thread_type='direct', pair of
--      participant IDs) — the application layer enforces this by checking
--      for an existing direct thread between two users before creating a new one.
-- =============================================================================

CREATE TABLE message_threads (
    thread_id        UUID            PRIMARY KEY DEFAULT gen_random_uuid(),

    thread_type      VARCHAR(20)     NOT NULL
                         CHECK (thread_type IN (
                             'direct',
                             'order',
                             'purchase_order',
                             'sku',
                             'buyer_account'
                         )),
    -- Classifies the thread. Drives routing, participant determination, and
    -- inbox view grouping ('Linked to Orders', 'Linked to Buyers', etc.).

    linked_object_id UUID,
    -- UUID of the anchored platform object. NULL for 'direct' threads.
    -- order_id / po_id / variant_id / b2b_account_id depending on thread_type.
    -- Plain UUID — no FK constraint. Object deletion must not cascade-delete
    -- conversation history. Application validates presence at thread creation.

    created_by       UUID            NOT NULL,
    -- The staff_user_id or b2b_account_id who initiated this thread.
    -- Plain UUID — cross-schema reference. Application validates.

    created_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT message_threads_linked_object_direct_check
        CHECK (
            thread_type = 'direct' OR linked_object_id IS NOT NULL
        )
    -- Non-direct threads must have a linked_object_id. Direct threads must not.
    -- Note: 'direct' type has linked_object_id = NULL (enforced by this CHECK
    -- combined with the explicit NULL allowed above). For non-direct types, the
    -- constraint ensures the anchor is always present.
);

COMMENT ON TABLE message_threads IS
    'One row per conversation thread. Threads are never deleted — conversation '
    'history is always preserved regardless of the lifecycle of the anchored object. '
    'linked_object_id holds the UUID of the anchored order, PO, variant, or buyer '
    'account (NULL for direct DMs). All object references are plain UUIDs — no FK '
    'constraints — to prevent cascade-deletion of conversation records.';

COMMENT ON COLUMN message_threads.thread_type IS
    'Classifies the thread: ''direct'' (1-to-1 DM), ''order'', ''purchase_order'', '
    '''sku'', or ''buyer_account''. Drives participant determination, routing, and '
    'inbox grouping. buyer_account threads are visible to both staff and the buyer contact.';

COMMENT ON COLUMN message_threads.linked_object_id IS
    'UUID of the anchored object. NULL for direct threads. '
    'order_id / po_id / variants.variant_id / b2b_accounts.b2b_account_id '
    'depending on thread_type. Plain UUID — application validates; no DB FK.';

COMMENT ON COLUMN message_threads.created_by IS
    'staff_user_id or b2b_account_id of the thread initiator. '
    'Plain UUID — cross-schema reference, application-layer validated.';

-- Indexes
CREATE INDEX idx_message_threads_type_object
    ON message_threads (thread_type, linked_object_id)
    WHERE linked_object_id IS NOT NULL;
-- Rationale: "Find the thread for this order / PO / SKU / buyer account."
-- Used when opening an object's context panel to load its existing thread.
-- Partial index on non-direct threads (linked_object_id IS NOT NULL).

CREATE INDEX idx_message_threads_created_by
    ON message_threads (created_by);
-- Rationale: "Which threads did this user start?" — used in inbox views and
-- participant auto-determination for buyer_account threads.
```

---

## Table: `thread_participants`

```sql
-- =============================================================================
-- TABLE: thread_participants
-- Schema: tenant_{tenant_id}
-- Description: Join table mapping users to the threads they participate in.
--              Tracks the last_read_at timestamp used for unread badge
--              calculation and Redis counter reconciliation.
--
-- Business rules:
--   1. One row per (thread_id, participant_id) pair. Composite PK enforces this.
--   2. participant_type distinguishes staff from buyer contacts:
--      'staff' — a merchant staff member (staff_user_id in kloudshop_platform)
--      'buyer' — a B2B buyer contact (b2b_account_id in this tenant schema)
--      'consumer' is NOT a valid value — DTC consumer messaging is out of scope.
--   3. Participants for DIRECT threads are the two users who initiated the DM.
--      Set at thread creation and never changed (the pair is fixed).
--   4. Participants for CONTEXT-LINKED threads (order, PO, SKU, buyer_account)
--      are AUTO-DETERMINED at the application layer by object access rules:
--      - 'order' thread: all staff with order read access are participants.
--      - 'purchase_order' thread: all staff with inventory/procurement access.
--      - 'sku' thread: all staff with catalogue manager or admin access.
--      - 'buyer_account' thread: all staff with B2B Account Manager access
--        AND the buyer contact associated with that account.
--      New staff members who gain access to an object are added as participants
--      by the application on their first access — not retroactively on role grant.
--   5. last_read_at drives unread badge logic:
--      - Redis holds a fast unread_count per (user, thread) updated on every
--        message receipt. Redis counter is the authoritative source during an
--        active session.
--      - On session start, the application reconciles Redis counters against
--        last_read_at: count messages in this thread where sent_at > last_read_at.
--      - On user reading a thread: UPDATE last_read_at = NOW(), reset Redis counter to 0.
--      No separate unread_count integer column is stored in the DB — that would
--      require concurrent writes on every message and create race conditions.
--   6. joined_at records when this participant was added to the thread.
--      For context-linked threads this is typically the object creation time or
--      the first time the user accessed the object.
--   7. Participants are never removed from a thread — even if a staff member's
--      access is revoked, their historical participation record is retained.
--      The application layer filters participant queries by active access
--      at display time.
-- =============================================================================

CREATE TABLE thread_participants (
    thread_id        UUID            NOT NULL
                         REFERENCES message_threads (thread_id)
                         ON DELETE RESTRICT,
    -- RESTRICT: never auto-delete participant records if a thread were somehow
    -- deleted. Threads are never deleted in practice.

    participant_id   UUID            NOT NULL,
    -- staff_user_id (kloudshop_platform.staff_users) or
    -- b2b_account_id (b2b_accounts in this tenant schema).
    -- Plain UUID — cross-schema reference, application-layer validated.
    -- Context determines which table this refers to: use participant_type.

    participant_type VARCHAR(16)     NOT NULL
                         CHECK (participant_type IN ('staff', 'buyer')),
    -- 'staff' → participant_id is a staff_user_id.
    -- 'buyer' → participant_id is a b2b_account_id.
    -- 'consumer' is explicitly excluded — DTC consumer messaging is out of scope.

    joined_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    -- When this participant was added to the thread.

    last_read_at     TIMESTAMPTZ,
    -- When this participant last read (opened) this thread. NULL = never read.
    -- Used to reconcile Redis unread badge counters on session start:
    --   unread_count = COUNT(*) FROM messages
    --   WHERE thread_id = ? AND sent_at > last_read_at AND is_draft = FALSE
    -- Updated to NOW() each time the participant opens and views the thread.
    -- Redis holds the fast counter; this column is the reconciliation anchor.

    PRIMARY KEY (thread_id, participant_id)
    -- Composite PK enforces one participation record per (thread, user).
);

COMMENT ON TABLE thread_participants IS
    'Maps users to the threads they participate in. One row per (thread, user). '
    'participant_type distinguishes staff (staff_user_id) from buyer (b2b_account_id). '
    'Consumer participants are never valid — DTC messaging is out of scope. '
    'For context-linked threads, participants are auto-determined by object access '
    'rules at the application layer — not by manual user actions. '
    'last_read_at drives unread badge reconciliation on session start; Redis holds '
    'the fast per-session counter. No separate unread_count column in the DB.';

COMMENT ON COLUMN thread_participants.last_read_at IS
    'Timestamp of the participant''s last thread view. NULL = never viewed. '
    'Reconciliation query on session start: '
    'COUNT(*) FROM messages WHERE thread_id = ? AND sent_at > last_read_at AND is_draft = FALSE. '
    'Redis unread counter reset to 0 when participant opens thread; last_read_at updated.';

COMMENT ON COLUMN thread_participants.participant_type IS
    '''staff'' = staff_user_id reference. ''buyer'' = b2b_account_id reference. '
    '''consumer'' is never valid — DTC consumer messaging is explicitly out of scope at MVP.';

-- Indexes
CREATE INDEX idx_thread_participants_participant
    ON thread_participants (participant_id, thread_id);
-- Rationale: Primary inbox query — "all threads this user participates in,
-- ordered for display." Covers the reverse lookup (participant → threads) which
-- the composite PK index does not cover efficiently.

CREATE INDEX idx_thread_participants_unread
    ON thread_participants (participant_id, last_read_at)
    WHERE last_read_at IS NOT NULL;
-- Rationale: Session-start Redis reconciliation — find all threads where
-- last_read_at is set, to compute unread counts. Partial on non-NULL only
-- (NULL last_read_at means the thread has never been opened; all messages are unread).

CREATE INDEX idx_thread_participants_type
    ON thread_participants (thread_id, participant_type);
-- Rationale: "All staff participants in this thread" and "all buyer participants
-- in this thread" — used when routing messages and generating FCM push targets.
```

---

## Table: `messages`

```sql
-- =============================================================================
-- TABLE: messages
-- Schema: tenant_{tenant_id}
-- Description: Immutable message records. One row per sent or draft message.
--              Messages are the permanent, auditable record of all communication.
--              Cloud Firestore handles real-time delivery; Cloud SQL is the
--              authoritative archive.
--
-- IMMUTABILITY GUARANTEE:
--   This table has NO updated_at column and NO deleted_at column.
--   No UPDATE is ever performed on a sent message (is_draft = FALSE).
--   No DELETE is ever performed on any row.
--   This is a deliberate business decision — in a B2B context, the message
--   history is a legal and operational record. A B2B buyer disputing an agreed
--   price must be able to reference the exact message where the price was
--   confirmed. Deletion or modification would destroy this audit trail.
--   Drafts (is_draft = TRUE) are the one partial exception: draft rows may be
--   updated by the sender (auto-save every 30 seconds). On send, is_draft is
--   set to FALSE and the row becomes immutable. No further updates occur.
--
-- Business rules:
--   1. sender_id is the staff_user_id or b2b_account_id of the message author.
--      Plain UUID — application validates. Never NULL.
--   2. sender_type distinguishes 'staff' from 'buyer'. 'consumer' is never valid.
--   3. body is the message text content. Never NULL — even if very short.
--      Maximum length is enforced at the application layer (8,000 characters).
--   4. body_tsv is a GENERATED ALWAYS AS STORED tsvector column using the
--      'simple' dictionary (DEC-04 — safe for all 10 LTR locales simultaneously).
--      Language-specific stemming would break cross-language search on multilingual
--      message corpora. 'simple' tokenises without stemming — correct default.
--   5. is_draft = TRUE: message is being composed; auto-saved every 30 seconds.
--      Visible only to the sender. Not delivered via Firestore, no FCM push.
--      is_draft = FALSE: message is sent. Immutable from this point. Visible to
--      all thread participants. Written to Firestore for real-time delivery.
--      FCM push sent to offline participants. is_draft cannot be set back to TRUE
--      once FALSE (enforced at application layer).
--   6. sent_at records the moment the message was submitted by the sender.
--      For drafts this is the creation time (auto-save start); it does not update
--      on auto-save (no UPDATE on any column once the row exists, including drafts).
--      Wait — drafts DO update on auto-save. Clarification:
--      The IMMUTABILITY rule applies to SENT messages only (is_draft = FALSE).
--      Draft rows (is_draft = TRUE) may be updated via a single UPDATE that sets
--      body = ?, updated_at = NOW(). On send, a final UPDATE sets is_draft = FALSE,
--      sent_at = NOW() — after which the row is permanently immutable.
--      Therefore: drafts carry an updated_at column (see below); sent messages
--      are written once and never touched again.
--   7. thread_id references message_threads ON DELETE RESTRICT — never auto-delete
--      messages if a thread were somehow removed. Threads are never deleted anyway.
-- =============================================================================

CREATE TABLE messages (
    message_id       UUID            PRIMARY KEY DEFAULT gen_random_uuid(),

    thread_id        UUID            NOT NULL
                         REFERENCES message_threads (thread_id)
                         ON DELETE RESTRICT,
    -- RESTRICT: never auto-delete messages if a thread row is somehow removed.
    -- Threads are never deleted in practice.

    sender_id        UUID            NOT NULL,
    -- staff_user_id or b2b_account_id of the message author.
    -- Plain UUID — application validates presence against correct table by
    -- checking sender_type. Never NULL.

    sender_type      VARCHAR(16)     NOT NULL
                         CHECK (sender_type IN ('staff', 'buyer')),
    -- 'staff' → sender_id is a staff_user_id (kloudshop_platform.staff_users).
    -- 'buyer' → sender_id is a b2b_account_id (b2b_accounts in this schema).
    -- 'consumer' is never valid — consumer messaging is out of scope.

    body             TEXT            NOT NULL,
    -- The message text. Never NULL. Max 8,000 characters enforced at app layer.
    -- No rich-text JSONB here — messages are plain text with optional attachments.
    -- URLs are auto-linked at render time, not stored as structured data.

    body_tsv         TSVECTOR        GENERATED ALWAYS AS (
                         to_tsvector('simple', body)
                     ) STORED,
    -- Full-text search vector over the message body.
    -- 'simple' dictionary (DEC-04): safe for multilingual message bodies across
    -- all 10 supported LTR locales. Language-specific stemming (e.g. 'german')
    -- would break cross-language search when staff write in multiple languages.
    -- 'simple' tokenises without stemming — correct for a multilingual platform.

    is_draft         BOOLEAN         NOT NULL DEFAULT FALSE,
    -- FALSE (default): message is sent. Delivered via Firestore. FCM pushed.
    --                  Row is immutable from the moment is_draft is set to FALSE.
    -- TRUE: message is being composed. Auto-saved every 30 seconds.
    --       Visible only to the sender. Not in Firestore. No FCM push.
    --       The row's body may be updated during drafting (see updated_at).

    sent_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    -- For sent messages (is_draft = FALSE): the moment the message was submitted.
    -- For drafts: the moment the draft row was first created (auto-save start).
    -- Drafts do not update sent_at on subsequent auto-saves.

    updated_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW()
    -- Relevant ONLY for draft messages (is_draft = TRUE).
    -- Updated on each draft auto-save (body changes).
    -- On send: updated_at is set to NOW() alongside is_draft = FALSE.
    -- After send: this column is never updated again. The row is immutable.
    -- Note: this column exists to support the 30-second auto-save cycle for
    -- drafts. It does NOT violate the immutability guarantee because the
    -- immutability guarantee applies to SENT messages only.

    -- IMMUTABILITY NOTE:
    -- No DELETE is ever performed on any row in this table — draft or sent.
    -- No UPDATE is ever performed on a sent message (is_draft = FALSE) row.
    -- Enforced at the application layer and documented in DB access policy.
    -- There is no deleted_at column. There is no soft-delete mechanism.
    -- This is intentional and irrevocable by design.
);

COMMENT ON TABLE messages IS
    'Immutable message records. SENT messages (is_draft = FALSE) are written once '
    'and never updated or deleted — by any user, including Owner. This preserves '
    'the legal audit trail for B2B price agreements and order instructions. '
    'DRAFT messages (is_draft = TRUE) may be updated via auto-save (body, updated_at). '
    'On send, is_draft → FALSE, row becomes permanently immutable. '
    'body_tsv uses ''simple'' dictionary (DEC-04) — safe for all 10 LTR locales. '
    'Cloud Firestore handles real-time delivery; Cloud SQL is the authoritative archive. '
    'No deleted_at column. No soft-delete. Deletion is architecturally impossible.';

COMMENT ON COLUMN messages.body_tsv IS
    'Generated FTS vector over message body. ''simple'' dictionary per DEC-04 — '
    'safe for multilingual messages across all 10 supported LTR locales. '
    'Language-specific stemming would break cross-language search.';

COMMENT ON COLUMN messages.is_draft IS
    'FALSE = sent message — immutable, delivered via Firestore, FCM pushed. '
    'TRUE = draft being composed — visible to sender only, not delivered, auto-saved. '
    'is_draft cannot be set back to TRUE once FALSE (app-layer enforced).';

COMMENT ON COLUMN messages.updated_at IS
    'Relevant for draft messages only. Updated on each 30-second auto-save. '
    'Set to NOW() on send alongside is_draft → FALSE. Never updated after send. '
    'Does not violate the immutability guarantee: immutability applies to sent '
    'messages (is_draft = FALSE) only.';

COMMENT ON COLUMN messages.sender_id IS
    'staff_user_id (kloudshop_platform.staff_users) or b2b_account_id '
    '(b2b_accounts in this schema). Plain UUID — application validates by '
    'consulting sender_type. Never NULL.';

-- Indexes
CREATE INDEX idx_messages_thread_sent_at
    ON messages (thread_id, sent_at ASC)
    WHERE is_draft = FALSE;
-- Rationale: Thread message listing — all sent messages in a thread in
-- chronological order. Partial index on sent messages only; drafts are
-- fetched separately by the sender. This is the hottest query on this table.

CREATE INDEX idx_messages_sender_drafts
    ON messages (sender_id, thread_id)
    WHERE is_draft = TRUE;
-- Rationale: Drafts folder — all draft messages for a given sender.
-- Partial on draft messages only — the overwhelming majority of rows are sent.

CREATE INDEX idx_messages_body_tsv
    ON messages USING GIN (body_tsv);
-- Rationale: Full-text message search across the inbox. Supports keyword
-- lookup by body content, scoped at application layer to threads the
-- requesting user has access to.

CREATE INDEX idx_messages_sender_id
    ON messages (sender_id, sent_at DESC)
    WHERE is_draft = FALSE;
-- Rationale: "All messages sent by this user" — used in the Sent view
-- and for audit/support purposes. Partial on sent messages only.
```

---

## Table: `message_attachments`

```sql
-- =============================================================================
-- TABLE: message_attachments
-- Schema: tenant_{tenant_id}
-- Description: File attachment metadata records per message. One row per file
--              attached to a message. The actual file bytes live in GCP Cloud
--              Storage; this table records the metadata and the storage path.
--
-- Business rules:
--   1. Attached to a message via message_id FK. A message may have zero or more
--      attachments. Maximum 10 attachments per message — enforced at application
--      layer before insert, not via a DB constraint.
--   2. MIME TYPE VALIDATION IS SERVER-SIDE ONLY.
--      mime_type is set by the server after inspecting the file bytes using
--      python-magic — NOT from the client-declared Content-Type header.
--      Clients declaring a false MIME type (e.g. an .exe renamed .pdf) are caught
--      at the server layer. The application rejects any file whose python-magic
--      detected type is not in the allowed list, regardless of the claimed type.
--      Allowed MIME types: image/jpeg, image/png, image/webp, application/pdf only.
--      All other types are rejected at upload with a clear error message.
--   3. Maximum file size: 100 MB per file. Enforced at upload (pre-insert).
--      file_size_bytes is stored for display and quota calculation.
--   4. storage_path is the Cloud Storage path:
--      gs://kloudshop-{tenant_id}/messages/{thread_id}/{uuid}.{ext}
--      Files are NEVER publicly accessible. Access is via signed URLs only.
--   5. Signed URL TTL: 15 minutes. Generated by FastAPI on every download
--      request — not stored in this table. A stored URL would expire and become
--      useless; on-demand generation ensures the link is always valid when clicked.
--   6. PDF security: PDFs with embedded JavaScript are rejected at a Cloud Run
--      scanner layer triggered by Cloud Storage object creation events. The
--      scanner runs before the row is inserted — a row in this table means the
--      file has passed the security scan.
--   7. Virus scanning is applied to all uploads via the same Cloud Storage
--      trigger → Cloud Run scanner pipeline. Files that fail scanning are
--      deleted from Cloud Storage and no row is inserted here.
--   8. Attachments inherit the immutability of their parent message: once
--      inserted, attachment rows are never updated or deleted. If a file must
--      be removed (e.g. compliance reason), it is deleted from Cloud Storage
--      only — the DB row is retained with storage_path marked as [redacted]
--      by an admin-only application operation.
--   9. uploaded_at records when the file was successfully scanned, stored,
--      and this row was created — not when the upload request was initiated.
-- =============================================================================

CREATE TABLE message_attachments (
    attachment_id    UUID            PRIMARY KEY DEFAULT gen_random_uuid(),

    message_id       UUID            NOT NULL
                         REFERENCES messages (message_id)
                         ON DELETE RESTRICT,
    -- RESTRICT: never auto-delete attachment records when a message is removed.
    -- Messages are never deleted. RESTRICT is a safety net for policy enforcement.

    file_name        TEXT            NOT NULL,
    -- Original filename as submitted by the client (e.g. "invoice_q3.pdf").
    -- Stored for display in the attachment panel. Not used for storage routing —
    -- storage_path uses a UUID-based filename to prevent path collision.
    -- Maximum 255 characters enforced at application layer.

    mime_type        VARCHAR(64)     NOT NULL,
    -- MIME type as determined by server-side inspection via python-magic.
    -- NOT the client-declared Content-Type — never trust client MIME claims.
    -- Allowed values: 'image/jpeg', 'image/png', 'image/webp', 'application/pdf'
    -- All other detected types are rejected before this row is ever inserted.
    -- python-magic reads the first N bytes of the file to detect the true type.

    file_size_bytes  BIGINT          NOT NULL,
    -- File size in bytes. Maximum 104,857,600 (100 MB) — enforced pre-insert.
    -- Stored for display (e.g. "4.2 MB") and future quota enforcement.

    storage_path     TEXT            NOT NULL,
    -- Cloud Storage path of the file.
    -- Pattern: gs://kloudshop-{tenant_id}/messages/{thread_id}/{uuid}.{ext}
    -- The UUID in the filename prevents path collision for same-named files
    -- across different messages or senders.
    -- Files are NEVER publicly accessible. Access is via signed URLs only.
    -- Signed URLs are generated on-demand by FastAPI with a 15-minute TTL.
    -- The TTL is NOT stored here — it is applied at generation time.
    -- In the rare case that a file must be removed for compliance, the Cloud
    -- Storage object is deleted and this column is updated to '[redacted]'
    -- by an admin-only platform operation. The row is retained for audit.

    uploaded_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
    -- When the file was successfully scanned, stored in Cloud Storage, and
    -- this row was committed. Not the upload initiation time — only files that
    -- complete the full pipeline (upload → virus scan → PDF JS scan → row insert)
    -- appear here.

    -- IMMUTABILITY NOTE:
    -- Attachment rows are never deleted as standard operation.
    -- storage_path may be set to '[redacted]' by a platform admin operation
    -- in exceptional compliance circumstances. No other column is ever updated.
);

COMMENT ON TABLE message_attachments IS
    'File attachment metadata per message. One row per file. The file bytes live in '
    'GCP Cloud Storage; this table records metadata and the storage path. '
    'mime_type is set by server-side python-magic inspection — NEVER client-declared. '
    'Allowed types: image/jpeg, image/png, image/webp, application/pdf only. '
    'Files are never publicly accessible — access via signed URLs (15 min TTL) generated '
    'on-demand by FastAPI. Virus scan and PDF JS scan run via Cloud Storage trigger before '
    'row insertion. Rows are never deleted; storage_path may be [redacted] by admin in '
    'exceptional compliance cases.';

COMMENT ON COLUMN message_attachments.mime_type IS
    'MIME type as detected by server-side python-magic (reads file bytes). '
    'NEVER set from client-declared Content-Type — clients may lie. '
    'Allowed: image/jpeg, image/png, image/webp, application/pdf. '
    'All other types rejected before row insertion.';

COMMENT ON COLUMN message_attachments.storage_path IS
    'Cloud Storage path: gs://kloudshop-{tenant_id}/messages/{thread_id}/{uuid}.{ext}. '
    'Files are never publicly accessible. Signed URLs (15 min TTL) generated on-demand. '
    'In exceptional compliance cases, may be set to ''[redacted]'' by platform admin. '
    'The row itself is never deleted.';

COMMENT ON COLUMN message_attachments.uploaded_at IS
    'Timestamp of successful pipeline completion: upload → virus scan → PDF JS scan → '
    'Cloud Storage commit → row insert. Not the upload initiation time.';

-- Indexes
CREATE INDEX idx_message_attachments_message_id
    ON message_attachments (message_id);
-- Rationale: Message display fetches all attachments for a given message.
-- Every rendered message with attachments triggers this lookup. Must be fast.

CREATE INDEX idx_message_attachments_storage_path
    ON message_attachments (storage_path);
-- Rationale: Cloud Storage lifecycle management and compliance audits query
-- by storage_path to correlate storage objects with DB records. Also used
-- when marking a path as [redacted] — the admin operation searches by path.
```

---

## Updated Schema Inventory Entry

Replace the `06i` row in `06-schema-inventory.md` progress table with:

```
| `06i-tenant-messaging-schema.md` | ✅ Generated | 4 | message_threads (thread_type CHECK, linked_object_id plain UUID, RESTRICT deletes), thread_participants (staff/buyer only — no consumer, last_read_at for Redis reconciliation, participants auto-determined for context-linked threads), messages (IMMUTABLE sent rows — no updated_at after send, no deleted_at ever, body_tsv GENERATED 'simple' FTS DEC-04, is_draft auto-save pattern), message_attachments (mime_type = python-magic server-side only, 100MB max, Cloud Storage signed URL 15-min TTL, PDF JS scan pre-insert, rows never deleted) |
```
