# HildaSoftLight — working contract

Проект `NikichMods/HildaSoftLight`: очень слабый естественный локальный свет для Хильды в Asterigos: Curse of the Stars. Начинать с [DevRules/WORKING_RULES.md](https://github.com/NikichMods/DevRules/blob/main/WORKING_RULES.md) и его карты чтения; для локального checkout применять CODEX_WORKFLOW.md. Исключений из DevRules нет.

## Владение и доказательства

- Это самостоятельный мод; единственный общий источник знаний игры — [NikichMods/Asterigos-Research](https://github.com/NikichMods/Asterigos-Research), вход [docs/RESEARCH_INDEX.md](https://github.com/NikichMods/Asterigos-Research/blob/main/docs/RESEARCH_INDEX.md). До нового исследования читать применимые принятые результаты и ограничения; в частности R-004 и R-016 в VERIFIED_RUNTIME.md.
- Исходный проверенный контекст: Steam 1.09/build 12996889, UE4.27, Windows x64, UE4SS v3.0.1-1181-g83330635. Это baseline исследований, не заявление о проверенной совместимости нового мода.
- Спецификация: [REQUIREMENTS](docs/REQUIREMENTS.md); текущая стадия: [STATUS](docs/STATUS.md); гипотезы и следующий эксперимент: [RESEARCH_PLAN](docs/RESEARCH_PLAN.md). Производственные решения и визуальная приёмка принадлежат этому репозиторию.
- Повторно используемые подтверждённые сведения игры сохранять в общей Research по ENGINEERING_RULES.md; не копировать изменяемый статус соседних модов. Объектные пути, UHT-декларации, исходники движка и выполненные игровые вызовы — разные уровни доказательств.

## Границы

Не менять глобальную экспозицию/гамму/тонмаппинг, Glimmer, игровые эффекты, частицы, настройки, сохранения или другие моды. Собственный свет должен быть независимо отключаемым и очищаемым. Интенсивность, радиус, цвет, положение и окончательная архитектура не утверждены.

Текущий разрешённый этап — research-only live tuner в `research/live-light-tuner`; см. docs/LIVE_TUNER.md. Два независимых собственных PointLightComponent Front/Back, минимальная текстовая панель, клавиатура, live bounded настройки и явное сохранение только в файл мода. Front имеет native shadow toggle; Back без теней. Начальные4/2лм — диагностические. Нет90s timeout; ручной STOP/потеря target отменяют own callback и удаляют свои компоненты/UI. Установка только closed-game с проверенным откатом; игру запускает/закрывает пользователь. Не переходить к production, Actor fallback, Coherent/pak/framework, respawn/travel/cutscene support или выпуску релиза.

## Git и приёмка

`main` содержит основу проекта; статическое исследование освещения — `research/lighting-feasibility`, текущая runtime-проба — `research/pointlight-runtime`. Документация может попадать в main по DevRules; непроверенное runtime-поведение — только в отдельной ветке. Перед production необходим reviewable evidence gate; для stable — пользовательская визуальная приёмка и проверка жизненного цикла. Не назначать номер до реального build/handoff.

## Лицензирование

Оригинальные материалы проекта — MPL-2.0, см. [LICENSING.md](LICENSING.md). Игровые ассеты, сырые дампы, извлечённый код и приватные пути остаются вне публичного Git; локальные исследовательские входы хранить под игнорируемым `.local/`.
