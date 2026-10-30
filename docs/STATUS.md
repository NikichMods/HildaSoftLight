# Статус

**PARTIAL_RUNTIME / NATIVE_CRASH; сравнительный прогон подготовлен.** [Точная диагностика и граница](NATIVE_CRASH_2026-10-30.md). Ветка research/live-light-tuner, main/релизы без изменений.

Трёхкомпонентный source b392c3c работал23м44с после READY до EXCEPTION_ACCESS_VIOLATION в UE4SS на GameThread. Native light setup/parameter actions и marker numeric projection/DPI gate прошли; новый visual preset, полноценные shadow/marker appearance и lifecycle не приняты. Конкретный виновник и причина native crash не установлены. Подробности прежних этапов: [LIVE_TUNER](LIVE_TUNER.md).

Сохранены CrashContext/minidump/логи/exact payload. Последние несохранённые числа восстановлены в приватный schema2-файл, не применены. Установленный код тюнера не менялся, исправление не заявлено.31 прежняя offline-проверка остаётся evidence оркестрации, не гарантией отсутствия native вылета.

По прямому согласию пользователя для одного теста временно отключён только SoulsEnemyHUD (mods.txt1→0), его исходники/остальные моды/настройки/сохранения не заменялись. Активны CombatHUD и HildaSoftLightLiveTuner. Точный возврат prior mods.txt подготовлен и hash-проверен; private current-install содержит comparisonManifest. После следующего пользовательского run сначала сохранить логи, при закрытой игре восстановить активность SoulsEnemyHUD, затем оценить результат. До обычной установки/rollback сначала снять эту activity exception. Это не постоянная смена состава модов и не доказанное исправление.
