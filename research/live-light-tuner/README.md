# Three-light live tuner — research only

Working profile accepted; [comparison completed and SoulsEnemyHUD restored](../../docs/COMPARISON_RESULT_2026-10-30.md). Unresolved prior native crash/registry compatibility remains. Canonical [active-unitless-v2.ini](profiles/active-unitless-v2.ini) matches the current installed saved file; Front0.15 is the user's chosen saved value. Diagnostic starts below remain fallback when no valid file exists. Own PointLightComponent construction/registration reuses R-018, viewport host reuses R-017, single-EngineTick input avoids the previous input-thread handoff. Current source/install evidence and prior sessions: [LIVE_TUNER](../../docs/LIVE_TUNER.md). No release, artistic preset or production acceptance.

## Start and controls

Launch normally, load Hilda, stand on solid ground near a shaded wall. **NumLock ON**. **Ctrl+Alt+F10** enters/leaves editing; closing leaves the lights for comparison. Inside editing use **bare NUMERIC KEYPAD**, without Ctrl/Alt. Outside editing keypad does not edit the tuner. Input is not consumed; known50 game mappings and UE4SS exact bare/chord bindings are checked before effects and each reopening. Unknown engine/debug/OS shortcuts are outside that audit. Held keys cannot become deferred edits across mode/modifier changes.

| Key | Action |
| --- | --- |
| 7 | Cycle Character Front → Character Back → Environment Fill |
| 8 / 2 | Previous / next selected parameter |
| 4 / 6 | Decrease / increase |
| 5 | Fine / LARGE step |
| 1 | Selected source ON/OFF |
| 3 | Front native dynamic shadows OFF/ON, regardless of selected source |
| / (Divide) | F/B/E markers ON/OFF (not saved) |
| 9 | Explicit save to own tuner-unitless-v2.ini |
| 0 | Leave editing; Ctrl+Alt+F10 reopens |
| * (Multiply) | Final STOP inside editing: cancel action, destroy all3 lights, release own UI/markers |

## Units and diagnostic starts

| Parameter | Front | Back | Environment | Bounds; fine / LARGE |
| --- | --- | --- | --- | --- |
| ON | yes | no | no | independent |
| Lighting Channel | 1 | 1 | 0 | fixed |
| Intensity | 1 | 0.5 | 0.25 | **Unitless**,0…20;0.05 /0.5 |
| FalloffExponent | 2 | 2 | 2 |0.1…16;0.1 /1 |
| Radius |180cm |180cm |200cm |50…400cm;10 /50cm |
| Local X/Y/Z |60/0/30cm |−60/0/30cm |0/0/30cm |X/Y±150cm,Z−100…150cm;2 /10cm |
| Temperature |5000K |5000K |5000K |2500…8000K;100 /500K |
| Shadows |OFF, toggle |OFF |OFF | Front only |

These are cautious diagnostic inputs, not a visual preset or conversion from60lm/4lm. All three have bUseInverseSquaredFalloff=false and Unitless0 set BEFORE FinishAddComponent. Live edits use native SetIntensity/SetLightFalloffExponent/SetAttenuationRadius/K2_SetRelativeLocation/SetTemperature/SetCastShadows. No constant recreation, post-registration falloff-mode write or stock light/Glimmer mutation. Nonphysical falloff permits comparison; it does not guarantee that a wall hotspot disappears.

Hilda live channel mask0+1 and sampled geometry0 are read, never changed. Character channel1 isolates from that geometry. Environment channel0 can illuminate both geometry AND Hilda; it is not perfectly isolated from the character. Other scene objects may use other channel masks. Unsupported live channel intersections fail before allocating effects.

## Profile and lifecycle

Only Num9 writes the own `tuner-unitless-v2.ini`: bounded plain schema2/mode=unitless-exponent,25 complete fields. Old `tuner-settings.ini` schema1 is never loaded, converted or overwritten. Invalid v2 falls back to diagnostic defaults with a log entry. No automatic save. Editor/marker state is ephemeral; each session starts markers enabled, subject to availability.

Exactly one cancellable EngineTick loop handles keys, light invariants, frame samples and optional markers. No90s timeout, input-thread callbacks, game input-mode changes or game/foreign config writes. Pawn/root/mesh/world loss triggers guarded cleanup of all3 own lights and own viewport; no respawn/travel/cutscene recovery. Native logical destruction does not prove immediate GPU/GC release. STOP is final until the next game process.

## Markers

F(red), B(cyan), E(yellow) are three small own TextBlocks in the same independent host. All three mark actual component K2_GetComponentLocation even when a light is OFF, allowing positioning before enabling. They do not illuminate, occlude-test or enter a preset. Hidden editor/STOP removes their visible effect. New objects are allocated once under the private WidgetTree; no new Actor/component/pak/HTML/asset/callback.

Native WidgetLayoutLibrary.ProjectWorldLocationToWidgetPosition(controller,world,out,false) uses an owned FVector2D out table; native Slate performs screen→viewport geometry conversion internally. No opaque FGeometry crosses Lua. Host origin0 and slots are in logical viewport coordinates; size=physical viewport/GetViewportScale, with no second division of projected points. On the first valid point and each resolution/DPI change, compare against the accepted PlayerController.ProjectWorldLocationToScreen numeric-out route (rounded pixels / DPI,2 logical pixel tolerance). Log MARKER_PROJECTION with both coordinates; finite/bool/out/slot checks guard the route. Behind-camera false or off-screen results hide that mark. Minimized viewport hides markers. The tested candidate is one ordinary player viewport; unusual application scaling/custom screen projection/split-screen can reject the check.

A marker API/marshalling/coordinate failure disables/hides markers for the session and logs MARKERS_DISABLED, preserving light tuning. Native projection/colored-label integration and perceived alignment remain untested until the user runs this candidate. UHT/UE4.27 source and offline mocks are not native runtime proof.

## Comparison

Use7 to choose a source and1 to leave only that source ON; compare Front only, Back only, Environment only, then combinations. Use8/2 to select falloff,4/6 to vary exponent at fixed intensity/radius/camera. Change one field at a time. Toggle markers with Divide, move/rotate Hilda and camera, then close/reopen editing to check visibility and positions. Save with9 only when desired; finish with Multiply.

Front shadows retain native capability checks (r.ShadowQuality, r.SupportPointLightWholeSceneShadows, r.AllowPointLightCubemapShadows) plus Hilda caster flag telemetry; no CVar/config is written. New Unitless/channel1 shadow rendering still requires observation. Back/Environment remain without shadows. To compare performance, disable markers for both sides, hold camera/parameters fixed, wait2–3s OFF, toggle3 and wait2–3s ON. Panel displays one-second real engine-frame intervals(ms/fps) after1s settling; caps/VSync can hide differences. Marker/parameter edits reset comparisons; no graphics changes.

## Verification boundary

Offline tests cover three-source policy/units/channels, old profile preservation, explicit v2 save/parse, pre-registration mode, live setters/no recreation, partial1/2/3 cleanup, UI failure, marker fail-soft and controls. Numeric projection tests cover DPI once, out tables, bad types/coordinates, behind/offscreen/minimized and resize validation. UMG construction is mocked in orchestration: no claim of native marker rendering, Shipping visual acceptance, FPS gain or full lifecycle proof.
