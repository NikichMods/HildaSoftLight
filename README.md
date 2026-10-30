# HildaSoftLight

Исследовательский проект мода для **Asterigos: Curse of the Stars**: очень слабый локальный свет, который помогает видеть Хильду в тенях и немного освещает ближайшие поверхности, сохраняя темноту локаций.

Готового production-мода пока нет. [Первый runtime](docs/RUNTIME_EXPERIMENT.md) подтвердил собственный свет и manual cleanup. Последующий F10/NumPad tuner работал в сохранённой сессии без нового сбоя; полная визуальная приёмка не заявлена. Пользователь выбрал дальнейшую [трёхкомпонентную калибровку Unitless](docs/LIVE_TUNER.md): Character Front/Back channel1, Environment Fill channel0, управляемое затухание и optional собственные экранные метки. Новый кандидат отработал около24мин до native UE4SS вылета; [причина исследуется в разрешённом сравнении](docs/NATIVE_CRASH_2026-10-30.md), пользователь принял рабочие числа после сравнительного прогона, но исправление причины вылета и полная production-приёмка не заявлены. Glimmer, чужие объекты, экспозиция/гамма/тонмаппинг и игровые сохранения не меняются.

- [Требования и визуальная приёмка](docs/REQUIREMENTS.md)
- [Текущий статус](docs/STATUS.md)
- [План исследования](docs/RESEARCH_PLAN.md)
- [Общая база Asterigos](https://github.com/NikichMods/Asterigos-Research/blob/main/docs/RESEARCH_INDEX.md)

Оригинальные материалы: [MPL-2.0](LICENSE), область прав — [LICENSING.md](LICENSING.md).
