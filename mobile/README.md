# Animeverse mobile frontend

Flutter Material 3 prototype with an original midnight/lavender visual theme.

## Included

- Searchable story library and genre filters.
- Companion selection and session-only story history.
- Scripted interactive chat with suggested choices and custom actions.
- Manual summary editing and pinned memory notes.
- Branch creation and switching with independent transcripts.
- Custom story titles (all titles currently use the same demo opening).
- Explicit demo labels and empty/validation states.

No AI, login, network, persistent saves, billing, or production backend is connected. Notes are global within one session, not branch-scoped; authoritative branch state and versioned summaries belong in the backend integration. All data resets when the process closes. No OOC assets or recovered code are used. The geometric/icon cover art is a placeholder for original anime illustrations.

## Run

Install current Flutter stable and Android tooling. Generate stock platform wrappers without overwriting the application source:

```bash
flutter create --project-name animeverse --platforms=android,web /tmp/animeverse-platform
cp -r /tmp/animeverse-platform/android /tmp/animeverse-platform/web .
cp /tmp/animeverse-platform/.metadata .
flutter pub get
flutter analyze
flutter test
flutter run
```

On Windows, create the temporary project in a folder of your choice and copy its android, web and .metadata items into mobile. Then run the remaining Flutter commands from mobile.

GitHub Actions runs analysis/tests and builds a debug APK artifact. A successful workflow is required before considering the code build-verified. Release signing and Play Store publishing are not configured.

## Backend integration boundary

Replace StorySession.send with an authenticated story service that streams validated responses. The current send method is explicitly scripted and must not be presented as AI. Keep per-session request IDs, cancellation and error/retry status. Server owns memory, summaries, branch IDs and authoritative game state. Do not place Ollama or privileged backend credentials in the mobile client.
