# Animeverse

An original Android interactive story project with a guided creator studio and
a path toward community-published adventures. The active implementation is currently
on the frontend/flutter-prototype branch; this is a pilot, not a launched service.

## What you can see in the current APK

- Illustrated discovery and story detail previews.
- Guided creation: premise, genre, tone, world, player role, goal, companion and opening.
- Playable scripted previews and editable original openings.
- My titles: recoverable local drafts and versioned story editions.
- Private / link-only / public visibility preview. Public editions appear in this
  device's local showcase. No content is uploaded or shared online.
- My stories: independent playthroughs, progressive reply text, Stop, notes and branches.
- Best-effort on-device saving through a replaceable storage adapter.
- The Lighthouse Promise: two starts, three stats/objectives, triggered lore, scene media and two endings.
- Creator rule forms, checkpoint world state, ending collection and retry-safe simulated failures.
- Local player profiles, reading settings, bookmarks, recent ordering, rename and archive/restore.
- Creator attribution/tags/rating and validated creator-only clipboard JSON export/import.

The authored adventure is separate from the three original prototype covers and five removable temporary test stories.
The manga reference adapter is optional and does not provide story text.

## What is already in the repository

| Area | Location | Current state |
|---|---|---|
| Flutter mobile app | mobile/ | Buildable scripted creator/player preview |
| Creator and local storage model | mobile/lib/creator/ | Drafts, isolated editions and device saves |
| Adventure harness | backend/ | Preferences, context, validated state and SQLite pilot |
| Product audit | docs/research/ooc-deep-product-audit.md | 47-feature review and revised priorities |
| Runtime acceptance plan | docs/research/ooc-runtime-test-plan.md | 45 tests still requiring execution |
| Project implementation tracker | docs/project-status.md | Implemented versus pending |

## Next production integration

Authenticated accounts and API; PostgreSQL work versions and private sessions;
Mem0 and versioned summaries; actual streamed model replies; publish/review permissions;
server-authoritative validation of the local adventure contracts. Then real-model and device benchmarks.

Local preview visibility is not server authorization. SharedPreferences is not a
critical-data database or a guarantee against abrupt process/device failure.
No cross-device sync, public creator platform or trained story model is claimed.
A live cloud server and real users still need performance/quality testing.

See mobile/README.md and backend/README.md for run commands. GitHub Actions builds
the debug APK and runs Flutter/backend tests. Release signing is not configured.
