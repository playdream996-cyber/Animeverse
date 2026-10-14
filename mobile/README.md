# Animeverse mobile creator/player preview

Flutter app with original anime artwork, a guided creator studio, local story editions,
a reader with progressive scripted replies, and best-effort device saves.

Run with current Flutter stable. Generate platform wrappers as shown in
.github/workflows/mobile.yml, then:

    flutter pub get
    flutter analyze
    flutter test --update-goldens
    flutter run

Production entrypoint loads SharedPreferencesAsync storage before showing the app.
Tests inject a MemoryProjectStorage, avoiding hidden device/network dependencies.
Drafts, local editions, transcripts, notes and branches serialize separately.
Writes are ordered, debounced during editing/replies and flushed on backgrounding.
Corrupt saved data enters read-only recovery rather than overwriting the saved payload.
Local storage is a prototype, not a critical-data database, cloud backup or sync system.

Creation: define title/premise → world/role/goal → edit opening and play preview.
Save a private or link-only edition, or add a public edition to this device's showcase.
No publishing action uploads data. Link sharing, online review and real community
visibility require the authenticated backend.

Each edition snapshots the creator draft. Every new playthrough uses a separate
StorySession with its pinned definition, so later draft edits do not alter its opening.
Partial replies restore as stopped rather than continuing an abandoned timer.

Replies and generated opening suggestions are scripted/templates. The Ollama backend
is present in backend/ but not connected. Original cover art is reused; no live
image generation, accounts, payments or release signing is configured.

The five fixtures remain in lib/demo. ANIMEVERSE_DEMO_CATALOG=false disables them.
Jikan supplies optional metadata references only; it never supplies playable prose.

CI produces debug APK and four Flutter screen renders. See docs/project-status.md
for the implementation status and docs/research/ for the full OOC audit and test plan.


### Complete authored adventure

Search for **The Lighthouse Promise**, choose a start and follow its authored choices. Search/listen → study → relight reaches the beacon ending; choosing a safe signal reaches the second ending. Check Adventure status for stats, objectives, lore and ending hints. Completed runs can restart or branch before the final action. Preview connection tests intentionally fail the next reply; Retry commits no duplicate input/effects. Player settings and library controls save on this device. Creator studio → Add playable adventure rules edits a lighthouse example; original story export/import uses copied JSON without private player data.
