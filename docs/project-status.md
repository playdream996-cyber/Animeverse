# Animeverse implementation tracker

Updated 2026-10-14. This describes the active frontend/flutter-prototype branch.
Main and earlier draft PRs are not a deployed combined product.

## Visible in the APK

| Feature | Implementation | Limit |
|---|---|---|
| Discovery/details | Original art, genre/search, readable detail sheet | Local catalogue |
| Guided creator | Three steps, editable premise/settings/opening | Template opening, no AI drafting |
| My titles | Drafts and story editions | Stored on this device |
| Visibility | Private, link-only and public preview | No real links or online publication |
| Local showcase | Latest public edition appears in discovery | Other users cannot access it |
| Preview/play | Each start creates its own StorySession | Scripted responses |
| Version isolation | Editing drafts doesn't mutate editions or existing sessions | Local model, not server permissions |
| Save/resume | Serial JSON snapshots and lifecycle flush | Best effort; no critical-data guarantees |
| Interrupted replies | Partial reply restores stopped | No backend job to reconnect |
| Memory/branches | Timeline-specific notes, summaries and per-message world checkpoints | Historical notes clear; no semantic Mem0 |
| Adventure engine | Stats, objectives, triggered lore, scene transitions, starts and endings | Deterministic local authored rules |
| Library/profile | Bookmarks, recent ordering, rename/archive/restore, identity, reading size | On-device only |
| Portability | Validated creator-only JSON, native file selection/save/share, clipboard fallback | Native device testing pending |
| Recovery | Injectable local transport, failure tests, effect-safe retry | Live HTTP recovery still pending |

## Implemented backend foundation

Ollama transport, prompt/context builder, structural validation, SQLite progress,
owner-scoped store, version checks, request idempotency and simple ending gates.
Tests use fake model responses. The frontend does not yet call this backend.

## Required for an online beta

1. Authentication and authorized API.
2. PostgreSQL definitions, immutable versions and private playthroughs.
3. Publication review, listing permissions, report/block workflow.
4. Real staged model streaming with cancellation and recovery.
5. Scoped Mem0, correction propagation and rolling summaries.
6. Stat/lore/ending prerequisites beyond model-proposed objective completion.
7. Device and server performance tests, sign/release process.

Creator following, financial rewards, advanced rankings and live image generation
remain later work. Temporary fixtures stay independently removable.

## Checks

Unit tests cover local serialization, save failures, visibility filtering,
private-session exclusion, version pinning and interrupted partial replies.
Widget tests cover the guided editor and discovery isolation.
CI renders real Flutter screenshots for visual inspection. They are preview artifacts,
not fixed visual regression baselines. APK build status is recorded in the PR.

## Frontend readiness review

See [frontend-readiness.md](frontend-readiness.md) for prioritized gaps and acceptance conditions. The latest frontend pass adds pinned adventure guides, message checkpoints, timeline-specific summaries/notes, safe migration of legacy shared notes, and broader Discover search. Structured stats/lore/endings are now implemented locally in the authored milestone below.


## Authored frontend milestone

The Lighthouse Promise is an independent original local adventure with two starts and two endings. Rules editor, stat/objective UI, triggered lore, prepared scene media, ending collection, checkpoint state, retry-safe reply effects, failure simulation, local player profiles/reading settings, bookmarks, recent ordering, rename/archive/restore, creator attribution/tags/rating, and creator-only clipboard JSON import/export are implemented. Temporary manga-reference fixtures remain under their existing feature flag. See frontend-readiness.md for tested scope and remaining backend/device requirements.

UI refinement, lazy transcript rendering, isolated large serialization and coalesced saves are documented in [ui-stability.md](ui-stability.md). Zero ANR/crash claims are not made without device profiling.
