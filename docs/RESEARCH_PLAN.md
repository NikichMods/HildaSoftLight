# План исследования и текущая граница

Текущий этап с2026-10-31: [production candidate0.1.0](CANDIDATE-0.1.0.md); следующие research-разделы сохраняют историю, не ограничивают отдельно разрешённый production-development.

## Текущий шаг

Первый статический этап и single-light manual runtime завершены; старые разделы ниже — история выбора. Сейчас пользователь разрешил трёхкомпонентный Unitless/exponent live tuner и optional UMG projection markers. Достаточная подготовка: точные native contracts, offline policy/OutParm checks, source/install identity и безопасный откат. Следующая неопределённость — реальный рендер новой схемы и marker alignment/OutParm/DPI. После подготовки установить closed-game и ждать одного пользовательского run; не расширять исследование в renderer/framework/respawn support. Точные текущие границы и evidence: [LIVE_TUNER](LIVE_TUNER.md).

## История: вопрос и граница

Как добавить независимый слабый локальный источник света с минимальным числом предположений и безопасным удалением? Решение этапа — предпочтительный технический кандидат и точная граница первого runtime-теста. Только локальная статическая проверка и официальные источники; никакого runtime-кода, запуска игры или установки.

## Итог этапа

Статический этап завершён. [LIGHTING_FEASIBILITY.md](LIGHTING_FEASIBILITY.md) содержит сравнение, точные пути/хэши, предпочтение собственному компоненту на root pawn и спецификацию первого runtime-эксперимента. [STATUS](STATUS.md) — текущая стадия. Следующее задание на первый runtime-эксперимент получено: текущая подготовка и установленное состояние описаны в [RUNTIME_EXPERIMENT.md](RUNTIME_EXPERIMENT.md), отдельная ветка `research/pointlight-runtime`. Статический результат сам по себе не был разрешением установки.

## Уже существующие доказательства

Единственный общий источник — [Asterigos-Research/VERIFIED_RUNTIME.md](https://github.com/NikichMods/Asterigos-Research/blob/main/docs/VERIFIED_RUNTIME.md). R-004 доказывает guarded startup owning pawn Хильды, но не универсальный respawn/replacement. R-016 доказывает конкретный собственный transient WidgetComponent, регистрацию/ручную очистку; это не доказательство освещения, привязки PointLightComponent или полного level-travel lifecycle.

## Гипотезы и проверка

| Кандидат | Что проверить | Что может изменить выбор |
| --- | --- | --- |
| Независимый Engine.PointLight Actor | Точный SpawnActor API установленного UE4SS, component reference, attachment, transient/ownership/teardown | Дополнительные actor lifecycle и spawn/defaults против готового компонентного пути |
| Собственный Engine.PointLightComponent с pawn Outer | Применимость R-016, reflected setters, независимая ветка attachment | Нативная регистрация света и попадание под штатный writer |
| Изменение штатного Glimmer | Только определить границы/владельца | Не соответствует требованию независимости, не кандидат реализации |

Отдельно найти Glimmer/flash-light Actor или компонент, его owner, параметры, связи и writers. Для каждого вывода сохранить точный путь, исходный источник, версию, хэш и пределы. API UE4.27/современных UE4SS docs не считать автоматически доступным в установленной версии.

## Завершение

Остановиться после обоснованного сравнения и описания одного следующего технического эксперимента. Полное исследование всех локаций/кат-сцен, подбор красивых чисел, production и runtime-проба в этот этап не входят.
