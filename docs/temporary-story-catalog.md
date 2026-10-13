# Removable APK test catalogue

Five original anime-style test adventures are stored in mobile/lib/demo/story_seeds.dart.
They are freshly written from broad public-domain literary foundations (Alice, Oz,
Monte Cristo, Scarlet Letter, Twenty Thousand Leagues), not copied manga plots,
characters, panels, translations or synopses. Existing three prototype stories remain.

The public Jikan v4 manga search API supplies OPTIONAL bibliographic reference
metadata only. Refresh manga references performs five paced GET searches, with
timeouts and offline fallback. Search results are references, not verified source
editions or proof of adaptation rights. No synopsis or remote artwork is imported.
Live API access failed in the development environment; mocks test success/failure.
The five playable fixtures do not depend on network access.

Sources: https://docs.api.jikan.moe/ and Project Gutenberg ebook IDs
11, 55, 1184, 33, 164. Gutenberg marks these originals public domain in the USA.
This is a private test catalogue; commercial release requires territory/edition review.

Replacement boundary: StoryCatalog interface and StoryDefinition are independent
of the demo adapter. Implement the interface with an authenticated database API,
then remove mobile/lib/demo and its reference refresh UI. Disable the fixtures now
with --dart-define=ANIMEVERSE_DEMO_CATALOG=false. No fixture data enters a production
database. Existing app sessions and previous cover models remain separate.

Reply presentation is simulated streaming of scripted text, not live AI.
Loading appears before incremental Unicode text, followed by a blinking cursor;
Stop cancels the timer and retains only received text. Sending and branching are
blocked while a reply is in progress. Scrolling follows only when already near
the bottom. Existing memories, summaries and transcripts remain session-only.

Tests cover progressive loading, stop/cancellation, duplicate sends, branch guards,
legacy branches/notes, five distinct openings, metadata separation and API fallback.
