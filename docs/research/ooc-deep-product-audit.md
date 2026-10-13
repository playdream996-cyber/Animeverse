# OOC product audit and revised Animeverse plan

Audit date: 14 October 2026, Asia/Karachi. Author: Codex.
Target: OOC: The Playable Anime, com.newai.ooc.
This document supersedes the earlier narrow feature shortlist, not the evidence in
the earlier static reports.

## Decision

Animeverse should be designed as a creator-and-player platform for reusable
interactive story definitions. Its core loop is discover → start a private
playthrough → make choices → continue later → reach an ending or branch.
A second loop is create → test → publish → other people play → creator receives feedback.

This is our product interpretation, not a claim about OOC's private architecture.
Building a better chat screen alone will not deliver the creator/publishing loop.
A catalogue does not require thousands of prewritten complete narratives.
It requires attractive starting definitions, rules and original assets that support
many independent playthroughs.

## Evidence and coverage

D = officially documented, not personally runtime-tested.
V = official store screenshot visually inspected.
A = selected reference reproduced from the supplied APK.
R = individual user review; not a prevalence measurement.
I = our proposed design or interpretation.
U = not verified.

Reviewed: Google Play listing/screenshots; Apple listing and release notes;
official Help Center; all eight story-editor stages; character setup/details/media;
prompt documentation; creator programme and credit policy.
A public third-party walkthrough index was consulted for orientation only.
Its locked screenshots were not accessed and its revenue estimates are excluded.
A competitor-authored review was not treated as independent evidence.

The supplied APK hash matches previous inspections:
3b9639e4114b0d88edeb3de043ad4a09a6f0ad4369c58bb7f3d52efdf905c977.
The bounded Hermes-v96 parser re-extracted 91,282 strings. A new focused scanner
verified 44 exact identifiers across nine product groups (see companion JSON).
No server routes were called. No proprietary assets or full recovered code are included.

Live website inspection reached a terms-acceptance gate. No agreement was accepted
and no account was created. There is no adb/emulator in this environment.
No live OOC playthrough, paid transaction, publication or resume test occurred.
Documentation and the APK may describe different releases or feature flags.
The older Hermes control-flow decoder failures remain unresolved.

## What OOC actually documents

### Discovery and the two entry experiences

Story and Character are separate product paths. The store listing limits free
unlimited chat to Basic in Character Mode; it does not promise free unlimited
story play. The public genre/gallery screenshot visibly shows the two tabs. [S01, V01]

The APK contains story/character recommendations, ranking and following interfaces.
Treat the ranking algorithm, placement logic and actual personalization efficacy as unknown.
Animeverse should start with clear genre/tag search, curated shelves, creator identity
and a Continue section. Advanced ranking needs usage evidence, not invented popularity.

### Creator editor: eight stages

| Stage | Officially documented capability | Animeverse implication |
|---|---|---|
| Profile | Cover, name, short introduction; image screening | Separate public discovery metadata from model context [S04] |
| Basic settings | Default/custom prompt templates, story details, AI-assisted drafting, examples | Guided creation first, advanced controls later [S05] |
| Intro | Multiple named starting scenarios, prologue, preview, player-facing guide and suggestions | A story can have several start sets [S06] |
| Stats | Numeric stats and conditional levels | Store values and rules outside generated prose [S07] |
| Media | Creator images with situation descriptions and per-intro scope | Select prepared assets with stable IDs [S08] |
| Keyword Book | Triggered lore notes with scope and priority | Retrieve relevant lore instead of injecting all world text [S09] |
| Endings | Conditional endings, epilogues, hints and collection cards | Build a real ending-definition system [S10] |
| Publish | Genre/audience/model metadata, rating, visibility and comments | Creation is not complete until preview and publication work [S11] |

Important distinction: a cover description is not necessarily an instruction to the
AI. OOC's prompt guide explicitly separates descriptive profile text from model-facing
character and feature prompts. Our editor must make that distinction clear. [S12]

An AI-written draft can assist creators; it does not establish automatic publication
or quality assurance. We should require a playable preview and explicit publication.

### Starting scenarios and onboarding inside stories

OOC documents multiple introductions per work, with a named prologue/opening context.
A player guide is described as user-visible rather than model memory.
Suggested replies may be creator-authored or generated if absent. [S06]

For Animeverse: show premise, role and goal before starting; retain free text actions.
Allow a creator to add multiple starts later. Do not confuse changing a start
(which starts a different playthrough) with restoring a checkpoint.

### Stats and consequences

