# PointLight runtime experiment

**BOUNDED RUNTIME PASS — manual path,2026-10-30.** Creation, ON/OFF, guarded follow and native user cleanup ran successfully; user confirms a visible light effect. Automatic timeout/Glimmer and separate per-surface visual acceptance remain unconfirmed. The probe has been archived/removed from active loading. See [the owning result](../../docs/RUNTIME_EXPERIMENT.md). Research-only Lua; no production version or release. Code lives in `research/pointlight-runtime/Scripts/main.lua`.

Question: can this Shipping game register, attach, display and logically destroy one independent transient PointLightComponent on the guarded gameplay Hilda pawn? R-016 proves the general owned-component route, not this light. A small probe is needed because native rendering and visual appearance cannot be proved from declarations or mocks. No UI/Widget/Slate layer is included.

## Temporary diagnostic parameters

| Parameter | Test value / reason |
| --- | --- |
| Mobility | Movable (2); no baked/static light |
| Units and intensity when ON | Lumens (2), 60 lm; explicit small diagnostic source, not stock unitless2.4 or default5000 |
| Attenuation | inverse-square=true, radius350 cm; bounded nearby illumination |
| Linear color | R1 G0.9 B0.75 A1, SetLightColor(...,true); encode to the FColor sRGB storage consumed by GetLightColor; warm neutral diagnostic, no accepted art setting |
| Offset | root-local X60 Y0 Z30 cm; outside the torso to permit direct model lighting; no guessed bone/socket |
| Shadows / indirect / volumetric | off / 0 / 0; no particle/mesh/material/postprocess changes |
| Initial state | Invisible and intensity0 before FinishAddComponent; the first key only creates DARK |
| Lifetime | 90000 ms from preparation completion; one creation attempt per process |

Lighting Channels are read from Hilda's mesh and one blocking surface reached by a single 250cm downward LineTraceSingle(query0, no debug, self ignored). The new light uses their union, checked for intersection; no channel on a foreign object is written. A missing hit/empty mask stops before allocation. A floor hit is a sampled collision surface, not proof of every material, shadow, translucency or level. Its actual illumination still requires observation.

## Controls and first run

1. Start the game normally and load a gameplay scene; stand on solid ground near a wall in shadow. Do not trigger a level change/cutscene or save during this bounded experiment.
2. **Ctrl+Alt+F8** once creates/registers/attaches the light while keeping it OFF. Further presses toggle ON/OFF. Walk a few steps between comparisons; each press records component/root movement and transform agreement.
3. If Glimmer is available, toggle it normally while the probe is active and note whether its operation remains independent. Do not alter progression to obtain it.
4. **Ctrl+Alt+F7** permanently stops this process's probe and destroys only its light. For the independent timeout path, a separate game process/run can instead leave the component alive for90s; do not treat manual stop as a timeout test. Report which cleanup path was actually observed.

After stop, Ctrl+Alt+F8 cannot recreate the light. F7 may retry incomplete cleanup. The probe never restarts the host. No active lifetime starts while merely ARMED in menus. Wrong UIOnlyMap/DefaultPawn contexts are skipped; retry F8 after normal gameplay loads. A genuine preparation/contract failure ends the attempt, with no Actor fallback.

`RegisterKeyBind`/explicit EngineTick dispatch and cancellation follow R-016. Both chords are checked by IsKeyBindRegistered before arming. After stop the key callbacks remain **inert** until process exit; no unverified UnregisterKeyBind API is invented. Queued simple EngineTick actions have no cancellation handle and check intent/phase before object reads. The retained timeout and monitor handles are individually cancelled and queried. A copied callback can still be delivered; guards prevent further object access/creation.

## Native path and assertions

Exact gameplay class: `/Game/MainContent/Act/Character_BP/hilda_BP.hilda_BP_C`, validated through the unique in-viewport HUDMainUMG_BP_C owning pawn and GenesisCharacter ancestry (R-004). Root comes from K2_GetRootComponent; model comes from pawn.Mesh.

StaticConstructObject(`/Script/Engine.PointLightComponent`, pawn, own FName, RF_Transient) → record cleanup identity → configure DARK/Movable/parameters → pawn.FinishAddComponent(component,true,MakeTransform(...)) → component.K2_AttachToComponent(root,None,KeepRelative×3,false). Native owner/Outer, root parent, transient/native CreationMethod, settings, color/channels and world position are read back. No stock `light` child or `Lights` entry is modified.

The saved UHT has **no direct IsRegistered/bRegistered/IsRenderStateCreated readback**. READY records FinishAddComponent returning plus native owner/attachment/settings and transform agreement; it does not assert a directly measured registration bit or visible rendering. Actual light on model AND geometry is the remaining renderer evidence.

A30-frame monitor checks native validity, target identity, settings and transform, without broad scans, per-frame transform writes or routine logs. It is separate from a90s delayed timeout. Construction/registration/attachment/destroy have before/after markers to localize native failures. Logical destruction requires pending-kill-aware KismetSystemLibrary.IsValid=false even when the Lua wrapper remains valid; no immediate GPU/GC release is claimed.

The RF_Transient/native-owned component is intended to be nonpersistent under the source contract. No game save API is called; save serialization and full travel lifecycle are not runtime-proven by this test. Level changes, death, respawn, cutscenes, persistent settings and FPS benchmarking are excluded.

## Minimum evidence and gates

| Scenario | Required evidence | Failure effect |
| --- | --- | --- |
| Dark allocation/register/attach | TARGET, construct/configure/finish/attach markers, READY and guarded readbacks | Stop/cleanup; no fallback |
| ON/OFF + short walk | ON/OFF logs with root/component positions; user sees local light and original image after OFF | No runtime PASS if absent |
| Glimmer if available | User reports ordinary Glimmer toggle remains independent; own state guard stays satisfied | Separate unresolved interaction if unavailable |
| Manual stop | CANCEL active=false for owned handles; DESTROYED native_valid=false; CLEANED reason=user; visible light gone | Block cleanup acceptance |
| Independent timeout, separate process | Corresponding CLEANED reason=timeout and light gone after90s | Remains UNTESTED until actually run |

Python tests execute this actual Lua source under an existing Lua5.4/lupa runtime and inject setup/registration/attachment failures and stale callbacks. They test containment and control flow only. Command: `python tests/test_pointlight_runtime.py -v`; optionally set `HSL_TEST_LIBRARIES` to an existing local lupa installation. No dependency is downloaded and no test framework/CI is scaffolded.

## Source provenance and installed state

Use [source-manifest.json](source-manifest.json) for payload SHA256, exact metadata/source input hashes and evidence limits. R-016 infrastructure and R-018 static game facts remain in [Asterigos-Research](https://github.com/NikichMods/Asterigos-Research/blob/main/docs/VERIFIED_RUNTIME.md). New source-reviewed diagnostic dependencies: KismetSystemLibrary.LineTraceSingle/FHitResult; UE4SS83330635 [weak-object property marshaling](https://github.com/UE4SS-RE/RE-UE4SS/blob/83330635/UE4SS/src/LuaType/LuaUObject.cpp#L1637) and [FWeakObjectPtr.Get](https://github.com/UE4SS-RE/RE-UE4SS/blob/83330635/UE4SS/src/LuaType/LuaFWeakObjectPtr.cpp#L47). These exact call combinations are untested in the game and must fail closed before allocation on mismatch.

Installed status and rollback identity belong in [docs/RUNTIME_EXPERIMENT.md](../../docs/RUNTIME_EXPERIMENT.md). Raw logs, local paths and snapshots remain `.local/`; no runtime result is fabricated here.
