# Статус

Первый runtime-эксперимент **PREPARED / UNTESTED**, 2026-10-30, ветка `research/pointlight-runtime`. [Подготовка и установленное состояние](RUNTIME_EXPERIMENT.md), [инструкция/исходник](../research/pointlight-runtime/README.md). Main не меняется.

Подготовлен один собственный transient PointLightComponent с pawn Outer/root attachment, первоначально DARK, управляемыми on/off и ручной/90s timeout очисткой. Диагностические60лм/350см, inverse-square, linearRGB1/0.9/0.75 и offset60/0/30см не являются принятыми настройками мода. Каналы только собственного света определяются по прочитанной модели и одному blocking floor hit.

Подтверждены статические declarations/source contracts и10 проверок логики Lua5.4; настоящие вызовы LineTrace/weak-pointer decoding, lighting register/attachment, renderer, visual follow, Glimmer independence и cleanup требуют игрового прогона. Прямого reflected IsRegistered нет; readbacks не выдают за видимый рендер.

Следующий шаг — безопасная установка точного опубликованного payload при закрытой игре, затем пользовательский короткий игровой тест по инструкции. Production gate BLOCKED. Нет версии/релиза/визуальной приёмки. Смена уровня, смерть, respawn, кат-сцены и FPS вне текущего этапа.
