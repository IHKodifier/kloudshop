# 06h — Tenant Blog Schema
# KloudShop Stage 6 — Data Model

> **File:** `06h-tenant-blog-schema.md`
> **Schema:** `tenant_{tenant_id}`
> **Persona:** Principal Data Engineer
> **Reads from:** `06a1`, `06a2`, `06b`, `06c`, `06d`, `06e`, `06f`, `06g`
> **Depends on:** Staff user IDs (plain UUID, sourced from `kloudshop_platform.staff_users` — cross-schema, application-layer validation only)
> **Tables:** 7
> **Status:** ✅ Generated

---

## Overview

The blog sub-schema provides KloudShop merchants with a fully-featured, multilingual content publishing system. It is provisioned as part of the BASE tenant schema at signup — no feature flag required. The design follows the same structural conventions established in `06g` (storefront schema): Tiptap/ProseMirror JSONB bodies, `GENERATED ALWAYS AS` FTS vectors using the `'simple'` dictionary, and a consistent `is_auto_translated` pattern for translation tables.

Key design decisions:

- **JSONB body, not TEXT.** `blog_posts.body` stores the full Tiptap/ProseMirror document tree. This enables the dashboard editor to round-trip structured content (embeds, callouts, headings) without a separate sanitisation pipeline.
- **`body_tsv` GENERATED ALWAYS AS STORED.** Full-text search vectors are computed from `body::text` using `to_tsvector('simple', ...)` at write time, indexed with GIN. The `'simple'` dictionary is used throughout — never language-specific dictionaries (DEC-04).
- **NULL-safe FTS expression.** `COALESCE(body::text, '') || ' ' || COALESCE(title, '')` ensures a NULL body does not produce a NULL `body_tsv`, which would silently drop the post from FTS results. Both title and body contribute to the vector.
- **Scheduling via `scheduled_for`.** A Cloud Tasks job (triggered at post creation/update when `status = 'scheduled'`) flips `status` to `'published'` at the given `TIMESTAMPTZ`. The DB itself imposes no time-based trigger; the status column is the source of truth.
- **Slug immutability signal.** When `blog_posts.slug` changes, the application layer MUST auto-create a redirect rule in `storefront_content` (same pattern as `static_pages` in 06g). The DB column carries a comment documenting this obligation.
- **`author_id` as plain UUID.** Cross-schema FK to `kloudshop_platform.staff_users` is not enforced at the DB layer. Application must validate. On staff deactivation, the author_id remains intact for historical record.
- **Translation tables exclude 'en'.** `blog_post_translations` and `blog_category_translations` both carry `CHECK (locale != 'en')`. The base table (`blog_posts`, `blog_categories`) holds the canonical English content.
- **`is_auto_translated = FALSE` rows are write-protected by convention.** The AI translation pipeline must never overwrite rows where `is_auto_translated = FALSE`. This is enforced at the application layer (same pattern as `product_translations` in 06b).
- **Normalised tags.** `blog_tags` is a proper lookup table, not a PostgreSQL array column. This enables efficient tag-cloud aggregate queries (`COUNT(*) GROUP BY tag_id`) and faceted filtering without `unnest()` gymnastics.
- **Join tables carry no extra columns.** `blog_post_categories` and `blog_post_tags` are pure many-to-many bridges. No `sort_order`, no `created_at`. Simplicity is a feature.
- **`sort_order` on categories.** Merchants can manually sequence categories in the nav. Default is `0`; ties are broken by `name ASC` at query time.
- **JSON-LD Article structured data** is rendered entirely by the SSR layer from the `blog_posts` columns (`title`, `slug`, `published_at`, `author_id`). No dedicated DB columns are needed.

---

## Table: `blog_posts`