The stat guide describes up to seven stats per starting setup, with names,
presentation, bounded values and defaults. Up to four conditional level ranges
can add context that changes character behavior; affinity and health are examples. [S07]

This documents a mechanism beyond prose-only relationship descriptions.
It does not prove that all generated stat changes are fair or deterministic.
Our harness should accept proposed changes only within allowed ranges and rules,
and preserve an event explaining each change. Player UI can show a small status
panel rather than technical validation messages.

### Lore and context

Keyword Book notes activate on matching words; the guide describes priority,
up to three simultaneous notes, and applicability to selected or all starts. [S09]
This is an authored lore layer, not necessarily a vector-memory implementation.

OOC describes system, character and feature prompt layers, plus history and
summaries. It acknowledges context-window and long-context limitations. [S12]
No exact private prompt, chosen inference provider or Mem0 implementation is disclosed.

Our context builder should combine trusted world rules, character cards, current
state, activated lore, relevant memories and recent turns under a measured token budget.
Creator content and player input are data; neither may grant database permissions.

### Memory, personalization and repair

Official FAQ: memory has long-term, temporary, relationship and goal categories.
It describes editable long-term entries, AI-managed other categories, and per-title
or global user notes. Avatars convey player identity. Message editing/deletion changes
conversation context. Output-length controls are documented. [S13]

Inference: these controls help users steer a generative system; they do not guarantee
perfect continuity. For Animeverse, separate authoritative facts from inferred memories.
Keep avatar preferences, story canon and private memories in different scopes.
A correction must invalidate/recompute affected summaries and state projections.

### Publishing and community

Public, Link Only and Private are explicitly documented. Public work can be played
and liked; Link Only is not indexed but is accessible by shared link; Private is for
the author. Publication includes tags, description, recommended model, content rating
and a comments switch. Most fields can be revised; the documented rating is fixed. [S11]

Characters have parallel visibility controls and can be linked to an author's story. [S14]
Creator following is described by the listing; comment/report/pin/search components
are present in the APK. [S01, A]

Our design recommendation: publish only allowlisted story-definition fields and approved
assets. Never publish a private transcript or personal memories by reusing a session object.
Snapshot the published version at playthrough creation. Later creator edits should not
silently change ongoing sessions. OOC's exact version-pinning behavior is unverified.

Link Only must still enforce authorization rules; an obscure ID is not private access.
For our beta, public stories should be manually reviewed before appearing in discovery.
Build block/report and a clear takedown/resume policy alongside publication.

### Endings are an authored reward loop

Creators can define endings per start, minimum turns, stat rules using operators and
AND/OR groups, an ending prompt, epilogue, image and hint. Documentation says checks
begin at turn ten and recur every five turns. The first eligible ending is delivered.
Rarity labels and collected ending cards support replay; issued rarity survives later
creator edits. The AI judges narrative fit. [S10]

These timing/rarity details are OOC's documented behavior, not mandatory settings for us.
Our deterministic evaluator should check eligibility and priority; the model writes
the resolution. Do not award an ending merely because the model says objectives are done.
Persist the award and its source version exactly once, with spoiler-aware hints.
Replay should create a branch from a chosen historical event and retain the original.

### Branches, shortcuts and a distinct AI-RPG experience

Apple release notes document branches from any message. They also describe saved
personal/creator slash commands, and the specific Dice of Fate AI-RPG with generated
turns, dice intervention and death/restart variations. [S02]
The APK includes matching branch, shortcut and AIRPG references. [A]

These do not establish a general 3D game engine or real-time anime video generation.
For Animeverse, reusable commands are a later convenience feature; validate their
scope as carefully as player actions. A separate dice/RPG mode should wait until the
basic adventure loop and state model are reliable.

### Reply presentation and images

APK references include LoadingMessage, StreamLoading, appendChunkToStreamingMessage,
handleStopStreaming and MessageStreamingSync. [A]
Their presence supports streaming/loading features, not verified timing or visual appearance.

Official documentation distinguishes selecting creator-supplied situation images
from optional on-demand image generation and a gallery. [S15]
This matters for budget: prepared artwork is a valid initial experience, not evidence
that every scene needs live image generation. Our next media work should map stable
character/location IDs to approved assets and prevent portrait mismatches.

### Creator incentives and economics

OOC's official credit policy describes a certified-creator reward of 2% of credits
spent on their titles, with its own expiry. The Creator Terms describe conditional
credit payouts and public-work eligibility. This is not proof of unrestricted cash
withdrawals, a guaranteed earnings rate or a revenue forecast. [S16, S17]

