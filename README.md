# HildaSoftLight

Исследовательский проект мода для **Asterigos: Curse of the Stars**: очень слабый локальный свет, который помогает видеть Хильду в тенях и немного освещает ближайшие поверхности, сохраняя темноту локаций.

Готового production-мода пока нет. [Первый ограниченный runtime-эксперимент](docs/RUNTIME_EXPERIMENT.md) подтвердил технический путь собственного света и ручной очистки; настройки и production ещё не приняты. Исследовательская проба снята с активной загрузки. Штатный Glimmer должен сохранить своё поведение; глобальная экспозиция, гамма и тонмаппинг не меняются.

Первый статический этап завершён в [research/lighting-feasibility](https://github.com/NikichMods/HildaSoftLight/tree/research/lighting-feasibility). Предпочтительный кандидат — собственный PointLightComponent без теней на персонаже. Его работу в игре, архитектуру и визуальные параметры ещё предстоит проверить.

- [Требования и визуальная приёмка](docs/REQUIREMENTS.md)
- [Текущий статус](docs/STATUS.md)
- [План исследования](docs/RESEARCH_PLAN.md)
- [Общая база Asterigos](https://github.com/NikichMods/Asterigos-Research/blob/main/docs/RESEARCH_INDEX.md)

Оригинальные материалы: [MPL-2.0](LICENSE), область прав — [LICENSING.md](LICENSING.md).