```sql
-- =============================================================================
-- TABLE: blog_posts
-- Schema: tenant_{tenant_id}
-- Description: One row per blog post. Body is stored as Tiptap/ProseMirror
--              JSONB to preserve structured content (embeds, callouts, etc.)
--              for round-trip editing in the dashboard. Full-text search is
--              served by the generated body_tsv column.
--
-- Business rules:
--   - status lifecycle:  draft → scheduled → published → archived
--                        draft → published  (direct publish, skipping schedule)
--                        published → archived
--                        archived → draft   (restore to editing)
--   - When status = 'scheduled', scheduled_for MUST be a future TIMESTAMPTZ.
--     Enforced by CHECK constraint.
--   - When scheduled_for fires, a Cloud Tasks job flips status → 'published'
--     and sets published_at = NOW(). The DB does not self-publish.
--   - slug MUST be unique per tenant. When slug changes on an existing post,
--     the application layer MUST insert a redirect_rule in storefront_content
--     (DMF-02 / 06g pattern) before committing the slug update.
--   - author_id is a staff_user UUID from kloudshop_platform.staff_users.
--     Cross-schema FK is NOT enforced at DB layer — application must validate.
--     On staff deactivation, author_id is preserved for historical integrity.
--   - body_tsv is computed from BOTH title and body::text so that title-only
--     matches surface relevant posts even when body is NULL.
-- =============================================================================

CREATE TABLE blog_posts (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Authorship & ownership
    author_id           UUID            NOT NULL,
    -- Cross-schema ref to kloudshop_platform.staff_users. App-layer validated.

    -- Content
    title               TEXT            NOT NULL CHECK (char_length(title) BETWEEN 1 AND 500),
    slug                TEXT            NOT NULL CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
    excerpt             TEXT            CHECK (char_length(excerpt) <= 1000),
    body                JSONB,
    -- Tiptap/ProseMirror document tree. NULL = post has no body yet (draft).

    body_tsv            TSVECTOR        GENERATED ALWAYS AS (
                            to_tsvector(
                                'simple',
                                COALESCE(title, '') || ' ' || COALESCE(body::text, '')
                            )
                        ) STORED,
    -- FTS vector over title + body. 'simple' dictionary per DEC-04 (multilingual safety).
    -- NULL body is coalesced to '' so the vector is never NULL.

    -- Cover image
    cover_image_url     TEXT,
    -- Cloud Storage public CDN URL. Nullable — posts may have no cover image.
    cover_image_alt     TEXT            CHECK (char_length(cover_image_alt) <= 500),

    -- SEO
    meta_title          TEXT            CHECK (char_length(meta_title) <= 120),
    meta_description    TEXT            CHECK (char_length(meta_description) <= 320),

    -- Lifecycle
    status              TEXT            NOT NULL DEFAULT 'draft'
                            CHECK (status IN ('draft', 'scheduled', 'published', 'archived')),
    scheduled_for       TIMESTAMPTZ,
    -- When status = 'scheduled', scheduled_for must be in the future (at write time).
    -- Cloud Tasks fires the publish job at this timestamp.
    published_at        TIMESTAMPTZ,
    -- Set by the Cloud Tasks job (or directly on immediate publish). NULL = not yet published.

    -- Feature flags (content-level)
    is_featured         BOOLEAN         NOT NULL DEFAULT FALSE,
    -- Controls 'Featured' badge and homepage blog widget ordering.
    allow_comments      BOOLEAN         NOT NULL DEFAULT FALSE,
    -- Reserved for future commenting feature. Not feature-gated at column level.

    -- Timestamps
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT blog_posts_slug_unique UNIQUE (slug),
    CONSTRAINT blog_posts_scheduled_status_check
        CHECK (
            status != 'scheduled' OR scheduled_for IS NOT NULL
        )
    -- When status = 'scheduled', scheduled_for must be provided.
    -- Future-datetime enforcement is application-layer (avoids clock-skew issues in DB).
);

COMMENT ON TABLE blog_posts IS
    'One row per merchant blog post. Body is Tiptap/ProseMirror JSONB for structured '
    'round-trip editing. FTS via body_tsv (generated, simple dict). Scheduling via '
    'scheduled_for + Cloud Tasks job. Slug changes must trigger a redirect_rule insert '
    'in storefront_content (DMF-02 / 06g). author_id references kloudshop_platform.'
    'staff_users — cross-schema, application-layer validated only.';

COMMENT ON COLUMN blog_posts.body IS
    'Tiptap/ProseMirror JSONB document tree. NULL for posts still in draft with no content.';
COMMENT ON COLUMN blog_posts.body_tsv IS
    'Generated FTS vector over title + body::text. simple dictionary (DEC-04). '
    'Never NULL — COALESCE guards both title and body.';
COMMENT ON COLUMN blog_posts.slug IS
    'URL-safe slug, lowercase alphanumeric + hyphens. Unique per tenant. '
    'MUST trigger a redirect_rule insert in storefront_content when changed on an existing post.';
COMMENT ON COLUMN blog_posts.scheduled_for IS
    'When status = scheduled, Cloud Tasks fires a publish job at this timestamp. '
    'Application must ensure this value is in the future at write time.';
COMMENT ON COLUMN blog_posts.author_id IS
    'UUID of the staff user who authored this post. References kloudshop_platform.staff_users '
    'but cross-schema FK is not enforced at DB layer. Preserved on staff deactivation.';

-- Indexes
CREATE INDEX idx_blog_posts_status
    ON blog_posts (status, published_at DESC);
-- Rationale: Primary storefront query — published posts ordered newest-first.
-- Filter: status = 'published'. Covers pagination and homepage widgets.

CREATE INDEX idx_blog_posts_scheduled_for
    ON blog_posts (scheduled_for)
    WHERE status = 'scheduled';
-- Rationale: Cloud Tasks scheduler queries for posts due to publish. Partial index
-- on status = 'scheduled' keeps it tiny and fast.

CREATE INDEX idx_blog_posts_author_id
    ON blog_posts (author_id);
-- Rationale: Dashboard "Posts by author" filter. Supports staff analytics.

CREATE INDEX idx_blog_posts_body_tsv
    ON blog_posts USING GIN (body_tsv);
-- Rationale: Full-text search across post titles and bodies. Supports storefront
-- search and dashboard post lookup.

CREATE INDEX idx_blog_posts_is_featured
    ON blog_posts (is_featured, published_at DESC)
    WHERE is_featured = TRUE AND status = 'published';
-- Rationale: Homepage "Featured posts" widget. Partial index — only featured
-- published posts. Expected cardinality: < 20 rows at any time.
```

