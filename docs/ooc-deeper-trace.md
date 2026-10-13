# Deeper OOC client reverse engineering

Date: 2026-10-13. Same supplied APK and SHA-256 as ooc-apk-analysis.md.

## Native DEX instruction tracing

Decoded instructions in MainActivity, MainApplication and MainApplication$a using Androguard.

- MainActivity's delegate construction instantiates com.facebook.react.defaults.b, obtaining a component-name string and a runtime flag before calling its constructor. onCreate installs a fragment-related factory and calls the React activity superclass.
- MainActivity's method a() calls Android moveTaskToBack(true).
- MainApplication creates and stores a MainApplication$a React host object.
- MainApplication$a extends com.facebook.react.defaults.f. Its bundle-path method g() references com.hotupdater.C and delegates resolution through an obfuscated wrapper with the application Context.
- Consequently, a HotUpdater-related bundle resolution path is present in startup. The installed runtime bundle might differ from the bundled asset after updates; actual update delivery is not verified.
- MainApplication's onCreate also invokes an obfuscated helper. Its behavior is not established. Do not label it a particular security mechanism without tracing it.

These conclusions derive from instructions, not solely a dependency-name search.

## Located Hermes function headers

A separate Hermes parser located named function records in the compiled bundle:

| Function ID | Function name | Byte offset | Bytecode bytes |
|---|---|---:|---:|
| 38003 | chatV3ControllerBranchChat | 10929883 | 114 |
| 38036 | chatV3ControllerGetMessages | 10932009 | 99 |
| 38050 | chatV3ControllerUpdateMessage | 10932980 | 111 |
| 38091 | chatV3ControllerCreateSummary | 10936519 | 114 |
| 38103 | chatV3ControllerUpdateSummary | 10937900 | 111 |
| 38152 | chatV3ControllerApplySnapshot | 10942311 | 92 |
| 58222 | useCreateBranch | 13600623 | 123 |

Header locations identify candidate functions, not a successful reconstruction of their execution.

## Decode attempts and explicit blocker

Installed hermes-dec 0.1.7. Normal disassembly fails the bundle's SHA-1 footer integrity assertion. For diagnostic parsing only, a second scratch-only attempt disabled Python assertions; full and selected-function decoding then failed on unsupported opcodes including 0xea, 0xe3, 0xfd and 0xf9.

No app was patched or run, and no decoded control flow is trusted from these failed attempts. Possible causes include a modified/protected bytecode format, tool mismatch or altered artifact; this inspection does not establish which. The presence of appsecurity assets alone is not proof of a particular protection scheme.

## Additional selected schema/UI references

- parent_chat_id, chat_id and chat_settings.
- ChatV3MaxOutputSettingRequestDtoMaxOutputMultiplier.
- ChatV3SummaryResponseCreatedBy.
- ChatSummariesDeleteScreen, updateChatSummary and useUpdateMaxOutputForChat.
- Relative route fragments /pause, /resume, /reroll and /summaries/read.

Together with the named function records, these strengthen evidence of a client-side branch/summary/settings interface. They do not reveal request payload types in full, HTTP methods, model prompts, server permissions or the memory algorithm.

## Implications

Animeverse should track parent branch IDs, summary authorship, output budgets and recoverable generation states explicitly. Keep a single validated canonical-state commit pathway.

Deeper JavaScript control-flow recovery remains blocked on a compatible decoder/runtime artifact. Runtime tests also require Android tooling and potentially the ABI split APKs. Backend code is not recoverable from this client package alone.

This report is substantive native instruction analysis plus function localization, not complete source recovery.
