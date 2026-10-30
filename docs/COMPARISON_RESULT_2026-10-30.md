# Comparison result and accepted working profile —2026-10-30

One-run comparison completed, exact SoulsEnemyHUD activity restored. Executed source remains `b392c3c952d8bbb10ae197886b3e1b8c71422168`,5Lua unchanged. No source fix/release is claimed. User reports no game crash and approves working values; explicit clarification adopts Num9 Front0.15 Unitless, not the later unsaved0.05.

## Evidence

Private snapshot `.local/live-light-tuner/comparison-result-20261030T190236Z` was taken BEFORE restoring mod activity. It contains raw logs, exact installed scripts, explicit profile and last-live diagnostic snapshot. UE4SS.log SHA256 `00e13d811e600b9baba99e63f993c3afb13e9f0350c0ec788abcd76db668afce`; Genesis.log `8cadc175b84ff1654b873ba014b3ce99979ed3246c1898666c660dcb14e0f2f6`; own diagnostic `3e441a8245b9f4c79a643da6c812c35a40ccbde7e530d4fc6846424976e7d909`. Private raw reports are not uploaded.

READY20:39:38.248 МСК; same2560×1440 / DPI1.333333373 numeric marker-projection gate returned with valid out tables. Tuner remained active until21:48:42.882, about69m04s. Multiple native parameter/ON/shadow controls and seven explicit SAVED events occurred, last SAVE21:45:55.276. User reports no game crash; Event loop end22:00:13.258 is present and the latest native crash folder remains the earlier20:23 report. This is one successful crash-free comparison, not proof of permanent stability or SoulsEnemyHUD causality.

Important residual evidence: at21:44:57.325 the global UE4SS log still records `Lua::Registry::get_function_ref: Ref was not function` while SoulsEnemyHUD is disabled. HSL controls/SAVE continue after it. Module/owner/cause of this registry error is not localized; it must not be hidden or equated with the earlier native AV. Removing SoulsEnemyHUD did not eliminate this error, so there is no basis to declare it the sole culprit or permanently disable it. Broader loader/other-mod fixes are not part of this profile acceptance.

## Save/load is the expected context-stop boundary

Genesis log21:48:42 (native timestamp18:48:42UTC) records LeavingMap→LoadMap UIOnlyMap→BeginTearingDown world01; subsequent LoadGameDataLevel→world01 follows at21:48:50–51. HSL21:48:42.882 cancels handle1 removed=true/active=false, native-dead for each light1/2/3, CLEANED own_lights0/own_viewport0/action_handles0; guard detail says `pawn expired` at frame_context. No later HSL control event before process exit.

The generic diagnostic labels this guarded context end FAILED/reason=failure, but it matches the designed no-rebind research boundary and did not crash the game. Do not infer an intensity/property defect from that marker. World/UI teardown was already in progress; CLEANED reports own_viewport0 but there is no separate ui_release event in this stop. This is logical context cleanup evidence, not immediate GPU/GC measurement. The current stopped session cannot restart via F10 until a new game process; no respawn/load-support claim is adopted.

## Accepted values and preservation

Explicit saved profile SHA256 `70bd93107584767a3993524bb003d4d7b28cd92867b54364c855bfda109420ea`, schema2, matches new canonical [active-unitless-v2.ini](../research/live-light-tuner/profiles/active-unitless-v2.ini). The only difference from the21:48 diagnostic is Front intensity: saved0.15 vs last-live0.05. User explicitly chose0.15; all other fields of the25-field profile are unchanged. [Requirements](REQUIREMENTS.md) own the accepted working table and its limited acceptance scope. The installed profile was already correct and was not overwritten. Its next manual start loads the chosen values; no lumen migration, new automatic save or source-default rewrite.

After the closed-game archive, the approved restore_activity.py restored exact prior mods.txt bytes/SoulsEnemyHUD1. Generic tuner verify-rollback passed again against all44 original mod files. Current activity is CombatHUD + SoulsEnemyHUD + own tuner, current-install records comparisonRestored=true. No other-mod source, loader, graphics or save was replaced; game was not launched/terminated by the agent. Comparison exception is closed.

Next project decision: retain these working numbers while separately deciding production lifecycle and unresolved native/registry compatibility. Do not turn one crash-free run into a stable release, or implement automatic respawn/load behavior solely from this feedback.
