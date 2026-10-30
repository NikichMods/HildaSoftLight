# Live tuner — подготовка

**Первый tuner run остановлен защитой; диагностическая ревизия PREPARED/UNTESTED**,2026-10-30. Ветка `research/live-light-tuner`, база подтверждённого manual runtime `d01606534066cf0ac99edc3a6041fd4b92feda3e`. Main остаётся без изменений. Это research-only инструмент, не релиз и не утверждённый визуальный пресет.

[Раскладка, параметры, ограничения и короткая процедура](../research/live-light-tuner/README.md), [точные SHA256 исходников/API](../research/live-light-tuner/source-manifest.json).

## Сбой первого tuner-прогона,2026-10-30

**PARTIAL RUNTIME / STOPPED_ON_FAILURE. Точная причина пока неизвестна.** В12:10:55.635 МСК защитная ветка завершила тюнер: CANCEL handle1 removed=true/active=false, native destroy обоих источников, release собственного UI и CLEANED reason=failure. Это не Num8 STOP и не таймер: у Num8 только выбор параметра. Пользователь связал исчезновение панели/света с регулировкой высоты и возможным Ctrl+Alt+8; лог не записывал control sequence, поэтому конкретная клавиша/параметр не подтверждены.

Реально исполнен source9099d05161b0369e2912dd90cacad0782f772673, installed main SHA2562b98e0e688cd2e318768bbe41cbdbf7298f2990e0dc9adaca158cf776c3a6166. Лог архивирован как `.local/live-light-tuner/run-20261030T090604Z/UE4SS.log`, SHA256 `e93622b0721af0cea9809307f9322f756612f7566e06bd240ae99d86b290b74c`. В нём50 current virtual bindings прошли preflight, UI load/Create/label/viewport и оба create/register/attach завершились, READY12:06:46.224, затем23 front-shadow native toggles вернулись с readback. Caps: quality3, project support1, cube1, Hilda CastShadow/dynamic=true; sampled floor CastShadow=false, это нельзя менять ради теста. Визуальная эффективность теней и FPS не приняты.

Вместо ожидаемого failure detail в raw log есть только `[Lua]` префикс без текста (повторяется после cleanup); байтов FAILED и NUL нет. **Причина потери текста не установлена**; изученный pinned LuaLibrary.cpp print contract сам по себе её не диагностирует. Одно CLEANED reason=failure доказывает исключение/нарушенный guard, а не конкретный owner/transform/UMG сбой. Не трактовать это как доказанный баг высоты.

Новая диагностическая ревизия сохраняет на failure отдельный `tuner-diagnostic.log` через стандартный Lua file I/O: last key, current stage, snapshot чисел и traceback. Это диагностический файл, не auto-save presets, он не загружается при старте. Native log получает ASCII-escaped detail после cleanup. Добавлены CONTROL строки по клавиатурным действиям; per-frame logging нет. Guards/допуски/раскладка/свет не ослаблены и не менялись. Числа этого прогона не восстановимы из старого лога; SAVED-событий и tuner-settings.ini не было.

15 offline checks PASS, включая Z/selector sequence и сохранение fault trace при искусственном нарушении readback. Реальная причина требует одного повторения в игре с новой диагностикой; никаких альтернативных renderer/UI/Actor механизмов не вводится. Диагностическая ревизия PREPARED/UNTESTED, а не объявленное исправление первопричины.

## Выбор минимального механизма

R-018 действительно подтвердил собственный transient PointLightComponent, on/off, следование и native manual cleanup. До кода повторно прочитан R-017 и точный IIP userwidget-host/probe: отдельный PostionItemUMG_BP_C, собственный WidgetTree/TextBlock, первый Construct Hidden, последующий показ и RemoveFromParent уже имеют принятый runtime результат. Поэтому новая панель использует этот путь, а не игровой HUD, PrintString в Shipping, Coherent, pak или новый UI framework. Текущий tuner-композит ещё требует проверки, но отдельная инфраструктура для UI не обоснована.

Два источника Front/Back независимы, имеют explicit Lumens/inverse-square, live native setters, начальные4/2лм, поля radius/XYZ/temperature. Front shadows — отдельный native SetCastShadows с readonly gates. Панель одна, клавиатурные Ctrl+Alt NumPad команды не потребляют ввод. Текущие50 известных keyboard virtual IDs проверяются scalar native resolver до появления объектов; новая array marshaling схема не вводится.

## Статические доказательства и нижние проверки

