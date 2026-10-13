# Animeverse

Original Android interactive anime storytelling project.

## Current status

This repository begins with a public-source analysis of OOC: The Playable Anime and a proposed task harness. There is no application implementation yet. No APK, emulator session, private backend, or live inference benchmark has been inspected or tested.

## Agreed direction

- Flutter Android client: interface, prepared anime art, animation and audio playback.
- Self-hosted FastAPI backend: model requests, authenticated access and workflows.
- Initial model candidate: Qwen3 4B Q4_K_M through Ollama, non-thinking dialogue.
- Self-hosted Mem0: memory extraction and retrieval, local embeddings, persistent Qdrant.
- PostgreSQL: authoritative characters, relationships, story state and event history.
- Cloud spending target: USD 20/month for a small pilot. This is not a verified production capacity or latency guarantee.
- A VPS is logically isolated but may share physical hardware; it is not confidential computing.
- No paid inference API is required in this proposed setup. Server, electricity, backup and transfer costs still exist.
- Model permissiveness is a separate requirement; the proposed Qwen model is not established as uncensored.

## Research and design

See [OOC assessment and harness](docs/ooc-assessment-and-harness.md).

## Next evidence needed

1. Authorized hands-on OOC access or an APK for client inspection.
2. Trace onboarding, character creation, story actions, session persistence and branching.
3. Select an available server with a complete checkout price.
4. Benchmark the actual model: first-token latency, generation speed, memory use and concurrent requests.
5. Implement and test the original story loop and task isolation before expanding features.

Do not copy OOC proprietary assets or code. Public behavior does not establish its private prompts, model or architecture.
