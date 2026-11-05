# HildaSoftLight0.1.0 — production candidate, NOT stable

Branch `codex/production-0.1.0`, base88d640f. First candidate version0.1.0 is immutable once handed. VERSION is canonical; tools/build.py checks Lua metadata, package instruction version and exact approved preset bytes, then verifies every package input against the recorded source commit. Archive is deterministic ZIP_STORED with fixed metadata. Runtime source `73b2c74e0f2bc49b675404efc14c29905e6e4402`. SHA-256 of `HildaSoftLight-0.1.0.zip`: `7c76372aa6085bd52154377bff2eb91c854cda2f921576625d0e62a7517d1b38`. All 56 offline checks passed. The ZIP from [CI run 41188596936](https://github.com/NikichMods/HildaSoftLight/actions/runs/41188596936) at `172d726` is byte-identical to the local candidate. The CI-only commit preserves the package inputs.

## Prepared behavior

Auto3-light binding in ready Hilda gameplay, periodic current context/HP validity fence, release then rebind with unique generations. Approved profile is unchanged. No own UI before F10; UI destroyed on close; native setters apply live values without another light set. Num* pauses, F10 resumes + opens editor. Optional UI/markers isolated. Unexpected core error cleans before one cancellation and leaves late callbacks inert. No LoopAsync/ExecuteInGameThread/input callbacks.

Source/capability basis: [PRODUCTION_READINESS](PRODUCTION_READINESS.md), R-004/R-017/R-018, accepted69-minute tuner session and exact working profile. Full lifecycle/appearance/native safety remains unproved for this source. Existing UE4SS native crash is not claimed fixed. HP>0 is the chosen bounded readiness/death fence, not evidence of every game's death/cutscene transition.

## Installable payload

Canonical folder HildaSoftLight/:5Lua Scripts (main/Profile/EditorView/Projection/KeyboardBindings), DefaultProfile.ini, VERSION, enabled.txt, README.txt, LICENSE and LICENSING.md. No loader, other-mod files, pak, game asset or generated dump. No mutable settings file in ZIP. Existing own user profile must be preserved/copied on first tuner→production migration, never overwritten on update.

Пользователь установил кандидат вручную. На 2026-11-05 все 11 установленных файлов совпадали по SHA-256 с манифестом ZIP, а старой папки `HildaSoftLightLiveTuner` в `Mods` уже не было. Рядом с файлами кандидата находится отдельный пользовательский `settings-unitless-v2.ini`. Игровые сессии загружали именно сохранённый профиль (`profile=saved`). В нём Environment Fill выключен, поэтому `lights=3` означает три привязанных компонента. Художественная проверка всех трёх одновременно из этого счётчика не следует.

## Подтверждено в игре

- **Автозапуск.** Логи 4 и 5 ноября 2026 фиксируют `LOADED profile=saved` и затем `BOUND generation=1 lights=3 auto=true ui=false` до открытия редактора.
- **Повторная привязка.** 4 ноября после `ClientRestart` в 16:19:14 записано `RELEASED reason=context_pawn lights=0 generation=1`, затем в 16:19:20 — `BOUND generation=2 lights=3 auto=true ui=false`. Это подтверждает очистку и восстановление в наблюдавшемся переходе игрового контекста.
- **Редактор.** 5 ноября редактор открылся в 19:29:12, закрылся в 19:29:22 с освобождением UI при входе в меню и снова открылся в 19:29:40. Между этими событиями журнал не показывает освобождения или повторной привязки света.
- **Наблюдения пользователя.** На игровых скриншотах Character Fill улучшает читаемость Хильды в темноте. При опробованных настройках Environment Fill давал заметные пятна на полу и стенах. Пользователь также сообщил об отсутствии света мода в наблюдавшихся катсценах. Причина в этих сценах не установлена.

Исходные UE4SS-логи хранятся локально. SHA-256 сессии 4 ноября: `90a5b5bc868b0610aae77afc96655406fb50dc56688544872cf671f0db847e83`. SHA-256 сессии 5 ноября: `676937dcc0eeb4a2f954b40a27a19b843775495f8892f8d89e9c5296f62af9f7`.

## Offline/native gate separation

Local tests cover initial readiness, approved/default/user settings, no UI/key-audit at normal start, repeated loads/HP0/pawn replacement, unique names and one handle, UI/marker faults, partial3-component cleanup, incomplete cleanup circuit break, cancel failure/late inert callbacks, key edges across editor/resume, pause/resume and shadow comparison. Syntax and schema roundtrip/preset hash checked. UI/native calls are mocked there; these are not native auto/load/death/renderer PASS. Автозапуск, один тип повторной привязки и цикл редактора подтверждены отдельно игровыми логами выше.

## Открытые проверки

В доступных записях нет отдельного подтверждения цикла `Num9 → перезапуск → чтение нового значения`, перехода между мирами, сценария смерти и возрождения, проверки Glimmer, Num* и визуального отсутствия дублей. Совместный запуск с другими модами сам по себе не закрывает проверку совместимости. Явная приёмка кандидата для стабильного выпуска остаётся открытой.
