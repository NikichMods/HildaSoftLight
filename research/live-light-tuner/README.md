# Live light tuner — research only

**PREPARED / UNTESTED as a combined tuner.** R-018 proved one own light and manual cleanup; R-017 proved this exact independent viewport-host/text recipe. This candidate composes them with two lights, live setters, native temperature, front shadows, saved settings and a small panel. New combinations still need the user's real session. No release/version/production architecture is adopted.

## Start and controls

Launch the game normally, load Hilda into gameplay, stand on solid ground near some shaded geometry, enable **NumLock**. Every command below is **Ctrl+Alt + the NUMERIC KEYPAD key**, not the top number row.

| NumPad | Action |
| --- | --- |
| **0** | First press: prepare two lights + open panel. Later: hide/show panel |
| **7** | Select Front / Back |
| **8 / 2** | Previous / next parameter (the `>` row) |
| **4 / 6** | Decrease / increase selected parameter |
| **5** | Fine / LARGE step |
| **1** | Selected light ON/OFF; compare Front only, Back only, both or neither |
| **3** | Front shadow OFF/ON using native SetCastShadows; independent of selected light |
| **9** | Explicitly write own `tuner-settings.ini` |
| **\*** | Permanently STOP: cancel own action, destroy both lights, remove own UI |

While the panel is hidden, parameter/control keys do nothing in this tuner. Only0 can reopen and* can stop. No mouse focus/input-mode changes, key consumption, original bindings edits or UI replacement occur. When native input context is not Scene, commands stop editing and the panel hides; reopening requires Scene again. The underlying RegisterKeyBind callbacks remain inert after STOP until process exit; the exact owned frame action is cancelled. No invented key-unregister API, hot reload or automatic recreation.

Key names were verified in UE4SS83330635 LuaMod.cpp523ff: `NUM_ZERO`…`NUM_NINE`, `MULTIPLY`. InputCore's actual FKey names `NumPadZero`…`NumPadNine`, `Multiply` are separate. Before binding, check every exact Ctrl+Alt chord via IsKeyBindRegistered. Before allocating any light/UI, query all50 retained keyboard virtual IDs through the R-014 runtime-proven scalar GetKeyByVirtualKey in batches of10 explicit EngineTick actions. A current mapping to a reserved keypad key fails closed. Empty local Input.ini is not treated as proof of current Genesis bindings. This audit covers the known declared keyboard rows, not every possible engine/debug/OS shortcut. Do not rebind game keys during a tuner run.

## Temporary values and bounds

| Parameter | Front start | Back start | Bounds | fine / LARGE |
| --- | --- | --- | --- | --- |
| ON | yes | no | independent flags | Num1 |
| Intensity | **4 lm** | **2 lm** | 0…30 lm | 0.1 /1 lm |
| Attenuation radius |200 cm |150 cm |50…400 cm |10 /50 cm |
| Root-local X |+60 cm |−60 cm |−150…150 cm |2 /10 cm |
| Root-local Y |0 cm |0 cm |−150…150 cm |2 /10 cm |
| Root-local Z |+30 cm |+30 cm |−100…150 cm |2 /10 cm |
| Temperature |5000 K |5000 K |2500…8000 K |100 /500 K |
| CastShadows |OFF |OFF | Front only | Num3 |

These are diagnostic starting points, substantially below60lm: inverse-square gives approximately15×/30× less input energy than the first probe. Perceived brightness still depends on distance/exposure/materials; no artistic acceptance follows. X is the pawn root's forward/back axis, Y side and Z up; moving X close to the body can put the source inside the mesh. No socket is guessed.

Both components are own RF_Transient Engine.PointLightComponent objects with guarded Hilda pawn Outer/native owner, root KeepRelative attachment and native FinishAddComponent. All illumination is configured DARK before registration; final live settings are applied only after both components and UI have been prepared. Movable, inverse-square, explicit Lumens, zero volumetric/indirect, no particles/material/postprocess changes. Lighting channels are the union of a read-only live model and one native downward floor hit as in the accepted probe. Position uses reflected K2_SetRelativeLocation(no sweep, own empty output table,teleport), radius/intensity/temperature use native setters; no continual recreation or per-frame transform writes.

