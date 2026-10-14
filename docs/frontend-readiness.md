# Frontend readiness before backend

Reviewed 2026-10-14 against the repository's OOC audit and current Flutter source. This is a source review, not an emulator/device usability study. Online features are pending; the existing test stories and replies are scripted.

## Improvements made in this pass

- Story editions and saved playthroughs now retain creator-authored world, player role, goal and adventure mode. A collapsible adventure guide appears before starting and inside the reader. Editing a draft does not change the guide in an older playthrough.
- Reader explains how to act, speak, use suggestions and try another path.
- Each committed message has a branch action. Confirmation describes the checkpoint and memory behavior. The original timeline remains available; branching is blocked while a reply streams.
- Summaries and pinned notes belong to each timeline. Branching at the latest message copies them independently. Branching earlier uses only selected messages for its recap and clears pinned notes, since notes have no historical timestamps yet. This prevents future facts leaking into a past checkpoint. Old shared-note saves retain notes only on the active timeline.
- Discover search matches premise, companion and genre as well as title.

## Initial gap inventory (implementation status updated below)

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

## Milestone target (now implemented locally)

Build a single fully authored original adventure using structured stats, triggered lore and two explicit endings. Exercise create → preview → save edition → start → checkpoint branch → resume → ending entirely with deterministic local state. Then connect the backend to the same contracts. Scaling the story catalog before this loop works would conceal the main product gaps.

Do not present a frontend button or fixture as implemented online sharing, dynamic AI story generation or verified OOC behavior. Public manga metadata does not supply reusable story text; keep temporary reference fixtures separate from authored stories.


## Implemented local systems — 2026-10-14

The frontend now includes an authored adventure engine and **The Lighthouse Promise**, separate from the removable five-story manga-reference catalog. It has two selectable starts, three bounded stats, three objectives, prioritized triggered world/companion lore, scene artwork transitions and two conditional endings. Complete adventures freeze input after ending; endless worlds continue. Endings are collected across preserved branches.

Creators can author stats, objectives, lore, endings, scenes, choices and starts in a form editor; editions carry a deep snapshot of these rules. Endings use AND conditions for selected objectives, lower/upper stat bounds and minimum completed actions. The editor starts from a clearly labeled lighthouse example; it does not invent original responses with AI. Every action has an authored reply, stat deltas, objective effects, next scene, optional stat gate and ending attempt. Free-text messages are recorded but do not invent state changes in authored previews.

Every committed message carries a state checkpoint. Branching restores that point's stats, objectives, scene and ending eligibility. A reply's effects are pending until the reply fully commits. Stop, simulated offline/timeout/interruption and app interruption preserve unchanged world state. Retry reuses the existing player input, replaces its partial reply and commits once. The transport interface is injectable; the preview failure controls are labeled local tests, not live network connectivity.

Player profiles (name, pronouns, prepared avatar), reading size, bookmarks, most-recent playthrough ordering, playthrough rename, archive/restore and draft archive/restore save locally. New runs pin their starting identity. Creator name, tags and age rating appear in story details. Export/import uses clipboard JSON version 1, validates size, settings and rule references, creates a new unpublished draft, and excludes player profiles/transcripts/private notes. It does not upload or create a real public link.

### Remaining limits

- P0 local stats, objectives, lore, endings and recovery UI are implemented; live model/HTTP behavior still needs backend integration.
- Android real-device lifecycle/storage and screen-reader testing remain manual work. Widget tests cover phone dimensions, enlarged text and deterministic interactions; rendered images are not a device usability study.
- Lore triggers currently use stat thresholds, not free-form keyword retrieval. Ending conditions support AND; compound OR groups are not implemented.
- Notes are untimestamped; historical forks clear them rather than pretending they are historical. Branch summaries remain user-editable.
- Multiple starts have separate openings, starting scenes and stat overrides; objective definitions are shared within an edition.
- Prepared scene assets are supported; uploads, audio/voice and live image generation are pending.
- Original story JSON can be copied/pasted; native file picker and real share sheets are not implemented.
- Real accounts, cloud synchronization, community pages, comments, likes, follows, reports, moderation, discovery ranking and online publication require backend services. No fictional community content is presented as real users.
