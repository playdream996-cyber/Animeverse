# OOC APK static inspection

Date: 2026-10-13. Input: user-supplied OOC.apk. Package com.newai.ooc, version 0.1.23 (535).
SHA-256: 3b9639e4114b0d88edeb3de043ad4a09a6f0ad4369c58bb7f3d52efdf905c977

## Method and limits

Inspected ZIP inventory, decoded Android manifest with Androguard, read the bundled dependency inventory, and parsed the Hermes v96 string table with a purpose-built bounded reader. No app execution, backend calls, authentication bypass, payment bypass, or network probing was performed. No original assets, APK, credentials, or complete recovered code are committed here.

The APK has 1,262 entries, six DEX files, and a 17,380,216-byte Hermes bundle with 91,282 string entries. Four strings contain decoding replacement characters; selected evidence strings are clean. No native libraries under lib/ were included, so this may be a base APK requiring additional ABI splits. It must not be assumed to be an independently installable complete application.

## Confirmed static findings

| Finding | Evidence | Confidence and limit |
|---|---|---|
| React Native client with Hermes bytecode | index.android.bundle magic/version; react-android 0.83.5 and hermes-android 0.14.1 in dependency inventory | High for bundled technology; dependency versions reflect the supplied artifact |
| Android API requirements | Manifest minSdk 24, targetSdk 36 | High |
| Network-oriented client | INTERNET permission and numerous generation/API route strings | High for client references; backend implementation unknown |
| Summary management | chatV3ControllerCreateSummary, ReadSummaries, UpdateSummary, UpdateLastSummary, DeleteSummary, GetSummariesVersion | High for client references; execution and summarization quality not tested |
| Branching and snapshots | chatV3ControllerBranchChat, ApplySnapshot, useCreateBranch, /snapshot/apply | High for client references; exact semantics unknown |
| Model configuration and recovery | ChatModelSelectBottomSheet, ApplyReplacementModel, useChatModelErrorsPolling, /ooc-gen/v3/chat-models/errors/config | High for client references; active providers unknown |
| Output-length configuration | chatModel.maxOutput is required | High for string presence; limits and billing behavior unknown |
| Streaming UI | useStreamingState and streaming configuration identifiers | Suggests incremental generation; transport not verified |
| Situation images | /ooc-gen/situation-images/generate, regenerateSituationImage | Suggests image generation/regeneration workflow; provider/cost unknown |
| Ending collections | EndingCollectionScreen and EndingDetailScreen | High for named client components; availability not tested |
| Payments, attribution, notifications and updates | BillingClient, AppsFlyer, Firebase messaging, Sentry inventory and HotUpdater manifest components | Presence only; does not prove data collection practices or active use |
| Basic transport/backup flags | usesCleartextTraffic=false, allowBackup=false | High; not a security audit or proof of encryption at rest |

No recognized .gguf, .onnx, .tflite, .safetensors, .pte or .task files were present. This argues against a conventional bundled local LLM in this artifact, but does not exclude downloads, splits, unconventional packing or remote configuration.

Gemini and GPT names appear in the string table alongside generic SDK/instrumentation material. They do NOT establish which model powers OOC story generation. Likewise, no specific Mem0 backend can be confirmed from the APK. Internal/admin-looking route strings are not evidence that those routes are accessible or vulnerable; they were not called.

## What changes for Animeverse

1. Add user-editable summaries, not just opaque automatic memory. Keep summary versions and the event range each summary covers.
2. Treat chat branches as separate branch IDs, with an immutable parent and fork event. Do not mutate the parent timeline when replaying a branch.
3. Implement snapshots of canonical state at checkpoints. Restore through the same validated transaction pathway, with a new state version.
4. Separate transcript, episode summary, world facts, relationships and extracted personal memories. Mem0 is one layer, not all five.
5. Give model requests explicit output budgets and streaming status. Implement timeout, cancellation and recoverable error states.
6. Introduce an internal model adapter so a replacement model can be selected without changing canonical state.
7. Leave generated scene images and public creator economics outside the USD 20 CPU pilot. Prepared original art can support the first mobile version.

## Harness task contracts

| Task | Reads | Writes |
|---|---|---|
| Retrieve context | Auth-scoped memory, canonical state, branch summary, recent turns | Nothing |
| Interpret action | Player input and world rules | Proposed intent only |
| Plan story | Intent and versioned state | Proposed events only |
| Validate/commit | Proposed events, permissions and expected state version | Atomic event log and canonical state |
| Render dialogue | Committed or explicitly staged events, personality and retrieved context | Transcript through backend |
| Update summary | Committed branch event range | Versioned branch summary |
| Extract memory | Committed transcript and events | Scoped Mem0 records through deduplicated worker |

The ordering must be chosen deliberately: if dialogue generation happens after commit, persist a recoverable turn status so a generation failure can be retried without applying the action again. Alternatively stage the response and commit everything atomically after validation. No model may directly write arbitrary canonical fields. Use cross-worker database locks/version checks, idempotency, durable jobs and an outbox. Separate task prompts alone do not prevent conflicts.

## Validation completed

The scanner executed successfully on this APK. Assertions checked package identity, six DEX files, string-table count and selected summary evidence. Three malformed/truncated inputs were rejected. String ranges and overflow indices are bounds-checked. This validates the extraction path for this artifact, not UI behavior or AI quality.

Reproduce with Python and optional Androguard:

```bash
python -m pip install androguard
python tools/inspect_apk.py /path/to/OOC.apk > evidence.json
```

The reader supports Hermes bytecode version 96 only. Future artifacts may require a different parser. See ooc-apk-evidence.json for selected references with string IDs, package metadata and dependency evidence.

## Remaining work

No Android emulator or adb was available. Installation, login, conversation persistence, summary editing, branches, snapshot recovery and live generation were not tested. A complete APK/split set and Android device/emulator would enable those tests. No claim is made that a USD 20 server matches OOC quality or supports its user scale.
