# Frontend readiness before backend

Reviewed 2026-10-14 against the repository's OOC audit and current Flutter source. This is a source review, not an emulator/device usability study. Online features are pending; the existing test stories and replies are scripted.

## Improvements made in this pass

- Story editions and saved playthroughs now retain creator-authored world, player role, goal and adventure mode. A collapsible adventure guide appears before starting and inside the reader. Editing a draft does not change the guide in an older playthrough.
- Reader explains how to act, speak, use suggestions and try another path.
- Each committed message has a branch action. Confirmation describes the checkpoint and memory behavior. The original timeline remains available; branching is blocked while a reply streams.
- Summaries and pinned notes belong to each timeline. Branching at the latest message copies them independently. Branching earlier uses only selected messages for its recap and clears pinned notes, since notes have no historical timestamps yet. This prevents future facts leaking into a past checkpoint. Old shared-note saves retain notes only on the active timeline.
- Discover search matches premise, companion and genre as well as title.

## Still missing and worth building before connecting AI

| Priority | Gap | Frontend acceptance condition | Later backend requirement |
| --- | --- | --- | --- |
| P0 | Structured endings | Creator defines ending name, prerequisites, epilogue and hints; player can inspect a sample ending and restart/fork. Complete and endless modes have distinct behavior. | Server validates prerequisites and freezes completed runs; model cannot award an ending alone. |
| P0 | Stats and objectives | Editable bounded stat definitions and goal checklist; player sees values and why they changed; deterministic test fixtures exercise success/failure. | Authoritative, validated state deltas and transactional saves. |
| P0 | Lore and context | Creator separates permanent world rules, triggered lore, character knowledge and player-private notes; preview shows which lore is active. | Retrieval, scope and priority limits; branch-specific context snapshots. |
| P0 | Response recovery | UI demonstrates offline, timeout, interrupted reply, retry and duplicate-send states through an injected fake transport. | Request IDs, cancellation, idempotency and partial-stream reconciliation. |
| P1 | Starting scenarios | One story can offer multiple starts with their own opening, objectives and guidance. | Pin selected start and edition in each run. |
| P1 | Personal identity | Local player name/pronouns/avatar and editable companion identity; previews use these consistently. | Account ownership and profile synchronization. |
| P1 | Library management | Bookmarks, recent-play ordering, rename/archive and restore; empty states give useful next actions. | Server pagination, favorites and cloud history. |
| P1 | Portable original stories | Export/import validates a versioned creator-only format; excludes private transcripts and notes. | Upload validation, ownership and content limits. |
| P1 | Publication readiness | Show an edition preview, tags, age rating and sharing status; private/link/public permissions are explicit. | Actual URLs, authorization, moderation, reporting, discovery ranking and creator attribution. |
| P1 | Accessibility and QA | Persist reading settings; screen-reader labels, large text, contrast, keyboard navigation and phone-size tests; manually check real Android lifecycle/storage. | No backend dependency. |
| P2 | Community presentation | Story/creator pages and review/report flows can be tested with labeled fixtures. | Real users, likes, follows, comments, abuse controls and notifications. |
| P2 | Prepared contextual media | Creator assigns media to scenes and player can inspect deterministic scene transitions. | Authorized asset storage and selection rules. |

## Recommended next milestone

Build a single fully authored original adventure using structured stats, triggered lore and two explicit endings. Exercise create → preview → save edition → start → checkpoint branch → resume → ending entirely with deterministic local state. Then connect the backend to the same contracts. Scaling the story catalog before this loop works would conceal the main product gaps.

Do not present a frontend button or fixture as implemented online sharing, dynamic AI story generation or verified OOC behavior. Public manga metadata does not supply reusable story text; keep temporary reference fixtures separate from authored stories.
