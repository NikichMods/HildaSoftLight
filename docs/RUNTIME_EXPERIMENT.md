# Первый PointLight runtime-эксперимент

**PREPARED / UNTESTED**, 2026-10-30. Ветка `research/pointlight-runtime`, база `1f3038992ed507b5abea1d88a9aad9ef74235a21`. Main не меняется; production gate остаётся BLOCKED.

[Исходник, параметры, управление и критерии](../research/pointlight-runtime/README.md), [payload manifest](../research/pointlight-runtime/source-manifest.json).

Вопрос: работает ли в настоящем Shipping runtime собственный transient PointLightComponent с guarded pawn Outer, attachment к root и FinishAddComponent, включая реальное освещение модели/геометрии и native logical destruction? Параметры диагностические, окончательная архитектура и визуальные настройки не приняты.

Подготовлены явное создание в выключенном состоянии, on/off, чтение каналов модели/пола, контроль owner/parent/flags/settings/позиции, ручная очистка и независимый90s timeout. По10 проверкам Lua5.4 подтверждена логика отмены, частичной очистки и запрета повторного запуска; mocks не доказывают Unreal API, rendering, input или timeout в игре.

## Установка и откат

**Установлена, но не запускалась.** Точный источник payload: commit `3e3eada6fe73cc5b25010e12f67b5e3f3eb43887`; SHA256 `56f0d51af6ad61ba939302250a224e65a92b3cdc9fe0a599f1e61185f1003259`. Установленный файл побайтно совпадает с Git blob и manifest. Локальный install manifest: `.local/pointlight-runtime/install-20261030T080004Z/manifest.json`; резервные копии исходного Mods и предыдущего лога сохранены рядом. Приватный `.local/pointlight-runtime/current-install.json` — точка входа в текущую установку.

До установки собственного каталога не существовало. Активны были только CombatHUD и SoulsEnemyHUD, в их Lua не найден RegisterKeyBind; неактивные IIP-пробы не включены. Runtime-проверка точных chord collisions остаётся в ARMED gate. Добавлены ровно два файла: свой Scripts/main.lua и пустой enabled.txt. Все40 исходных файлов Mods и18 protected inputs (UE4SS DLL/settings, Engine.ini и файлы SaveGames) сохранили SHA256. Mods.txt не редактировался. Настройки loader уже имели HookEngineTick1, default EngineTick и auto-reload0, они не менялись.

Проверка готовности отката выполнена при закрытой игре: установленный собственный каталог содержит ровно ожидаемые два файла с ожидаемыми хэшами; baseline совпадает. **Откат не выполнен**, проба оставлена доступной для пользовательского запуска. Приватный helper `.local/pointlight-runtime/preparation-tools/install_probe.py` имеет режимы `verify-rollback` и `rollback`; последний при закрытом host переносит только проверенный собственный каталог в приватный install archive, затем проверяет весь первоначальный Mods manifest. Это не изменение/замена чужих модов.

 Исходное состояние и SHA всех существующих файлов Mods, UE4SS DLL/settings и предыдущих логов сохраняются локально до любого изменения; игра должна быть закрыта. Payload должен совпадать с опубликованным исходником. Установка добавляет только собственный `HildaSoftLightRuntimeProbe/Scripts/main.lua` и enabled.txt, не редактируя mods.txt. Условие загрузки enabled.txt проверено в точном UE4SSProgram.cpp83330635, строки1645ff.

Откат при закрытой игре — убрать только собственный enabled.txt и перенести собственную папку за пределы Mods, сверив manifest; чужие файлы не заменять. В запущенной игре F7 убирает native компонент/действия, но сам loader payload остаётся до закрытой установки/отката. Это разные состояния.

## Ожидаемый следующий результат

Пользователь запускает игру вручную: F8 с Ctrl+Alt создаёт DARK, следующие нажатия дают сравнения ON/OFF; несколько шагов проверяют следование; F7 с Ctrl+Alt очищает. Локальный UE4SS.log исполнитель читает сам после сообщения пользователя. Для автоматической очистки нужен отдельный реально выполненный run с ожиданием90s; текущий source/mock PASS её не заменяет. Glimmer проверять только если уже доступен.

Реальный прогон, визуальное освещение, ручная/timeout очистка и совместимость с текущим сохранением пока **не проверены**. Повторно используемых новых runtime-фактов для Asterigos-Research ещё нет.
