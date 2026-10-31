# HildaSoftLight0.1.0 — production candidate, NOT stable

Branch `codex/production-0.1.0`, base88d640f. First candidate version0.1.0 is immutable once handed. VERSION is canonical; tools/build.py checks Lua metadata, package instruction version and exact approved preset bytes, then verifies every package input against the recorded source commit. Archive is deterministic ZIP_STORED with fixed metadata. Frozen source/archive/CI identity will be recorded after checks; no stable tag/release/main promotion yet.

## Prepared behavior

Auto3-light binding in ready Hilda gameplay, periodic current context/HP validity fence, release then rebind with unique generations. Approved profile is unchanged. No own UI before F10; UI destroyed on close; native setters apply live values without another light set. Num* pauses, F10 resumes + opens editor. Optional UI/markers isolated. Unexpected core error cleans before one cancellation and leaves late callbacks inert. No LoopAsync/ExecuteInGameThread/input callbacks.

Source/capability basis: [PRODUCTION_READINESS](PRODUCTION_READINESS.md), R-004/R-017/R-018, accepted69-minute tuner session and exact working profile. Full lifecycle/appearance/native safety remains unproved for this source. Existing UE4SS native crash is not claimed fixed. HP>0 is the chosen bounded readiness/death fence, not evidence of every game's death/cutscene transition.

## Installable payload

Canonical folder HildaSoftLight/:5Lua Scripts (main/Profile/EditorView/Projection/KeyboardBindings), DefaultProfile.ini, VERSION, enabled.txt, README.txt, LICENSE and LICENSING.md. No loader, other-mod files, pak, game asset or generated dump. No mutable settings file in ZIP. Existing own user profile must be preserved/copied on first tuner→production migration, never overwritten on update.

Installation is currently **NOT PERFORMED**: SoulsEnemyHUD0.3.3 is separately installed and unaccepted. CombatHUD0.4.1 is accepted. Do not mix two unaccepted changes or revert that other candidate in this task. Once the other acceptance is resolved, verify closed game, snapshot exact own tuner+profile/log/shared hashes, archive old own folder out of Mods, enable new own payload last, compare hashes, verify exact own rollback. Never run both old tuner and production. User launches/closes game.

## Offline/native gate separation

Local tests cover initial readiness, approved/default/user settings, no UI/key-audit at normal start, repeated loads/HP0/pawn replacement, unique names and one handle, UI/marker faults, partial3-component cleanup, incomplete cleanup circuit break, cancel failure/late inert callbacks, key edges across editor/resume, pause/resume and shadow comparison. Syntax and schema roundtrip/preset hash checked. UI/native calls are mocked there; these are not native auto/load/death/renderer PASS. CI must pass exact source and package identity before handoff.

## Short native acceptance after separate installation

1. Load gameplay normally: light appears without editor; no panel/markers visible.
2. Ctrl+Alt+F10 open/close: same light set, close keeps light. Use7/8/2/4/6, Front shadows3 and markersDivide briefly; no artistic recalibration needed.
3. For persistence, change Front intensity one0.05 step, Num9, load/restart and confirm the value. Restore accepted0.15 and save if the change was only a test.
4. Load a save/world: light automatically returns without old-world residue/doubles; inspect BOUND/RELEASED generations after run.
5. Death/respawn: observe release/recovery, no duplicates. This gate is OPEN until actually exercised; do not manufacture a mocked PASS.
6. Use Glimmer normally, then Num* pause and F10 resume: each effect keeps its intended independent behavior. Close editor for ordinary play.
7. Coexistence only with accepted CombatHUD/SoulsEnemyHUD versions, review UE4SS errors after game close. Native crash: snapshot raw reports and identities first, do not blame the last action.

On completion report observations; the agent reads logs directly. No stable release until this candidate's mandatory gates are explicitly accepted. No game launch/termination or hot reload by agent.
