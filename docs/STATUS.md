# Статус

**Production-development0.1.0 реализован; подготовка installable candidate/CI.** Ветка codex/production-0.1.0 от88d640f. [Readiness](PRODUCTION_READINESS.md), [кандидат и native gates](CANDIDATE-0.1.0.md). Main/релизы не изменены.

Принятый рабочий профиль70bd93107584767a3993524bb003d4d7b28cd92867b54364c855bfda109420ea используется точно как default. Новый source автоматически создаёт свет без editor, освобождает own context и перепривязывает при готовности, сохраняет редактор и явное сохранение, Num* pause/F10 resume. Native death/load/respawn/новый UI lifecycle и совместимость остаются OPEN, не PASS по mocks. Старые crash/registry evidence остаются неразрешёнными; изменения не объявлены их исправлением.

**Установка отложена:** в общей игре появился независимый непроверенный SoulsEnemyHUD0.3.3. По прямому требованию пользователя не совмещаем его с новой HildaSoftLight. CombatHUD0.4.1 принят. В этой задаче чужие files/activity/loader/settings/saves не менялись. Продолжается разрешённая независимая подготовка ZIP/CI; после приёмки соседнего кандидата — отдельная closed-game установка с exact rollback и архивированием старого HildaSoftLightLiveTuner. Текущая установленная Hilda остаётся прежним исследовательским b392c3c, не production0.1.0.

Предыдущие числовая приёмка,69мин сравнения и возврат Souls activity: COMPARISON_RESULT_2026-10-30.md. Эти результаты не подменяют новое production acceptance.
