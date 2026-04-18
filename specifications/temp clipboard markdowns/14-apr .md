You are continuing KloudShop Stage 6 — Data Model generation. The persona is Principal Data Engineer.

**Canonical inventory:** `BKP-06-schema-inventory.md` is the authoritative generation tracker.

**Completed so far:** `06a1` through `06n` (all ✅ Generated).

**Next artifact:** `06o-index-strategy.md`

**Scope per `BKP-06-schema-inventory.md`:** Documentation + DDL artifact. Consolidates all `CREATE INDEX` statements across both schemas (`kloudshop_platform` and `tenant_{tenant_id}`), with prose rationale per index. Each table section must include: the dominant query patterns served, the full `CREATE INDEX` statement, and a one-line rationale. Non-obvious composite and partial indexes get extended rationale.

**Key source:** Every index already appears inline in `06a1` through `06m`. The task for `06o` is to consolidate and audit — do not invent new indexes. Do identify any indexes that are missing from the DDL artifacts by cross-referencing the access patterns documented in `06n` (state machine transitions imply specific lookup patterns) and the business rules in `03-user-journeys.md` and `04-feature-stories.md`.

**Locked conventions:**

* All timestamps `TIMESTAMPTZ`
* `'simple'` FTS dictionary (DEC-04)
* UUID PKs via `gen_random_uuid()`
* No DB FK constraints across schema boundaries
* Status columns use `VARCHAR` + CHECK, never PostgreSQL ENUMs
* `CREATE INDEX CONCURRENTLY` where blocking indexes are noted (non-destructive migration policy)

**After generating `06o`:**

1. Present the artifact file
2. Provide the surgical patch for `BKP-06-schema-inventory.md`
3. Provide the handoff prompt for `06p`

Look for ways and means and techniques to sort of compress the task without losing output quality and the thinking and analysis depth to stay within the chat limits. Or at least you can think of breaking it into multiple parts so that completeness and quality of the task are ensured and all the tokens are used optimally so as not to hit the message limits set by Claude. Ask for clarification questions if you need to..... before writing the output 

