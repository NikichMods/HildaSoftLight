# Статус

Текущий этап — research-only трёхкомпонентная Unitless/exponent калибровка в `research/live-light-tuner`; main и релизы не меняются. Принятые продуктовые решения: [REQUIREMENTS](REQUIREMENTS.md). Точные источники/сохранённые сессии/установка: [LIVE_TUNER](LIVE_TUNER.md).

Последний старый F10/bare NumPad кандидат source4e0fe21 работал примерно11мин после READY до закрытия игры без нового failure в логе. Подтверждены model0+1/floor0 и управляющие действия. Пользователь сообщил о визуальной проверке работающего тюнера, но подробного отчёта нет; SAVED/manual STOP не записаны. Это ограниченное положительное наблюдение старой интеграции, не приёмка трёх источников, теней, пресета или полного lifecycle.

Новый кандидат: Character Front/Back channel1 и Environment Fill channel0, три own PointLightComponent с bUseInverseSquaredFalloff=false и Unitless до регистрации. Независимые intensity/falloff/radius/XYZ/K/on, Front shadows. Environment может влиять на Hilda channel0+1. Старый lumen/schema1 профиль не мигрирует и не перезаписывается, новый explicit schema2-файл отдельный. Начальные числа диагностические.

Optional F/B/E text markers в том же own UMG host следуют реальным world transforms. Divide toggle, только редактор, без доп. компонентов/действий; behind/offscreen скрываются. Native numeric projection/DPI/slot sanity проверяются; marker failure отключает только markers. One EngineTick/input safety/cleanup всех3 сохраняются.

Offline policy/projection проверки не заменяют новую runtime-марshalling/rendering/визуальную приёмку. Production/полный lifecycle/художественные числа остаются открытыми. Следующий шаг — один пользовательский run нового кандидата с F/B/E/falloff/markers/SAVE/STOP, затем чтение локальных логов.
