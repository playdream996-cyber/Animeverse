# UI fixes and stability work

Scope: current Flutter frontend branch, before live backend integration.

## UI changes

- Creator preview validity updates as fields change; preview also rechecks readiness before constructing a session.
- Adventure status is reactive, including restart and alternate path actions performed from its sheet.
- Rule edits are protected by Apply/Discard/Keep editing navigation. Deletions have confirmation and undo, with related stat/objective references cleaned up.
- Rule editor shows one section at a time and builds its cards lazily. Validation selects the relevant section, highlights the entry, exposes condition fields and scrolls to the affected control. Invalid numbers remain invalid rather than silently reverting to an old number.
- Reader has compact stats/objectives with a direct status action. Suggested choices remain close to the latest reply; locked choices show their prerequisites.
- Reading positions persist per timeline; existing playthroughs without an offset open near the latest content. Branch names are editable, with origin message and progress previews.
- Save status is visible in the library, creator and reader, including failed save retry. Help, library search/sorting, ending progress and a zoomable artwork viewer are available.
- Native JSON file selection/save and platform sharing complement clipboard import/export. File reads are bounded to 600 KB, timed out while reading, and validated before import. Cancellation and native/plugin failures leave the UI usable.

## Performance and crash-risk changes

- Sliver-based transcript rendering creates widgets for the visible region instead of the whole history. History pages are bounded to 40 messages with Earlier/Later/Jump to latest controls, limiting variable-height jump layout work without deleting messages. Page and pixel position persist per timeline. Streaming uses a separate text notifier and does not trigger project saves on every character update.
- Native large JSON encode/decode uses a background isolate. Small saves avoid isolate overhead. Only one save is active; edits and repeated flushes coalesce to the newest snapshot. No growing queue of serialized copies.
- Reading-position writes debounce; timers/listeners are canceled on reader/editor disposal. Leaving the reader stops an active reply and retains its partial state for retry.
- Prepared image decoding is bounded; full-screen artwork has a separate bounded resolution. Rule editor field controllers are released with the screen.
- Reply transport exceptions and oversized responses produce a recoverable error, without awarding state changes. Corrupted committed/pending checkpoints are rejected before reader use. Failed project loads preserve the stored payload.
- Historical recaps use a bounded window of recent messages, avoiding huge summary fields when branching long histories.
- CI builds debug and release-mode, per-ABI test APKs. Release test APKs use the generated project's test signing configuration, not a production signing key.

## What these checks prove

Regression and stress tests verify deterministic local flows, bounded reader widget count for a 2,000-message history, large-history save/reload, coalesced slow writes, safe native-service failures via injected fakes, invalid file handling, reactive status, editor navigation and live validation. Screenshots are generated for phone dimensions and enlarged text.

They do not prove zero Android ANRs or crashes. Native file/share dialogs, background/foreground transitions, abrupt process kill, low-storage behavior, low-memory devices, TalkBack, keyboard layouts and CPU/frame timing still require Android device/profile-mode tests. Native file pickers may perform their own provider-side caching; Dart bounds protect reading into the application, not every third-party provider operation. Local preferences remain prototype storage, and large libraries should move to a transactional local database for production.

## Manual Android acceptance checklist

1. Profile on a low-end 2–3 GB RAM phone and an ARM64 phone; measure frame build/raster times and memory during 2,000+ messages and repeated branching.
2. Send, Stop, retry and navigate back during loading/writing. Reopen after backgrounding and process kill; verify no duplicate input, partial reply or stat award.
3. Cancel file picking, deny provider access, import oversized/invalid files, remove a selected file, and close share sheets. Verify no stuck spinner or crash.
4. Change text size and system font scale; rotate, show/hide keyboard, scroll and reopen a playthrough. Verify usable controls and reading-position restoration.
5. Simulate disk write failure and slow writes; verify Save failed/retry and preservation of existing data.
6. Confirm release signing, app identifier/update behavior, and native dependency compatibility before store release.