The eligibility guide lists publication/follower/interaction milestones and excludes
certain nonpublic or blocked content from counting. Those rules are a documented
programme, not requirements for ordinary story creation. [S18]

For Animeverse, creator profiles and usage feedback should precede financial rewards.
Do not promise payouts until unit economics, abuse controls and administration work.
A small CPU-server budget cannot establish public-launch capacity.

## Player feedback: useful hypotheses, not measured frequencies

Selected visible review excerpts were deduplicated by author: 12 Apple and 3 Google
Play reviews. This is a small nonrandom sample, including positive and negative
comments. Store ordering and duplicated expanded excerpts make percentages misleading.

| Observed review theme | Product hypothesis | What we should test |
|---|---|---|
| Strong enjoyment of agency/other creators' worlds | Premise plus meaningful action is the initial hook | Users voluntarily take several turns [S02, S19] |
| Credits interrupt immersion | Predictable session access matters | Comprehension of limits and interruption rate [S01, S19] |
| Corrections become tedious | Repair UX is as important as retrieval | A correction persists after reopening [S19] |
| Missing/mismatched images | Asset identity must match characters | Check portrait-to-character mapping [S19] |
| Login/editor failures | Reliability can erase creative investment | Recovery without losing drafts/progress [S01, S19] |

One review's description limit is not a universal platform limit: character description,
prompt, user note and memory fields are different. Model tiers, region and releases
also change costs. We have not verified current in-app per-turn charges.
Third-party revenue estimates disagree markedly and are excluded from our decisions.

## Honest gap analysis of our current code

Source snapshot: frontend PR #1 at 76ec5431c8fa2eb2e165b2142a7399db6f76505b;
backend PR #2 at 9fb2b4b365faa22d6347fac2cdfb48cba6217f2d.
Both were still open drafts at this audit. Main is not a deployed combined app.

| Capability | Current Animeverse | Required next step |
|---|---|---|
| Discovery | Local covers and five temporary fixtures | Database-backed published catalogue |
| Creation | Frontend title/companion; backend preference-based generation contract | Guided editor and persisted drafts |
| Start another author's story | Not implemented | Work-version to independent session creation |
| Publication and privacy | Not implemented | Draft/review/publish, ownership, 3 visibility modes |
| Follow/like/comment/report | Not implemented | Basic community and moderation model |
| Progress | Session-only mobile; durable local SQLite backend | Authenticated API and connected persistent saves |
| Memory | Manual frontend notes; backend NoMemory adapter | Scoped Mem0, versioned summaries and correction flow |
| Branches | Transcript copies; backend current-state forks | Historical checkpoints and branch-scoped state |
| Replies | Scripted frontend animation; buffered Ollama adapter | Real staged streaming, cancellation and recovery |
| Stats/conditional lore | Not implemented | Typed rules and context activation |
| Endings | Backend phase/all-objectives checks only | Defined conditions, priorities and earned awards |
| Media | Three original illustrations reused | Stable asset mapping and per-story prepared media |
| Economics | None; model/server unbenchmarked | Measure cost, latency and concurrency first |

Current backend tests prove selected storage/validation behavior with fake model data.
They do not prove writing quality. The validator currently lets the model propose
completion of an existing objective without proving its narrative prerequisites;
phase checks alone therefore do not establish a valid ending. It also limits facts
and items to the initial keys, and cannot support arbitrary later discoveries.
Characters have minimal cards, no numeric relationships, and no authored lore.
The recap is the latest scene, not a rolling summary. These are concrete pilot limits.

## Revised architecture recommendation (our design, not recovered OOC internals)

Separate reusable content from personal playthroughs:

| Record group | Owns |
|---|---|
| Works and immutable WorkVersions | Author, public metadata, visibility, rules and approved assets |
| StartingSets | Role, opening, initial state and available endings |
| CharacterCards and LoreEntries | Personality, knowledge constraints, activation/scope |
| StatDefinitions and EndingDefinitions | Ranges, transition rules, prerequisites and priorities |
| Sessions, Branches and Events | Owner, source version, canonical facts and committed actions |
| GenerationJobs | Request identity, reserved version, chunks, cancellation and final commit |
| Summaries and Memories | Event coverage, provenance, editable/correctable records |
| Profiles, Follows, Reactions, Comments, Reports | Discovery/community, separate from private play data |
| EndingAwards and AssetRegistry | Stable achievements and identity-safe media |