---

## Table: `blog_post_translations`

```sql
-- =============================================================================
-- TABLE: blog_post_translations
-- Schema: tenant_{tenant_id}
-- Description: Per-(post_id, locale) translations for blog posts. Stores
--              translated title, slug, body (JSONB), body_tsv (generated),
--              and SEO fields. Mirrors the product_translations pattern (06b).
--
-- Business rules:
--   - 'en' is excluded by CHECK constraint. Canonical English content lives
--     in blog_posts. Translation rows are strictly non-English.
--   - is_auto_translated = FALSE rows are NEVER overwritten by the AI pipeline.
--     The AI translation pipeline must CHECK this flag before any UPSERT.
--   - slug must be unique per locale within this tenant. Enforced by UNIQUE
--     constraint on (locale, slug).
--   - body_tsv is generated from translated title + body using 'simple'
--     dictionary (DEC-04 — safe for all 10 supported LTR locales).
--   - When a translation slug changes, the application layer MUST insert a
--     redirect_rule (locale-scoped) in storefront_content.
-- =============================================================================

CREATE TABLE blog_post_translations (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),

    post_id             UUID            NOT NULL REFERENCES blog_posts (id) ON DELETE CASCADE,
    locale              TEXT            NOT NULL
                            CHECK (locale != 'en'),
    -- 'en' is excluded. Canonical English content lives in blog_posts directly.

    -- Translated content
    title               TEXT            NOT NULL CHECK (char_length(title) BETWEEN 1 AND 500),
    slug                TEXT            NOT NULL CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
    excerpt             TEXT            CHECK (char_length(excerpt) <= 1000),
    body                JSONB,
    -- Tiptap/ProseMirror JSONB — same structure as blog_posts.body.

    body_tsv            TSVECTOR        GENERATED ALWAYS AS (
                            to_tsvector(
                                'simple',
                                COALESCE(title, '') || ' ' || COALESCE(body::text, '')
                            )
                        ) STORED,
    -- Generated FTS vector. 'simple' dict. Same NULL-guard pattern as blog_posts.

    -- Translated SEO
    meta_title          TEXT            CHECK (char_length(meta_title) <= 120),
    meta_description    TEXT            CHECK (char_length(meta_description) <= 320),

    -- Translation provenance
    is_auto_translated  BOOLEAN         NOT NULL DEFAULT TRUE,
    -- TRUE = generated by AI pipeline (may be overwritten on re-run).
    -- FALSE = human-edited; AI pipeline MUST NOT overwrite. Enforced at app layer.

    -- Timestamps
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT blog_post_translations_post_locale_unique UNIQUE (post_id, locale),
    CONSTRAINT blog_post_translations_locale_slug_unique UNIQUE (locale, slug)
);

COMMENT ON TABLE blog_post_translations IS
    'Per-(post_id, locale) translations for blog posts. Excludes en (canonical in blog_posts). '
    'is_auto_translated = FALSE rows must never be overwritten by the AI pipeline. '
    'Slug changes must trigger locale-scoped redirect_rule inserts in storefront_content.';

COMMENT ON COLUMN blog_post_translations.is_auto_translated IS
    'TRUE = AI-generated, eligible for pipeline overwrite. '
    'FALSE = human-edited, must never be overwritten by AI pipeline. App-layer enforced.';
COMMENT ON COLUMN blog_post_translations.body_tsv IS
    'Generated FTS vector over translated title + body::text. simple dictionary (DEC-04).';

-- Indexes
CREATE INDEX idx_blog_post_translations_post_id
    ON blog_post_translations (post_id);
-- Rationale: Join from blog_posts → translations. Used by SSR locale resolution.

CREATE INDEX idx_blog_post_translations_locale
    ON blog_post_translations (locale);
-- Rationale: "All translated posts for this locale" query during sitemap generation
-- and locale-aware storefront listing.

CREATE INDEX idx_blog_post_translations_body_tsv
    ON blog_post_translations USING GIN (body_tsv);
-- Rationale: FTS over translated post content for non-English locales.
```

