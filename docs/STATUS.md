# Статус

**Рабочий профиль принят; сравнение завершено; причина native crash остаётся открытой.** [Результат/лог/возврат модов](COMPARISON_RESULT_2026-10-30.md), [принятые значения](REQUIREMENTS.md). Ветка research/live-light-tuner, runtime source b392c3c неизменен; main/релизы не затрагиваются.

Пользователь одобрил сохранённый Num9 профиль с Front intensity0.15 Unitless. Canonical active-unitless-v2.ini совпадает с установленным; остальные параметры трёх источников, включая ON/Front shadow, сохранены точно. Диагностические исходные defaults не заменяются. Это рабочая числовая/визуальная настройка пользователя, не полная production-приёмка.

Без SoulsEnemyHUD тюнер работал69мин до предусмотренного context STOP при загрузке игры; native destroy всех3/action cancellation подтверждены, игра не вылетела. После архивирования лога при закрытой игре exact prior активность SoulsEnemyHUD восстановлена, tuner rollback снова проверен. Активны CombatHUD, SoulsEnemyHUD и HildaSoftLightLiveTuner.

Один registry function-ref error UE4SS всё же записан в сравнении, хотя SoulsEnemyHUD был отключён. Виновник/причина прежнего native AV не установлены, исправление не заявлено. Crash-free comparison не является доказательством виновности другого мода.

Текущая версия завершает сессию при потере pawn/мира и не перезапускается в том же процессе. После загрузки свет исчезает ожидаемо; повторный запуск — новый процесс игры и Ctrl+Alt+F10 с сохранённым профилем. Автовосстановление/respawn/cutscenes/full lifecycle и compatibility — открытые отдельные этапы.31 прежний offline test относится к неизменной research-оркестрации; новые runtime сведения не заменяют эти границы.
