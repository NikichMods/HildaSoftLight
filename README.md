# HildaSoftLight

Локальное освещение Хильды в **Asterigos: Curse of the Stars**. Приняты три независимых PointLightComponent: Character Front/Back на channel1 и Environment Fill на channel0. Точный Unitless-профиль сохранён; Glimmer, игровая экспозиция, материалы, чужие каналы и saves не меняются. Environment может подсвечивать и Хильду.

**Первая production-версия0.1.0 готовится как кандидат, не stable release.** Автоматическое освещение, безопасное освобождение/повторная привязка и editor Ctrl+Alt+F10 реализованы, но новые runtime-пути ещё требуют пользовательской приёмки. [Статус](docs/STATUS.md), [кандидат/установка/тест](docs/CANDIDATE-0.1.0.md), [readiness](docs/PRODUCTION_READINESS.md).

Normal gameplay не создаёт собственный UI. Editor использует bare NumPad; Num7 выбирает любой источник, Num9 сохраняет. Num* ставит собственный свет на паузу, Ctrl+Alt+F10 возобновляет. Close editor не гасит свет. Полная инструкция — в кандидате/пакете.

Установку в общую игру пока не выполняем: другой отдельно проверяемый SoulsEnemyHUD0.3.3 ещё не принят. Изменения не объявляются исправлением ранее наблюдавшегося native UE4SS crash. Архивы research и принятых чисел сохранены.

- [Требования и принятый профиль](docs/REQUIREMENTS.md)
- [Research tuner / исторические evidence](docs/LIVE_TUNER.md)
- [Общая база Asterigos](https://github.com/NikichMods/Asterigos-Research/blob/main/docs/RESEARCH_INDEX.md)

Оригинальный software — [MPL-2.0](LICENSE); [область прав](LICENSING.md). Игровые assets и UE4SS не входят в пакет.
