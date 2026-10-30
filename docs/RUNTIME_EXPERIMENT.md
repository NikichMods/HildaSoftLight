# Первый PointLight runtime-эксперимент — результат

**BOUNDED RUNTIME PASS: создание, управление, следование и ручное удаление**, 2026-10-30. Это технический результат одной сессии, не production или художественная приёмка. Автоматический timeout и независимость Glimmer пока не подтверждены. Пользователь сообщил, что свет включился и светит; настройку/дизайн обсуждает отдельно.

Ветка `research/pointlight-runtime`; код пробы [3e3eada6fe73cc5b25010e12f67b5e3f3eb43887](https://github.com/NikichMods/HildaSoftLight/tree/3e3eada6fe73cc5b25010e12f67b5e3f3eb43887/research/pointlight-runtime). Lua SHA256 `56f0d51af6ad61ba939302250a224e65a92b3cdc9fe0a599f1e61185f1003259` совпал с установленным payload после прогона. Код не менялся по результату теста.

## Что проверялось и почему

Нужно было установить, работает ли source-supported путь собственного transient PointLightComponent с pawn Outer/root attachment/FinishAddComponent в настоящем Shipping runtime. R-016 ранее доказывал общий компонентный путь на WidgetComponent, но не свет. Технический PASS позволяет сохранить этот кандидат для дальнейших решений; он не выбирает визуальные настройки и не закрывает lifecycle за пределами одной сцены.

Среда: Steam1.09/build12996889, UE4.27, Windows x64; текущий лог UE4SS v3.0.1/Git83330635. Установленная DLL соответствует исходному SHA256 `ce5e3c46a920cc00b2817ac61e438c9162830290379d0b5b9c4dfc2b29459290`. Номер Steam-билда берётся из зафиксированного install baseline; новый полный pak/EXE hash не выполнялся.

## Наблюдённая цепочка

Лог в часовом поясе Europe/Moscow: ARMED11:08:38; READY11:09:07.433; CLEANED11:10:06.243. Компонент существовал примерно58.81с после READY, до90s timeout не дошёл.

| Стадия | Реальное доказательство |
| --- | --- |
| Выбор pawn/поверхности | Gameplay hilda_BP_C, root CollisionCylinder; одна blocking StaticMeshComponent пола. Маски каналов модели3, поверхности1, своего света3: пересечение есть с обоими |
| Создание и настройка DARK | Все before/after пары construct/configure_dark завершены; READY visible=false, intensity_ON60лм, radius350см, inverse-square=true, linearRGB1/0.9/0.75, offset60/0/30см |
| Регистрация/привязка | FinishAddComponent и K2_AttachToComponent вернулись; owner/Outer/transient/parent/параметры/transform guards прошли. Прямого reflected IsRegistered нет; не заявляется измерение этого бита |
| Управление | В11:09:10 ON60,11:09:43 OFF0,11:10:05 ON60. Пользователь отдельно подтвердил световой эффект |
| Следование | Всего123 guarded проверки состояния/позиции без ошибки; root displacement последнего snapshot1751.801см, component1651.423см относительно первого. Разница допустима из-за вращаемого root-local offset, каждый snapshot проверял ожидаемый transformed offset с ошибкой<1см. Это не FPS-замер |
| Ручное удаление | CANCEL monitor2 и timeout1: removed=true/active=false; HIDE returned=true; native K2_DestroyComponent вернулся; Kismet IsValid=false; CLEANED reason=user, own_component=false, action_handles0, key callbacks inert |
| После остановки | До Event loop end11:10:19 новых HSL событий нет. Принудительный GC и мгновенное GPU-освобождение не измерялись |

Сессия не содержит HSL FAILED/UNAVAILABLE/CLEANUP_PENDING/DISPATCH_FAILED. В полном логе два диагностических сообщения UE4SS — ConsoleManagerSingleton AOB неоднозначен и FObjectPtrProperty size unavailable. Оба дословно присутствовали в логе до установки этой пробы; новых ошибок исследования они не устанавливают. Причины/исправление loader предупреждений в эту задачу не входят. Строки ArIsError/bKismetScriptError — список offsets, не runtime exceptions.

## Предел визуального подтверждения

Подтверждение пользователя: свет включился и светит. Отдельное подтверждение качества освещения именно модели и геометрии, полного визуального возврата при OFF/cleanup и независимости Glimmer не получено. Лог подтверждает ON/OFF/native destruction, но не заменяет эти отдельные наблюдения. Параметры остаются диагностическими, художественная настройка и выбор архитектуры не утверждены.

**Timeout UNTESTED**: timer отменён вручную до90с. Не подменять это принятым автоматическим удалением. Level travel, смерть/respawn, кат-сцены, длительный FPS и production policy не проверялись. Новый игровой прогон в рамках анализа логов не запускался.

## Архив и установленное состояние

Сохранён закрытый лог SHA256 `7374c7a35b14dbc11df0c2754a58d0bfb5e6ead998e18437fd0d94c9684b3255`,59210байт. Приватный архив `.local/pointlight-runtime/run-20261030T080838Z/` содержит UE4SS.log, hsl-events.txt, run-summary.json и снятый установленный payload. Исходный install snapshot/manifest остаётся `.local/pointlight-runtime/install-20261030T080004Z/`; актуальный private pointer — current-install.json. Сырые логи/приватные пути не публикуются.

После архивирования при закрытой игре собственная папка HildaSoftLightRuntimeProbe перенесена за пределы Mods. **Откат loader payload выполнен**: Mods снова точно совпадает с40 исходными файлами по SHA256; mods.txt и чужие моды не редактировались. DLL/settings/Engine.ini сохранились. Изменения SaveGames после пользовательского игрового прогона, если есть, сохранены как текущий игровой результат и не откатывались; их число записано в private run-summary. Runtime-компонент уже был удалён пользователем до выхода; снятие payload — отдельный шаг.

## Дальнейшая граница

Технический manual-path результат сохранён. Сейчас дополнительных действий пользователя для этого анализа не требуется. Настройка света/дизайн — отдельное обсуждение по решению пользователя. Автотаймаут, отдельные визуальные уточнения/Glimmer и последующий lifecycle остаются открытыми gates, а не поручением немедленно продолжать тесты. Main/production/release не изменены.
