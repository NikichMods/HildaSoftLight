# Статус

Второй live tuner run **STOPPED_ON_FAILURE** после примерно7м25с; source55db771. [Доказательства и новая input revision](LIVE_TUNER.md). Ветка `research/live-light-tuner`, main не меняется.

Own diagnostic поймал function вместо ожидаемого UObject при CDO.GetClass внутри проверки viewport/world; native log также сообщил ошибку registry function ref. Последний успешный ввод — Front X40→42cm; Z/Num8 как причина не доказаны. Cleanup обоих lights/UI/action завершился.

Pinned UE4SS source показывает риск одновременного изменения hook Lua stack input-dispatch и исполнения кадрового callback. Это обоснованная гипотеза, точный interleaving не доказан. Подготовлена узкая ревизия: native клавиши и тюнер обслуживает один EngineTick loop, без RegisterKeyBind/ExecuteInGameThread handoffs. Safety guards и fault diagnostics сохранены.17 offline checks PASS; это не runtime-приёмка.

Следующий шаг — обычная пользовательская настройка новым кандидатом и анализ локального лога. Числа сбойной сессии сохранены как evidence, не auto-saved preset; явное сохранение только Ctrl+Alt+Num9. Визуальная эффективность теней/FPS, стабильность новой интеграции и production остаются непринятыми. Релиз не выпускается.
