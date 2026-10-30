# Native crash and one-run comparison —2026-10-30

Status: PARTIAL_RUNTIME / NATIVE_CRASH; cause unproved. User approved one comparison with only SoulsEnemyHUD temporarily disabled. No tuner source fix is claimed. Main/releases unchanged.

## Preserved candidate and evidence

Executed source `b392c3c952d8bbb10ae197886b3e1b8c71422168`; installed5Lua match previous manifest/Git payload, main SHA256 `6568c84e4a65197172b41b1550c72d6b6aeb7ade97326b35d2c45d1650b19ed6`. Steam1.09/build12996889, UE4.27.2, UE4SS83330635/DLL SHA256 `ce5e3c46a920cc00b2817ac61e438c9162830290379d0b5b9c4dfc2b29459290`. Active at crash: CombatHUD, SoulsEnemyHUD, own tuner.

Before changes, private `.local/live-light-tuner/native-crash-20261030T172446Z` preserved exact own payload/diagnostic, raw UE4SS/Genesis logs, CrashContext XML and766105-byte UE4Minidump.dmp plus hash manifest. Raw reports/dumps include private machine data and are not published.

| Evidence | SHA256 |
| --- | --- |
| UE4SS.log |749ae56d6ab8a9a0f632b61218296fe69e518b0198960ade8c796a3abb23d515 |
| current Genesis.log |980fcdf8d48c8b9568aa5bbf0f4cc074d1ccb4bdceb2f519b08bff44025bafbd |
| CrashContext.runtime-xml |0fc98396958a81d7ebc9e57ea9c446d2f2cd462a2181ce2a246f02380b7c850c |
| UE4Minidump.dmp |40ae1119de80692663235cc696ce47752f3fae68a67d391571a52462a5bdcf47 |

## What the run establishes

READY20:00:03.864 МСК; marker projection20:00:03.864: viewport2560×1440, DPI1.333333373, raw1362.181/934.112px→widget1021.500/700.500, native bool/out and scaling check passed. All3 own native light registration/apply guards reached READY, continued parameter/selection/ON actions were logged. User reports that tuning worked for a long time; this is not a detailed aesthetic acceptance of channels, marker alignment or shadows.

Last successful action20:23:43.106 was Front shadow ON, following OFF20:23:42.423. Both native calls returned with readback; crash17:23:48.528UTC/20:23:48.528МСК, approximately5.42s later and23m44.66s after READY. CrashContext SecondsSinceStart1471 covers process lifetime. Temporal proximity does not identify the shadow setter/renderer as the cause. No HSL FAILED/CLEANED/SAVED event; own fault log hash remains the old09:31UTC diagnostic. Native access violation bypassed ordinary Lua exception containment. Manual STOP/SAVE/release are not verified by this run.

The1590 successful CONTROL entries were used to reconstruct last numeric values/ON toggles plus SHADOW flags from known diagnostic defaults. A schema2-validated `recovered-unsaved-unitless-v2.ini` and derivation note are private in this archive. There was no v2 profile loaded/saved in this session. Recovery is derived evidence, not an accepted preset or automatic save; it was NOT installed/loaded into the next run.

## Crash localization and limits

Unhandled EXCEPTION_ACCESS_VIOLATION reading0x70, exception PC=UE4SS+0x2afdf6. Minidump records thread30252; XML maps the primary crashed thread to **GameThread**. Later Genesis log says Runnable thread AIF_Director_BP_2 crashed and HandleError re-entered; that secondary error is not proof of a worker-thread origin. The earlier chat interpretation was corrected after cross-checking XML/dump.

Installed PE export table plus x64 runtime-function boundaries establish two exact stack functions, without guessing from distant exports:

- UE4SS+0xb9f485 lies in function0xb9f410…0xb9f575, exported LuaMadeSimple::Lua::call_function.
- UE4SS+0x4a44ee lies in function0x4a4420…0x4a456c, exported UnrealScriptFunctionData::FirePreCallbacks.
- Fault0x2afdf6 belongs to a separate private function0x2afde0…0x2afe0a, NOT the distant nearest exported UObject::HasAnyInternalFlags. Instruction reads [RAX+0x70] with captured RAX0. That establishes a null access, not which Lua object/mod/property caused it.

No matching local PDB was found. The official [exact commit build](https://github.com/UE4SS-RE/RE-UE4SS/actions/runs/39048955758) has no retained artifacts at inspection; rolling experimental release now has another commit. New/different PDBs are not substituted. No new system debugger, loader version or package dependency was installed. Exact private lambda, Lua traceback/mod-state owner and root cause remain unknown; a minidump with flags0 does not supply a full Lua heap.

The stack passed through a Blueprint pre-hook. Own tuner source registers no hooks: it uses one EngineTick action. Of the active Lua sources, SoulsEnemyHUD registers two Blueprint Tick hooks (MeterOnHead2 and HudUmg); CombatHUD registers a native GenesisPlayerController OnActionInputPressed hook. This makes a comparison without SoulsEnemyHUD a bounded useful discriminator, not proof of its fault or proof that HildaSoftLight cannot trigger an interaction. The old Lua-return failure and this native crash are not assumed to share a cause. Pcall/guard relaxation or removing shadows merely because of the last key would not establish a fix.

## Authorized comparison prepared

User explicitly approved temporary deactivation of only SoulsEnemyHUD for one comparison, preserving its files and exact prior activity for return. No Lua source changed: installed candidate remains b392c3c with identical5Lua, parameters start at the same diagnostic defaults unless a user-saved profile exists. The recovered unsaved profile stays outside the game.

With game closed, only its `mods.txt` activity row changed1→0; CombatHUD1 and own enabled marker remain. No SoulsEnemyHUD enabled marker exists. Original43other mod files and19current loader/config/save inputs hash-verified unchanged. Previous `mods.txt` bytes and expected comparison bytes are archived; exact return hashes verified. Private comparison manifest `.local/live-light-tuner/comparison-without-souls-20261030T173500Z/manifest.json`, `restore_activity.py` restores only this file after checking closed game/current expected hash. Own current-install records comparisonManifest. No game launch/termination by the agent.

Next user action: start normally, Ctrl+Alt+F10, ordinary tuning including markers and Front shadow OFF/ON as before. Num9 remains explicit save; Multiply STOP, then close game and report outcome. The assistant snapshots the new log FIRST, restores exact prior SoulsEnemyHUD activity with the private helper, verifies it and compares evidence. Before any ordinary install/rollback, restore this activity exception first: the generic tuner helper intentionally expects the original mods.txt and will reject the comparison state. No background watcher/automatic game control.

A new crash can narrow the hypothesis by stack comparison. One crash-free comparison is encouraging, not proof of causality or long-term stability; it does not license permanent changes to the other mod. Do not change other mod sources/global UE4SS, gameplay/graphics settings or publish a stable release under this one-run approval.