White base color plus SetUseTemperature(true)/SetTemperature(K) uses UE4.27's native temperature multiplier. The exact native methods are present in the saved UHT and source-reviewed; this candidate's temperature/UI arrangement is not yet runtime-accepted.

## Front shadows and limits

Front has CastDynamicShadows=true and CastStaticShadows=false set only on the own unregistered component; Back's CastDynamicShadows=false and CastShadows=false. Front's master flag changes through reflected native SetCastShadows, which marks render state dirty. Before enabling, read `r.ShadowQuality`, `r.SupportPointLightWholeSceneShadows`, `r.AllowPointLightCubemapShadows`; zero/unsupported lookup blocks the request and leaves user settings untouched. No CVar is written.

Read/log Hilda mesh CastShadow/bCastDynamicShadow, sampled floor flags, light Mobility/CastDynamicShadows, visibility/intensity and channel intersections. A noncasting Hilda mesh is reported, never patched; scene casters may still work. Readback of CastShadows is a setter/flag test, **not proof of effective shadow-map rendering**. Actual shadow appearance depends on desktop/RHI/project support, visibility/culling, affected casters/materials and native renderer. Accepted machine baseline is DX11; no renderer replacement, custom shadow material or shader is introduced. First Num3 test must be judged in-game and its log reviewed.

## Nondestructive frame comparison

The panel shows one-second averages of **real engine-frame intervals**, in ms and engine fps, separately for the last Front-shadow OFF/ON window. It samples GetRealTimeSeconds on one EngineTick callback, not os.clock, dilated world delta or generated/presentation FPS. UE4.27's native getter returns World.GetRealTimeSeconds. Ignore the first second after a change; waits and large gaps reset the window. Parameter or light ON/OFF edits invalidate old comparisons. Shadow changes preserve the other mode's last value; reopening the panel clears stale/menu samples.

Keep camera, position, both light states and parameters fixed; wait2–3s with shadows OFF, press Num3 and wait2–3s ON. Repeat manually if useful. VSync/frame caps can conceal a performance difference; frame generation/presentation FPS can differ from engine fps. This is a small A/B aid, not GPU profiling or a guaranteed benchmark. No user graphics setting or external overlay is changed. A1s UI text refresh and a30-frame ownership check share the single cancellable per-frame handle; no recurring success logs or broad per-frame scans.

## Saving and lifecycle

Only Num9 writes `<own mod>/tuner-settings.ini`, plain bounded non-executable schema1 text. Startup reads only that file after a manual start; invalid/oversized input is rejected to diagnostic defaults with a log line. No auto-save. The file path is derived from the actual `@.../HildaSoftLightLiveTuner/Scripts/main.lua` chunk path; pinned LuaMod.cpp5995 creates that exact @filename. Settings are separate from game saves and other mods and are preserved when archiving this tuner.

There is no90s timer. The tuner runs until explicit STOP or a guarded integration/context failure. On failure, intent becomes inert first, the exact loop handle is cancelled, both owned components are hidden/self-destroyed with native IsValid=false checks and only the own viewport host is released. No forced GC/unload or global cancellation. A lost/changed gameplay HUD/pawn/root or current GameViewport.World is a stop condition; there is no rebind/respawn/cutscene/travel support. This is containment, not accepted broad world-transition behavior. Cached primitive identities are re-resolved, rather than blindly dereferencing old UObject wrappers. Native renderer/Slate deferred release is not measured as immediate memory reclamation.

## Validation and handoff

`tests/test_live_light_tuner.py` reuses the existing Lua5.4 fixture for bounded policy/orchestration checks: independent bounds/steps, save parsing/explicit writes, frame windows, current-key collisions, dark partial setup/cleanup, UI failure, panel-hidden no mutation, shadow gating, pending-stop/pawn-loss and no recreation. The UI is mocked in orchestration tests; they do not claim real viewport/shadow/native setter execution. No new test framework or dependency is installed.

See [LIVE_TUNER.md](../../docs/LIVE_TUNER.md) for source/install identity and current evidence. Raw engine source, snapshots and machine paths remain `.local/`. The minimal next native check is this one tuner session: start, alter one value per light, hide/reopen, save, toggle Front shadows and STOP. The assistant reads the local log after the user's report. No visual acceptance is claimed in advance.