- DevRules checkout `f7ee85645659d1d947b2b7b0636e6cf8dcdfeb1d` не менялся относительно предыдущего этапа; применены engineering, Git, local installed-runtime и live-calibration contracts.
- Установленный UE4SS83330635 LuaMod.cpp523ff действительно регистрирует NUM_ZERO…NUM_NINE/MULTIPLY;5995 задаёт @filename для safe own file path. UHT содержит SetTemperature/SetUseTemperature, K2_SetRelativeLocation, UMG panel APIs и read-only CVar getters.
- UE4.27 LightComponent.cpp: SetCastShadows52ff→MarkRenderStateDirty; SetTemperature934ff/SetUseTemperature954ff→native light update, GetColoredLightBrightness1353ff применяет temperature multiplier. ShadowSetup.cpp проверяет dynamic-shadow flags, GetShadowQuality, project point-light support иdesktop path; RendererSettings.h702 связывает project flag с r.SupportPointLightWholeSceneShadows. GetConsoleVariableIntValue не изменяет CVar и возвращает0 при отсутствии — такой результат блокирует shadow request. Установленный GameUserSettings sg.ShadowQuality2 сам по себе не доказывает итоговые runtime CVars; tuner читает их нативно.
- UE4.27 GameplayStatics.cpp2281 возвращает World.GetRealTimeSeconds. Счётчик даёт реальные интервалы EngineTick, не CPU os.clock/дилатированный gameplay delta и не display/generated FPS. VSync/cap не меняются.
- Lua5.4 syntax и13 policy/orchestration tests PASS. Ранее sandbox не позволял доступ внутри временных директорий; вне этого ограничения те же offline tests выполнены успешно. Native UMG в этих тестах mocked; новых runtime API/теней/визуальной приёмки они не доказывают.

## Установка и runtime-граница

Перед установкой требуется закрытая игра, проверка loader/settings/active mods, private backup/hash manifest и совпадение payload с опубликованным Git blob. Добавляется только собственная папка HildaSoftLightLiveTuner с четырьмя Lua и enabled.txt; mods.txt/другие моды/настройки/сохранения не редактируются. Старый HildaSoftLightRuntimeProbe уже снят после принятого прогона; не включать его одновременно.

**Установлен при закрытой игре, ещё не запускался.** Payload source commit `9099d05161b0369e2912dd90cacad0782f772673`; каждый из четырёх installed Lua побайтно совпал с Git blob и [source manifest](../research/live-light-tuner/source-manifest.json). Narrow .gitattributes закрепляет LF у этих payload-файлов; первая попытка установки обнаружила CRLF/LF mismatch до изменения игры, затем identity была исправлена/повторно проверена.

Добавлено ровно5 файлов собственного каталога, сохранены baseline snapshot/предыдущий лог. Все44 исходных файлов Mods и19 protected inputs (UE4SS DLL/settings, Engine.ini, GameUserSettings.ini, текущие SaveGames) сохранили SHA256; mods.txt и активные CombatHUD/SoulsEnemyHUD не изменялись. Чужие неактивные probes не включались. Runtime IsKeyBindRegistered и current mapping preflight выполнятся только при пользовательском запуске; offline-проверка активных Lua не обнаружила RegisterKeyBind.

Private install manifest: `.local/live-light-tuner/install-20261030T085733Z/manifest.json`. **Готовность отката проверена, откат не выполнен**: exact own folder/known source hashes и baseline Mods совпали. Private helper `.local/live-light-tuner/preparation-tools/install_tuner.py` имеет режимы verify-rollback/rollback; оба требуют закрытой игры, rollback сохраняет пользовательский tuner-settings.ini в архиве. Код payload после установки не менялся.

 Private `.local/live-light-tuner/current-install.json` — точка входа в установку/откат. Откат при закрытой игре переносит только проверенную собственную папку за пределы Mods, сохраняя explicit tuner-settings.ini. Не возвращать старые игровые SaveGames поверх пользовательского прогресса.

Первый реальный run подтвердил прохождение двухкомпонентного setup/UI, температуры/начальных readbacks, native shadow toggles и combined failure cleanup. Изменение всех live полей, save write, видимый shadow effect и числовой FPS не приняты; точная причина последующей остановки неизвестна. Передача устанавливает минимального кандидата для такого прогона; пользователь сам запускает игру. Нет90s timer и автоматического запуска. На material blocker — cleanup/stop, без Actor fallback или большого UI workaround.


Контекст дополнительно связывает pawn.GetWorld() с текущим GameEngine.GameViewport.World, а не только старым живым pawn. Pinned UE4SS [LuaAActor.cpp49ff](https://github.com/UE4SS-RE/RE-UE4SS/blob/83330635/UE4SS/src/LuaType/LuaAActor.cpp#L49) предоставляет GetWorld; поля GameViewport/World отражены в текущих Engine.h/GameViewportClient.h. Их runtime-применимость в составе тюнера остаётся gate; offline world-change test подтверждает fail-closed/no-rebind логику. После синхронной загрузки UI-класса target заново разрешается до Create; stop-intent проверяется до появления света.
