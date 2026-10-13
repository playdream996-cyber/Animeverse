# OOC runtime observations and Animeverse acceptance tests

Date: 2026-10-14. All runtime observations below are PENDING.
No line in this plan is a claim that OOC passes or fails a test.
Use accounts and assets the tester owns; do not publish copied characters/content.
Record OS, app version, date, content type, mode and visible cost before testing.
Never include credentials or real private conversations in test evidence.

| ID | Scenario | Record in OOC | Animeverse acceptance criterion |
|---|---|---|---|
| T01 | First launch | Consent, age, name/preferences, tutorial steps | User reaches a playable opening without unexplained fields |
| T02 | Browse Story and Character | Entry points and included free access | Modes clearly distinguish their purpose and allowance |
| T03 | Search and genre filters | Search targets, ranking/sort labels | Search resolves real catalogue metadata, not fake popularity |
| T04 | Story detail | Description, creator, start options and costs | Premise, role, content rating and action are clear |
| T05 | Two starts in one story | Which state resets on changing start | A new start creates an independent session |
| T06 | Player avatar | Default versus session-specific identity | Identity does not silently leak across unrelated worlds |
| T07 | Guided creation | Required fields, AI drafting, errors | A novice can create and preview a coherent opening |
| T08 | Draft interrupted by app close | Autosave/recovery and server/local behavior | Restart restores saved draft, with explicit unsaved-state handling |
| T09 | Creator preview | What preview sends or persists | Preview cannot accidentally publish |
| T10 | Private title with second account | Actual access boundary | No other user can retrieve definition or private playthrough |
| T11 | Link-only title | Indexing and link permissions | Not indexed; linked access obeys intended policy |
| T12 | Public title | Discoverability and publication delay | Only reviewed published definition becomes discoverable |
| T13 | Two players start same title | Shared or independent session data | Actions, memories and branches never cross owners |
| T14 | Edit work after others start | Version propagation | Existing session pins its source version |
| T15 | Public metadata exposure | Whether raw prompts/media can be viewed | Private creator fields never appear through unrelated endpoints |
| T16 | Follow creator | Feed and notification changes | Follow/unfollow produces accurate feed state |
| T17 | Like/comment/report/block | Available controls and feedback | Rate limits and moderation work; block scopes are explicit |
| T18 | Reply loading and streamed text | First chunk, chunk sizes, stop placement | User sees actual status; provisional output distinguished from committed |
| T19 | Stop before first chunk | Charges, state, ability to retry | Cancellation does not silently apply action or spend twice |
| T20 | Stop midway | Partial output, continuation semantics | Recoverable partial turn; explicit commit policy |
| T21 | Network loss during generation | Reconnect behavior and duplicate messages | Retry reuses request ID and cannot double-apply state |
| T22 | Close app mid-turn | Resume/result recovery | Server job and version determine one canonical outcome |
| T23 | Send two turns quickly | Queue, credit lock, double-generation behavior | Ordering is defined and conflicting commits cannot occur |
| T24 | Reopen next day/on second device | Session history and position | Authenticated user resumes exact branch/state |
| T25 | Contradict a known fact | Retrieval and correction controls | Canon is changed only through explicit validated correction |
| T26 | Edit or delete an old event | Recomputed memories/stats/history | Dependent summaries/state projections are invalidated |
| T27 | Long-term vs temporary memory | UI scope, edit limits | Memory records carry provenance and event coverage |
| T28 | Promise after 30 turns/reopen | Character recall and unknown facts | Relevant confirmed promise recalled; invented promise flagged |
| T29 | Keyword lore activation | Keywords, priority and start scope | Correct scoped lore activates; irrelevant lore is excluded |
| T30 | Stat thresholds | Bounds, level changes, visible consequences | Code enforces bounded values and rule-based transitions |
| T31 | Use nonexistent/consumed item | Response and underlying state | Invalid spending rejected; prose/state reconciliation explicit |
| T32 | Model changes during session | Personality and state continuity | Switching provider never discards authoritative state |
| T33 | Branch at an old message | Included history, summary, stats and images | Snapshot corresponds to selected event; parent unchanged |
| T34 | Correct facts on child branch | Whether parent remembers correction | Corrections and extracted memories remain branch-scoped |
| T35 | Ending below minimum turns | Hint/award behavior | No award before deterministic prerequisites |
| T36 | Stat ending with AND/OR rules | Priority and context judgment | Rule evaluation is deterministic and tested |
| T37 | Two endings eligible simultaneously | Tie handling | Defined priority yields one idempotent award |
| T38 | Ending card/replay | Rarity, spoiler hints, prior awards | Earned version/award preserved across creator edits |
| T39 | Prepared scene image | Character/location/situation match | Stable IDs select correct media; missing art has fallback |
| T40 | On-demand generated image | Cost, failure, gallery/retry | Separate job/budget; failure cannot corrupt narrative state |
| T41 | Personal and creator commands | Prompt injection, scope, costs | Commands cannot bypass state/visibility permissions |
| T42 | Title blocked/deleted while playing | Access and recovery policy | User gets explicit status; policy determines allowed recovery |
| T43 | Credit or allowance exhausted | Warning and saved state | Limit understandable before action; progress retained |
| T44 | Failed/stopped model output billed | Refund or consumption behavior | Charge policy is explicit, auditable and idempotent |
| T45 | Account deletion/export | What disappears or remains public | Retention/public-work policy enforced and disclosed |

Prioritize T07–T14 and T18–T38 for the first integrated vertical slice.
A fake-model test can verify transaction behavior, not character quality.
Run a fixed real-model evaluation set: five original premises, at least three
runs each, plus a longer continuity run. This is a proposed evaluation design.
Record malformed-output rate, contradictions, repeated prose, latency and resource
usage. Use human review for player agency and ending satisfaction.

Publication release gate: private/session data must not appear in public responses.
Resume gate: close/restart retries must not duplicate committed actions.
Narrative gate: meaningful choices and character consistency are reviewed on actual
outputs. Model size alone is not a substitute for these checks.
