# Статус

Первый live tuner run дал **PARTIAL RUNTIME / STOPPED_ON_FAILURE**,2026-10-30. [Точный лог/доказательства/диагностическая ревизия](LIVE_TUNER.md). Ветка `research/live-light-tuner`, main не меняется.

UI-host/text panel, оба light create/register/attach и начальные native parameter checks прошли, front shadow toggles возвращались. В12:10:55 произошло исключение/guard failure; cleanup отменил action handle, логически удалил оба света и выпустил UI. Сам failure detail потерян в нативном логе; связь с высотой/Num8 не доказана.

Подготовлена узкая диагностика с собственным tuner-diagnostic.log, traceback/current values/last key и ASCII-safe native log. Guards/тюнинг/раскладка не меняются.15 offline tests PASS; Z/selector regression в mocks не воспроизводится. Это не исправление ещё неизвестной первопричины.

Следующий необходимый результат — один пользовательский повтор с диагностической ревизией; исполнитель сам читает error file и log. Настройки по-прежнему сохраняются только Num9, автоматического preset save нет. Production/визуальная приёмка/полный lifecycle BLOCKED.

Диагностическая ревизия установлена при закрытой игре, source `55db771563dfbd5790982190931a4a9eb970eed4`; exact hashes/rollback подтверждены. Следующий run не запускался.
