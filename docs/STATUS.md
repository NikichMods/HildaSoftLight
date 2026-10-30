# Статус

Подготовлен research-only live tuner, **PREPARED / UNTESTED combined candidate**,2026-10-30. Ветка `research/live-light-tuner`, [текущие доказательства/установка](LIVE_TUNER.md), [управление/параметры](../research/live-light-tuner/README.md). Main не меняется.

Переиспользованы runtime R-018 для собственного света и R-017 для независимой viewport text UI. Два transient компонента Front/Back имеют независимые параметры и on/off; стартовые4/2лм, Back OFF, тени OFF. Front shadows идут через native SetCastShadows с readonly условиями. Панель и50-key current mapping preflight не меняют игровой ввод/настройки. Явное сохранение пишет только файл тюнера.

Нижние проверки: Lua5.4 syntax и13 policy/orchestration tests PASS. Новый composite UI/двухкомпонентный lifecycle, temperature/save/native shadows и frame counter требуют пользовательского runtime-теста. Тонкая настройка/архитектура не приняты. **Production gate BLOCKED**, релизной версии нет.

Кандидат установлен closed-game;5 собственных файлов добавлены,44 исходных Mods/19 protected inputs неизменны. Готовность точечного отката проверена, он не выполнен. Следующий шаг — пользователь запускает игру и открывает панель Ctrl+Alt+Num0 и проверить управление, shadows и ручной STOP по инструкции. Таймера90с нет. Потеря pawn/контекста прекращает исследование; полноценная поддержка respawn/travel/cutscenes не реализуется.
