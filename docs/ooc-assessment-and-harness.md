# OOC assessment and proposed Animeverse harness

Research date: 2026-10-13. Method: public listing and user reports.
Status: preliminary product analysis, not a completed binary or runtime reverse engineering.

## Sources

- S1: https://play.google.com/store/apps/details?id=com.newai.ooc&hl=en
- S2: https://play.google.com/store/apps/details?gl=GB&hl=en-GB&id=com.newai.ooc
- S3: https://huggingface.co/Qwen/Qwen3-4B
- S4: https://ollama.com/library/qwen3:4b
- S5: https://docs.mem0.ai/open-source/overview
- S6: https://docs.mem0.ai/components/embedders/models/huggingface
- S7: https://docs.hetzner.com/general/infrastructure-and-availability/price-adjustment/
- S8: https://www.hetzner.com/cloud/

Listings and reviews vary by region and time. Store claims are not independent functional verification. Competitor marketing articles were not used to establish private implementation.

## Observed public evidence

| Evidence | Classification | Implication |
|---|---|---|
| Typed actions drive unique story progression | Publisher claim, S1 | Build an action-to-event workflow |
| Character and world creation | Publisher claim, S1 | Use structured authoring forms |
| Companions adapt and remember history | Publisher claim, S1 | Evaluate long-session continuity |
| Private stories and community publishing | Publisher claim, S1 | Separate access control from generation |
| Follow creators and explore genres | Publisher claim, S1 | Later discovery and creator features |
| Unlimited free chat restricted to Basic model in Character Mode | Publisher claim, S1 | Do not describe every mode as unlimited |
| September reviews complain about credits and quality selection | Individual user reports, S1 | Transparent quotas and error handling |
| A visible regional review reports forgotten timelines/events | Individual user report, S2 | Test continuity; does not establish a universal failure rate |

Unknown: model provider, prompts, orchestration, memory algorithm, database schema, inference hardware, actual concurrency, and whether assets are generated during gameplay.

## Original implementation mapping

| Workflow | Inputs | Outputs | Write authority |
|---|---|---|---|
| Action interpretation | Player text, world rules, current state | Structured proposed intent | None |
| Memory retrieval | Authenticated user ID, character ID, world ID, query | Scoped relevant memories | None |
| Dialogue | Personality, validated state, memories, recent turns | Character reply | Conversation log through backend |
| Story planning | Intent and current state | Proposed events | None |
| Validation | Proposed events, permissions, world rules, state version | Approved/rejected changes | None |
| Commit | Validated changes and expected version | Atomic new state and event log | Authoritative database |
| Memory extraction | Committed conversation/events | Candidate durable memories | Memory store only |

These are task-specific workflows using one inference service, not independently loaded models.
Permissions and deterministic invariants must be implemented in code, not merely described in prompts.

## Conflict prevention

- Derive user identity from authentication; never trust a client-supplied identity for scoping.
- Attach user, session, character, world and request IDs to every job.
- Serialize turns per session; use database versions/transactions to handle shared-world changes across sessions.
- Use idempotency keys scoped to user/session and store completed results.
- Treat model output, player text and retrieved memories as untrusted inputs.
- Validate structured outputs, field types, allowed operations and bounds.
- Keep durable jobs with retries, status and deduplication. Process-local locks alone are insufficient with multiple workers.
- Only one state commit pathway may modify canonical state.
- Memory extraction cannot overwrite canonical inventory, relationships or events.
- Prefer an outbox recorded in the same transaction as the turn, then asynchronously update Mem0.
- Prioritize dialogue over background extraction when sharing a CPU model.
- Do not promise conflict-free operation until concurrency and recovery tests pass.

## Proposed pilot deployment

Flutter -> HTTPS authenticated FastAPI -> harness -> Ollama.
FastAPI owns PostgreSQL and calls Mem0 with scoped identifiers.
Mem0 uses persistent Qdrant and local embeddings.
Keep Ollama and database ports private. Persist data outside ephemeral directories.

Qwen3 4B Q4_K_M is a candidate: Ollama lists approximately 2.5 GB model weights and Apache 2.0 licensing (S4). Total working memory exceeds the file size.
Start experiments with 4096 context tokens, non-thinking mode, short streamed replies, one active generation and queued background work.
This is a proposed configuration, not a benchmark or evidence of uncensored behavior.

Hetzner's current notice lists European CX33 at USD 9.99/month excluding IPv4 and VAT (S7). Its public page marked shared offerings unavailable during research (S8).
Do not present that as an immediately purchasable verified solution.
A final server choice requires availability, actual specifications, taxes, backup costs and a performance measurement.

Self-hosted Mem0 supports configurable LLM, embedder and vector store (S5).
Its defaults include external OpenAI services; explicitly replace them.
Local Hugging Face embeddings are supported in Python (S6).
Verify model endpoint compatibility and reliable structured extraction before choosing the dialogue model for memory processing.

## Hands-on inspection matrix: all pending

| Test | Evidence to capture | Status |
|---|---|---|
| First launch and onboarding | Screen sequence, required fields, time to story | Not run |
| Character creation | Fields, limits, editing and persistence | Not run |
| Action input | Input/output trace across multiple choices | Not run |
| Multi-character dialogue | Speaker identity and personality consistency | Not run |
| Session restart | Recall of explicit facts after restart | Not run |
| Contradictory facts | Handling of corrections and canonical changes | Not run |
| Long conversation | Event and relationship recall at increasing length | Not run |
| Branching/replay | Whether branches change original state | Not run |
| Error/retry | Duplicate actions and interrupted generation behavior | Not run |
| Private/published story | Visibility and access boundaries | Not run |

## Implementation tests to add

- Two simultaneous turns cannot commit from the same stale session version.
- Repeated request IDs return the same result without another event or charge.
- One user's memories never appear in another user's search.
- A proposed impossible inventory or relationship change is rejected.
- A crash after state commit does not lose the queued memory update.
- A memory retry does not duplicate a durable fact.
- Provider timeouts do not partially commit story changes.
- Restarts retain canonical state and memories.
- Model load plus embeddings and databases stay within measured server RAM.
- Report first-token latency and tokens/second under one and two users.

No tests in this document have been executed. No application code exists yet.