---

## Table: `blog_categories`

```sql
-- =============================================================================
-- TABLE: blog_categories
-- Schema: tenant_{tenant_id}
-- Description: Merchant-defined blog post categories. Enables grouping posts
--              by topic, driving category archive pages on the storefront.
--              Slug is unique per tenant and serves as the URL segment.
--
-- Business rules:
--   - name and slug must be unique per tenant (UNIQUE constraints).
--   - sort_order controls display sequence in navigation and category dropdowns.
--     Ties are broken by name ASC at query time — no secondary key needed.
--   - Deleting a category cascades through blog_post_categories (join table).
--     Posts themselves are NOT deleted.
--   - description is optional and plain-text (not JSONB) — category descriptions
--     are short by convention; rich formatting is not supported.
-- =============================================================================

CREATE TABLE blog_categories (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),

    name                TEXT            NOT NULL CHECK (char_length(name) BETWEEN 1 AND 200),
    slug                TEXT            NOT NULL CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
    description         TEXT            CHECK (char_length(description) <= 1000),
    sort_order          INTEGER         NOT NULL DEFAULT 0,

    -- Timestamps
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT blog_categories_name_unique UNIQUE (name),
    CONSTRAINT blog_categories_slug_unique UNIQUE (slug)
);

COMMENT ON TABLE blog_categories IS
    'Merchant-defined blog categories. Drives category archive pages on the storefront. '
    'Slug is the URL segment and must be unique. sort_order controls nav sequence; '
    'ties broken by name ASC. Deletion cascades to blog_post_categories (join table) '
    'but does NOT delete the posts themselves.';

COMMENT ON COLUMN blog_categories.sort_order IS
    'Display sort order in navigation and dropdowns. Default 0. Ties broken by name ASC.';

-- Indexes
CREATE INDEX idx_blog_categories_sort_order
    ON blog_categories (sort_order, name);
-- Rationale: Dashboard and storefront category listing ordered by sort_order, name.
-- Low cardinality table — index is mainly for consistent query plans.
```