Publishing produces a reviewed immutable definition version. Starting it creates
new owner-scoped state. Each turn loads the pinned definition, prepares context,
generates proposed events, validates rules and commits atomically.
Rendered prose and a proposed stat delta are not independently authoritative.
Public creator analytics should aggregate activity, not reveal private dialogue.

The harness task split should be creation assistance, definition validation,
context/lore retrieval, turn generation, event validation, commit, summary update,
memory extraction, media selection and ending evaluation. Keep deterministic work
in code. Separate prompts do not require separate loaded models.
Expensive memory/summary work can be scheduled after confirmed turns; scope/version
checks must keep stale background results out of a newer branch.

Use PostgreSQL for production records and the replaceable Mem0 adapter for selected
memory tasks. Preserve the existing local pilot for tests, with explicit migrations.
Do not silently put temporary story fixtures into the real catalogue.

## Build order and release gates

P0 — a closed beta must support BOTH selecting an authored story and guided creation.
Include private saves/resume, real-model turns, stable media, basic creator drafts,
publication review, discoverability, independent playthroughs and safe correction.
Add minimal ending definitions early so stories can finish coherently.

P1 — expand with historical branches, named start variants, scoped lore,
stats/relationships, ending collections, follows and useful creator feedback.
Use a small curated seed catalogue plus invited creators; do not auto-publish
thousands of unreviewed generations.

P2 — personalization/ranking, public comments at scale, creator badges, command hub,
live image generation, financial creator incentives and a separate AI-RPG mode.
Order these using observed player/creator behavior, not competitor feature count.

First vertical slice: Author creates → previews → publishes → another account
discovers → starts → takes turns → closes app → resumes → reaches a valid ending.
If that fails, cosmetic polish or a larger model cannot compensate.

Measure: creation completion, first playable scene latency, turn latency/error rate,
voluntary session length, return usage, successful correction, valid endings,
cost per active session and public-content report handling. These are proposed
evaluation metrics, not established market benchmarks.

## Runtime validation still required

The companion test plan covers OOC observations and Animeverse acceptance tests.
First validate publication/session isolation, restart persistence, turn retries,
corrections, branches and ending prerequisites. Use two test accounts for isolation.
A consented OOC runtime walkthrough can establish current UI behavior; it cannot
reveal private models or server source. We should not stop progress on our own
architecture while awaiting that evidence.

Unknown: actual OOC model providers, prompts, database/vector store, exact context
packing, account-level concurrency, current costs/refunds for failed/stopped turns,
draft autosave semantics, version pinning, deletion propagation, true cross-device
recovery, fine-tuning datasets and production inference economics.

## Sources

All sources retrieved 14 October 2026 Asia/Karachi; no entire articles reproduced.
[S01] https://play.google.com/store/apps/details?id=com.newai.ooc&hl=en
[S02] https://apps.apple.com/us/app/ooc-the-playable-anime/id6761247061
[S03] https://help.ooc.ai/guide/user/tutorial/story
[S04] https://help.ooc.ai/guide/user/tutorial/story/1
[S05] https://help.ooc.ai/guide/user/tutorial/story/2
[S06] https://help.ooc.ai/guide/user/tutorial/story/3
[S07] https://help.ooc.ai/guide/user/tutorial/story/4
[S08] https://help.ooc.ai/guide/user/tutorial/story/5
[S09] https://help.ooc.ai/guide/user/tutorial/story/6
[S10] https://help.ooc.ai/guide/user/tutorial/story/7
[S11] https://help.ooc.ai/guide/user/tutorial/story/8
[S12] https://help.ooc.ai/guide/prompt
[S13] https://help.ooc.ai/
[S14] https://help.ooc.ai/guide/user/tutorial/character/5
[S15] https://help.ooc.ai/guide/user/image/what-is-scene-image
[S16] https://help.ooc.ai/credit-usage-policy
[S17] https://help.ooc.ai/creator-terms
[S18] https://help.ooc.ai/guide/creator/info/how-to-become
[S19] https://apps.apple.com/us/app/ooc-the-playable-anime/id6761247061?platform=iphone&see-all=reviews
[S20] https://help.ooc.ai/guide/user/tutorial/character/1
[S21] https://help.ooc.ai/guide/user/tutorial/character/4
[S22] https://help.ooc.ai/guide/creator/info/what-is-creator
[S23] https://help.ooc.ai/guide/creator/info/disqualification
[V01] Official Google Play promotional screenshots, first four inspected; these
show marketing presentation, not hands-on app behavior.
[A] Supplied APK and docs/research/ooc-product-apk-evidence.json.
Prior native trace: docs/ooc-deeper-trace.md.
