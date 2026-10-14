# Reusable adventure pipeline

This independent Python backend foundation does not import or change the Flutter
demo catalogue. User preferences become structured creation instructions;
the harness assembles authoritative state, recent turns and scoped optional memories
for every subsequent request. The model proposes JSON; code validates and atomically
commits state and transcript. It cannot directly access the database.

## Run locally

Python 3.11+; no Python dependencies. A separately installed Ollama server and a
downloaded model are required for real generation. Default candidate: qwen3:4b.
No real-model quality or server-speed benchmark has been performed.

From backend:

    python -m unittest discover -s tests -v
    python -m animeverse --owner local-test create preferences.example.json
    python -m animeverse --owner local-test resume BRANCH_ID
    python -m animeverse --owner local-test turn BRANCH_ID "Use the key" --request turn-1 --version 0
    python -m animeverse --owner local-test fork BRANCH_ID

Use --close with a turn to request a closing arc. Returned versions must accompany
the next turn. Keep a request ID when retrying an identical action; changed actions
require a new ID. A committed duplicate returns the same result without generation.

## Task ownership and replacement boundaries

- Prompt templates: creative direction and structured output contract.
- Context builder: canon, recent history, recap and optional relevant memories.
- Model adapter: Ollama JSON generation only; replaceable with another provider.
- Validator: allowed facts/items/objectives, phase progression and ending eligibility.
- Store: owner-scoped transactions, optimistic versions, idempotency and persistence.
- Memory adapter: search(owner, branch, action); currently NoMemory. Mem0 integration
  is pending. Recalled memories are untrusted and cannot overwrite canonical state.

SQLite is a durable LOCAL PILOT implementation, not the planned production
PostgreSQL service. Owner is trusted CLI input, not authentication. No public HTTP
endpoint, mobile integration, live streaming, Mem0 deployment or production hosting
is implemented. Build an authenticated API and PostgreSQL adapter before mobile use.
Never expose this CLI identity mechanism as authentication.

Validated generation is buffered before committing. This avoids saving partially
validated model output; real streaming needs a staged-turn lifecycle, cancellation
and explicit commit events. No simulated backend streaming is presented as real.

The complete transcript stays in storage; context uses six recent turns and trims
optional history/memory to a 12,000-character budget without trimming canon.
Characters are not tokens: exact tokenizer budgeting and rolling summaries remain
future work. Recap currently displays the latest narrative, not an AI summary.
Characters/initial facts are bounded; known items start as the initial inventory.
The pilot deliberately refuses arbitrary new fact/item keys.

Complete stories must move setup → conflict → climax → resolution, with all
objectives complete before resolution. Endless worlds require explicit closure.
Only current-state forks exist; older checkpoints/sequels are not yet implemented.
Code checks structure and rules, not whether a model's narrative is emotionally
satisfying or semantically consistent with every proposed change. Human-reviewed
model evaluations remain necessary.

Generation failures leave state unchanged. Concurrent turns use compare-and-swap
at commit: one wins and one reloads; they can still consume two model calls.
Production needs durable task queues and reservations to avoid wasted inference.
Creation is not yet request-idempotent. No automatic model retry loop is hidden.

## Verification

Tests use an explicitly fake model and mocked Ollama HTTP responses. They verify
restart recovery, scoped access, branch isolation, duplicate requests, conflicting
turns, invalid changes, item spending, endings, context bounds and failed generation.
They do not measure actual LLM creativity, latency, or continuity.

Ollama adapter contract: https://docs.ollama.com/api/chat