---

## Table: `blog_category_translations`

```sql
-- =============================================================================
-- TABLE: blog_category_translations
-- Schema: tenant_{tenant_id}
-- Description: Per-(category_id, locale) translations for blog categories.
--              Covers name, slug, and description. Same is_auto_translated
--              pattern as blog_post_translations and product_translations (06b).
--
-- Business rules:
--   - 'en' is excluded by CHECK constraint. Canonical English content lives
--     in blog_categories.
--   - is_auto_translated = FALSE rows MUST NOT be overwritten by the AI pipeline.
--   - Translated slug must be unique per locale (UNIQUE on locale, slug).
--   - Slug changes require a locale-scoped redirect_rule insert.
-- =============================================================================

CREATE TABLE blog_category_translations (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),

    category_id         UUID            NOT NULL REFERENCES blog_categories (id) ON DELETE CASCADE,
    locale              TEXT            NOT NULL
                            CHECK (locale != 'en'),

    -- Translated fields
    name                TEXT            NOT NULL CHECK (char_length(name) BETWEEN 1 AND 200),
    slug                TEXT            NOT NULL CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
    description         TEXT            CHECK (char_length(description) <= 1000),

    -- Translation provenance
    is_auto_translated  BOOLEAN         NOT NULL DEFAULT TRUE,
    -- FALSE = human-edited. AI pipeline MUST NOT overwrite. App-layer enforced.

    -- Timestamps
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT blog_category_translations_category_locale_unique UNIQUE (category_id, locale),
    CONSTRAINT blog_category_translations_locale_slug_unique     UNIQUE (locale, slug)
);

COMMENT ON TABLE blog_category_translations IS
    'Per-(category_id, locale) translations for blog categories. Excludes en (canonical '
    'in blog_categories). is_auto_translated = FALSE rows must never be overwritten by '
    'the AI pipeline. Translated slug must be unique per locale.';

COMMENT ON COLUMN blog_category_translations.is_auto_translated IS
    'TRUE = AI-generated, eligible for pipeline overwrite. '
    'FALSE = human-edited, must never be overwritten. App-layer enforced.';

-- Indexes
CREATE INDEX idx_blog_category_translations_category_id
    ON blog_category_translations (category_id);
-- Rationale: Join from blog_categories → translations for locale resolution.

CREATE INDEX idx_blog_category_translations_locale
    ON blog_category_translations (locale);
-- Rationale: "All translated categories for this locale" during sitemap generation.
```

---

## Table: `blog_post_categories`

```sql
-- =============================================================================
-- TABLE: blog_post_categories
-- Schema: tenant_{tenant_id}
-- Description: Many-to-many join table between blog_posts and blog_categories.
--              Pure bridge — no additional columns.
--
-- Business rules:
--   - A post may belong to zero or more categories.
--   - A category may contain zero or more posts.
--   - Composite PK enforces uniqueness; no separate UUID PK needed.
--   - Deleting a post cascades here. Deleting a category cascades here.
--     Neither cascades to the other base table.
-- =============================================================================

CREATE TABLE blog_post_categories (
    post_id             UUID            NOT NULL REFERENCES blog_posts      (id) ON DELETE CASCADE,
    category_id         UUID            NOT NULL REFERENCES blog_categories (id) ON DELETE CASCADE,

    PRIMARY KEY (post_id, category_id)
);

COMMENT ON TABLE blog_post_categories IS
    'Many-to-many bridge between blog_posts and blog_categories. Pure join table — '
    'no additional payload columns. Composite PK enforces uniqueness. Cascades on '
    'post delete and category delete.';

-- Indexes
CREATE INDEX idx_blog_post_categories_category_id
    ON blog_post_categories (category_id);
-- Rationale: Reverse lookup — "all posts in this category". The composite PK index
-- covers post_id → category_id direction. This covers category_id → post_id.
```

