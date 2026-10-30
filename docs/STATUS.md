# Статус

Самостоятельный проект создан; первый ограниченный статический этап завершён 2026-10-30. Main содержит требования и основу проекта; подробные записи находятся в [research/lighting-feasibility](https://github.com/NikichMods/HildaSoftLight/tree/research/lighting-feasibility), [точный отчёт](https://github.com/NikichMods/HildaSoftLight/blob/1f3038992ed507b5abea1d88a9aad9ef74235a21/docs/LIGHTING_FEASIBILITY.md).

Предпочтительный технический кандидат — собственный transient PointLightComponent с pawn Outer, вне штатной ветки `light`. Архитектура и числовые параметры не приняты; работа света/attachment/cleanup в игре не проверена. **Production gate BLOCKED.** Готового мода, версии, релиза, runtime-пробы и установленного payload нет.

Повторно используемые статические факты сохранены как [R-018 в Asterigos-Research](https://github.com/NikichMods/Asterigos-Research/blob/fed4d466a4e861d4e94509df561dbff6be3f4f38/docs/VERIFIED_RUNTIME.md#r-018--hilda-stock-flash-light-component-chain-and-independent-lighting-apis-static-2026-10-30).

Следующий необходимый шаг после отдельного задания: подготовить один research-only runtime-эксперимент создания/регистрации/привязки собственного компонента, короткого on/off при движении Хильды и ручной/timeout очистки. Проверка смены уровней/pawn и визуальная настройка остаются последующими gates. На текущем этапе игра не запускалась и установленная среда не менялась.
