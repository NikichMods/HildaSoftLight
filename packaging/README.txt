HildaSoftLight - UE4SS mod

Candidate 0.1.0: stable publication requires new runtime acceptance.
Tested foundation: Asterigos Steam1.09/build12996889, UE4.27, UE4SS83330635.
This does not claim that the candidate fixes prior UE4SS native crashes.

Install only while the game is CLOSED. Extract HildaSoftLight/ into ue4ss/Mods/.
Archive/disable old HildaSoftLightLiveTuner first; never load both.
Do not replace settings-unitless-v2.ini on upgrade. It is deliberately NOT in this ZIP.
DefaultProfile.ini is the exact approved Unitless preset; no Lumens migration.
Manual startup is not required: valid Hilda gameplay context gets three own lights.
Context loss/HP0 releases the own lights and waits for ready context/rebind.
Load/death/respawn must be runtime-tested for this new candidate.

Ctrl+Alt+F10: open/close editor; if lighting was paused, resume and open editor.
NumLock ON. Bare numeric keypad only while editor is open:
7 source (Front/Back/Environment),8/2 parameter,4/6 value,5 step,
1 source ON/OFF,3 Front shadow toggle,/ markers,9 explicit save,0 close.
* pauses own lighting; Ctrl+Alt+F10 resumes. No hidden irreversible STOP state.
Closing editor releases own UI/markers and keeps the light.
An unexpected core error cleans/disables for the process; restart the game after diagnosis.
Optional UI/marker failure leaves core lighting running.

Settings: own settings-unitless-v2.ini, plain bounded schema2. Only Num9 writes it.
Unsaved live edits remain in memory during rebind, not in game saves.
No changes to Glimmer, graphics, foreign channels/mods or game saves.
Environment channel0 can also illuminate Hilda; no perfect isolation is claimed.
No game assets or UE4SS loader are bundled.

Source/license: https://github.com/NikichMods/HildaSoftLight ; MPL-2.0.