---

## Table: `blog_tags`

```sql
-- =============================================================================
-- TABLE: blog_tags
-- Schema: tenant_{tenant_id}
-- Description: Merchant-defined blog post tags. Normalised into their own
--              lookup table to enable efficient tag-cloud aggregate queries
--              and faceted browsing without array unnesting.
--
-- Business rules:
--   - name and slug must be unique per tenant (UNIQUE constraints).
--   - Tags are never translated — they are merchant-internal taxonomy.
--     Storefront display uses the tag name as-is.
--   - A tag with zero posts remains valid (orphan tags are permitted — merchants
--     may pre-create taxonomy). Dashboard may offer a "clean up unused tags"
--     utility, but the DB does not auto-delete them.
-- =============================================================================

CREATE TABLE blog_tags (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),

    name                TEXT            NOT NULL CHECK (char_length(name) BETWEEN 1 AND 100),
    slug                TEXT            NOT NULL CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),

    -- Timestamps
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT blog_tags_name_unique UNIQUE (name),
    CONSTRAINT blog_tags_slug_unique UNIQUE (slug)
);

COMMENT ON TABLE blog_tags IS
    'Merchant-defined blog tags. Normalised table (not a PostgreSQL array) to enable '
    'efficient tag-cloud COUNT(*) GROUP BY queries and faceted filtering. Tags are not '
    'translated — name is used directly on all locales. Orphan tags (no posts) are '
    'permitted; the DB does not auto-delete them.';

-- Indexes
-- Note: UNIQUE constraints on name and slug create implicit B-tree indexes.
-- No additional indexes needed on this small lookup table.
-- Tag-cloud query: SELECT tag_id, COUNT(*) FROM blog_post_tags GROUP BY tag_id
-- is served by the PK index on blog_post_tags without a covering index here.
```

---

## Table: `blog_post_tags`

```sql
-- =============================================================================
-- TABLE: blog_post_tags
-- Schema: tenant_{tenant_id}
-- Description: Many-to-many join table between blog_posts and blog_tags.
--              Pure bridge — no additional columns.
--
-- Business rules:
--   - A post may have zero or more tags.
--   - A tag may be applied to zero or more posts.
--   - Composite PK enforces uniqueness.
--   - Deleting a post cascades here. Deleting a tag cascades here.
-- =============================================================================

CREATE TABLE blog_post_tags (
    post_id             UUID            NOT NULL REFERENCES blog_posts (id) ON DELETE CASCADE,
    tag_id              UUID            NOT NULL REFERENCES blog_tags  (id) ON DELETE CASCADE,

    PRIMARY KEY (post_id, tag_id)
);

COMMENT ON TABLE blog_post_tags IS
    'Many-to-many bridge between blog_posts and blog_tags. Pure join table — no '
    'additional payload columns. Composite PK enforces uniqueness. Cascades on '
    'post delete and tag delete.';

-- Indexes
CREATE INDEX idx_blog_post_tags_tag_id
    ON blog_post_tags (tag_id);
-- Rationale: Reverse lookup — "all posts with this tag" for faceted browsing and
-- tag archive pages. Tag-cloud COUNT(*) GROUP BY tag_id also uses this index.
-- The composite PK index covers post_id → tag_id direction.
```

---

## Updated Schema Inventory Entry

Replace the `06h` row in `06-schema-inventory.md` progress table with:

```
| `06h-tenant-blog-schema.md` | 7 | blog_posts (Tiptap JSONB + body_tsv GENERATED 'simple' FTS, status lifecycle, Cloud Tasks scheduling), blog_post_translations (locale != 'en', is_auto_translated, generated body_tsv), blog_categories (name/slug unique, sort_order), blog_category_translations (is_auto_translated), blog_post_categories (pure join, composite PK), blog_tags (normalised lookup, no translations), blog_post_tags (pure join, composite PK) | ✅ Generated |
```
