# Lighting feasibility — статическое исследование, 2026-10-30

## Результат и предел

Предпочтительный **кандидат первого эксперимента**, не утверждённая production-архитектура: собственный `/Script/Engine.PointLightComponent`, RF_Transient, actor Outer = проверенный игровой pawn Хильды, привязка к его корневому SceneComponent вне штатной ветки `light`, регистрация через Actor.FinishAddComponent. Не менять штатные массивы/свет/эффекты и не создавать runtime-код на этом этапе.

Production gate **BLOCKED**: реальное освещение, point-light registration, attachment/follow, совместное поведение с Glimmer и level/pawn lifecycle нового компонента не проверены. Исследование закончено на границе точного минимального эксперимента; числовые настройки не приняты.

## Контекст и происхождение

- Внутренний baseline: Steam 1.09/build 12996889, UE4.27, Windows x64, UE4SS v3.0.1-1181-g83330635. Текущий Steam appmanifest 1731070 содержит buildid/TargetBuildID 12996889; установленная UE4SS.dll имеет SHA256 `ce5e3c46a920cc00b2817ac61e438c9162830290379d0b5b9c4dfc2b29459290`. Shipping EXE и pak целиком заново не хэшировались; это не свежая проверка всех игровых байтов.
- Повторно использованы сохранённые CUE4Parse-экспорты hilda_BP из предыдущего HP-исследования и UHTHeaderDump из сессии R-010. Новая выгрузка из игры не выполнялась. CUE4Parse reader проекта закреплён на 1.2.2; точный бинарь первоначального hilda-экспортера отдельно не переаттестован. Отсутствующие сериализованные поля не трактуются как false/zero.
- [Общий источник, проверенная ревизия](https://github.com/NikichMods/Asterigos-Research/blob/9c6d306108474feba04c9a25cb96d0ecbbd7aabd/docs/VERIFIED_RUNTIME.md): R-004 — guarded startup HUD owning pawn (`DefaultPawn` в UIOnlyMap следует пропускать); R-016 — один свой transient WidgetComponent с actor Outer/manual FinishAddComponent, EngineTick, native-validity-aware cleanup, позднее manual stop PASS. Эти результаты не тестируют PointLightComponent и не дают общей гарантии переходов уровней.
- [STATIC_EVIDENCE.json](STATIC_EVIDENCE.json) фиксирует точные SHA256 всех использованных входов и URL исходников. Локальный игнорируемый `.local/input-paths.json` связывает метки с реальными исходными файлами; сырые игровые дампы и исходники движка не публикуются.

## 1. Штатная световая ветка Хильды / кандидат Glimmer

Точный asset `/Game/MainContent/Act/Character_BP/hilda_BP`; класс `/Game/MainContent/Act/Character_BP/hilda_BP.hilda_BP_C`.

Сериализованное дерево SCS: нативный `CharacterMesh0` → `light` (`SkeletalMeshComponent`, шаблон `hilda_BP_C:light_GEN_VARIABLE`, export 89) → `PointLight` (`PointLightComponent`, шаблон `hilda_BP_C:PointLight_GEN_VARIABLE`, export 76). Это компонент персонажа; отдельный световой Actor в этой найденной ветке не требуется. Шаблон, CDO и живая instance — разные объекты: live world path, owner и текущие значения сейчас не наблюдались.

| Поле шаблона PointLight | Сериализованное значение |
| --- | --- |
| Intensity / AttenuationRadius | 2.4 / 1200 |
| bUseInverseSquaredFalloff / LightFalloffExponent | false / 2 |
| LightColor | R255 G231 B152 A255 (#FFE798) |
| CastShadows / CastStaticShadows / CastDynamicShadows | false / false / false |
| IndirectLightingIntensity / VolumetricScatteringIntensity | 0 / 0.1 |
| SpecularScale / bVisible | 0.3 / false |
| LightingChannels | записан bChannel2=true; неперечисленные каналы не установлены этим экспортом |

Не копировать эти числа в новый свет. `light` — меш `mi028_guardian_mesh` с `mi028_guardian_forlight` анимацией и bHiddenInGame=true в шаблоне; это также не live-состояние. Новый мод не должен создавать этот меш/анимацию/эффекты.

Контрольные смещения `ExecuteUbergraph_hilda_BP` (bytecode offsets, не адреса памяти):

- `SwitchLightEvent` → offset 15661 → `GenesisCharacter.InputUseBagItem(flash_light)`. Это сильная статическая связь штатной световой механики с flashlight item. Тождество локализованного названия «Glimmer», всех его эффектов/прогрессии и этой ветки отдельно в игре не проверено.
- `LightBeginPlay` → 18680 → 16967: подготовка временного массива, затем 16978 `light.GetChildrenComponents(false, Children)` и 17020 запись `LoopSceneComponent`. Цикл 5987ff отбирает PointLightComponent; 6260 добавляет их в `Lights`, 6328 сохраняет max intensity, 6418ff вычисляет скорость включения с длительностью не меньше 0.01.
- 5235 и 5894: `LightComponent.SetIntensity` на элементах `Lights` с ограничением к 0/max в соответствующих ветках плавного выключения/включения. `LightIntensityChangeTime_On=3`, `_Off=1` — CDO defaults, не гарантированные текущие времена.
- 17052: `light.SetVisibility(false,true)`; `LightTick` → 18675 → 17167ff, 17301: `light.K2_SetWorldLocation` после VInterpTo. 4433–4508: поиск свободной точки по LightLocations/LightCollisionSize. `ActiveLight` → 17974 добавляет `hilda_light_use` и выбирает штатный звук; `DeactiveLight` → 17885 — звук выключения. Поля `light vfx`, Attach/Detach/EventStop присутствуют отдельно.

Вывод из этой цепочки: присоединение нового света под `light` может включить его в штатную выборку или распространение видимости. Кандидат должен быть отдельной веткой под root pawn и не записываться в `Lights`. Это обоснование из найденного Blueprint, **не доказательство отсутствия любого другого native/cutscene writer**.

## 2. Что отражено в сохранённой среде

Полные объектные пути ниже образуются как `/Script/Engine.<Class>:<Method>`. UHT доказывает декларацию/форму параметров; его сгенерированные cpp — заглушки, не игровые реализации. Успешный вызов каждой строки через Lua не доказан.

| Владелец | Подтверждённые объявления |
| --- | --- |
| PointLight (не Abstract в dump), наследник Light | PointLightComponent reference, SetRadius(float), SetLightFalloffExponent(float) |
| PointLightComponent (не Abstract), наследник LocalLightComponent | SetSourceRadius(float), SetSoftSourceRadius(float), SetSourceLength(float), SetLightFalloffExponent(float); отражённые bUseInverseSquaredFalloff и геометрия источника |
| LocalLightComponent | SetAttenuationRadius(float), SetIntensityUnits(ELightUnits) |
| LightComponent | SetIntensity(float), SetLightColor(FLinearColor,bool bSRGB), SetIndirectLightingIntensity(float), SetVolumetricScatteringIntensity(float), SetLightingChannels(bool,bool,bool), SetSpecularScale(float) |
| LightComponentBase | SetCastShadows(bool), SetCastVolumetricShadow(bool), GetLightColor() |
| SceneComponent | SetMobility(EComponentMobility), SetVisibility(bool,bool), SetHiddenInGame(bool,bool), K2_AttachToComponent(SceneComponent*,FName,EAttachmentRule,EAttachmentRule,EAttachmentRule,bool)→bool, K2_SetRelativeLocation(FVector,bool,FHitResult&,bool) |
| Actor | K2_GetRootComponent()→SceneComponent*, FinishAddComponent(ActorComponent*,bool,const FTransform&), AddComponentByClass(...), K2_AttachToComponent(...), K2_DestroyActor() |
| ActorComponent / KismetSystemLibrary | GetOwner()→Actor*, K2_DestroyComponent(UObject*); static IsValid(const UObject*)→bool |
| GameplayStatics | BeginDeferredActorSpawnFromClass(WorldContext,Class,Transform,CollisionHandling,Owner), FinishSpawningActor(Actor*,Transform) |

Enums в dump: EComponentMobility Static0/Stationary1/Movable2; EAttachmentRule KeepRelative0/KeepWorld1/SnapToTarget2; ELightUnits Unitless0/Candelas1/Lumens2. Не переносить единицы интенсивности из иной falloff-модели.

`RegisterComponent`, `SetupAttachment`, `SetUseInverseSquaredFalloff` **не обнаружены как UFUNCTION** в просмотренных ActorComponent/SceneComponent/PointLightComponent headers. Они не являются обещанными Lua-вызовами. Использовать отражённый FinishAddComponent, нативный отражённый attachment и явно проверенные собственные pre-registration fields; не писать AttachParent/AttachChildren/owner arrays вручную. Наличие UPROPERTY не равно renderer update после прямой записи.

## 3. Actor через установленный UE4SS

[Официальная документация UWorld.SpawnActor](https://docs.ue4ss.com/dev/lua-api/classes/uworld.html) описывает `SpawnActor(UClass,FVector,FRotator)` и deferred GameplayStatics маршрут. В [точном LuaUWorld.cpp 83330635](https://github.com/UE4SS-RE/RE-UE4SS/blob/83330635/UE4SS/src/LuaType/LuaUWorld.cpp#L57) binding принимает класс и Lua-таблицы Location(X,Y,Z)/Rotation(Pitch,Yaw,Roll), затем делегирует native wrapper SpawnActor; этот файл сам не раскрывает реализацию deferred bridge. Проверена привязка API этой ревизии, но не успешное создание `/Script/Engine.PointLight` в Asterigos.

Actor route требует отдельной проверки spawn/defaults/flags, ссылки на световой компонент, настройки до первого видимого кадра, attachment и уничтожения. Lua SpawnActor overload не предоставляет Owner/RF_Transient аргументы. Просто назначить Owner не означает прикрепить Actor или гарантировать уничтожение с pawn. Создавать Actor через StaticConstructObject вместо spawn нельзя считать доказанным маршрутом.

## 4. Применимость компонентного пути

[Официальный StaticConstructObject API](https://docs.ue4ss.com/lua-api/global-functions/staticconstructobject.html) существует, но пример в текущих docs не заменяет pinned source и реально испытанный вызов R-016.

Проверенные R-016 исходники UE4.27 mirror `306a7e9f7fb53f14c2cb3bfd3854ad906710a17e` (это зеркало исходников Epic, не аттестация бинаря игры):

- ActorComponent.cpp 253ff/282ff: actor Outer определяет native owner; cooked PostInitProperties добавляет OwnedComponent. Outer или Lua wrapper сами по себе не GC root.
- ActorConstruction.cpp 1165ff: FinishAddComponent вызывает OnComponentCreated; при manualAttachment=true не выбирает/не заменяет root; применяет transform и регистрирует bAutoRegister компонент. Это общий путь, реально применённый в R-016 к WidgetComponent.
- SceneComponent.cpp 1776ff: K2_AttachToComponent делегирует AttachToComponent с заданными rules. Подтверждена source/декларация, но это новый attachment case для света.
- [LightComponent.cpp](https://github.com/AlexMercer-MA/UnrealEngine-4.27/blob/306a7e9f7fb53f14c2cb3bfd3854ad906710a17e/Engine/Source/Runtime/Engine/Private/Components/LightComponent.cpp#L805) 805ff добавляет свет в World.Scene при bAffectsWorld и допустимом render/visibility/intensity; DestroyRenderState 844ff удаляет light из Scene. SetIntensity 857ff обновляет цвет/яркость; SetCastShadows 52ff помечает render state dirty. Это source evidence, не выполненные здесь вызовы.
- [LocalLightComponent.cpp](https://github.com/AlexMercer-MA/UnrealEngine-4.27/blob/306a7e9f7fb53f14c2cb3bfd3854ad906710a17e/Engine/Source/Runtime/Engine/Private/Components/LocalLightComponent.cpp#L22) SetAttenuationRadius проверяет возможность dynamic data change и обновляет render thread; сначала требуется Movable. Новый компонент по исходнику начинает с Intensity5000/Radius1000, PointLightComponent с inverse-square=true: нельзя показывать необработанные defaults или брать stock2.4 как сопоставимую яркость.

Документация [Epic UE4.27 Point Lights](https://dev.epicgames.com/documentation/en-us/unreal-engine/point-lights?application_version=4.27) подтверждает динамическое назначение Movable, ограничение влияния AttenuationRadius и runtime-выключение через Visibility (не bAffectsWorld). [Inverse Square Falloff](https://dev.epicgames.com/documentation/en-us/unreal-engine/4.2---inverse-square-falloff?application_version=4.27) объясняет несопоставимость одних чисел при разных моделях затухания. Никакие параметры не выбраны только на основании docs.

Предлагаемая последовательность для будущего теста: explicit EngineTick; guarded gameplay pawn и root; RF_Transient собственный PointLightComponent с pawn Outer; Movable, начальная невидимость/нулевая яркость, отсутствие теней/volumetric contribution до регистрации; собственная ветка attachment без выдуманного сокета, ручная FinishAddComponent; проверить owner/parent/flags/readbacks; только затем кратко показать контролируемый свет. Использовать native setters, получить собственный handle и удалять только его. Предварительная невидимость предотвращает вспышку default5000; точные ненулевые тестовые числа/units согласовать при подготовке эксперимента.

Native KismetSystemLibrary.IsValid через точный CDO нужен после проверок null/обёртки; Lua IsValid не учитывает PendingKill. Очистка: свой light visibility off → self-allowed K2_DestroyComponent → native invalid; не считать это немедленным освобождением GPU/GC. Брать контекст/отмену из R-016, без копирования UI/Slate/asset-load machinery.

## 5. Сравнение и решение

| Путь | Предположения и жизненный цикл | Решение |
| --- | --- | --- |
| Свой компонент на pawn/root | R-016 уже доказывает общий native ownership/register/destroy; новые gates: световой renderer, attachment, каналы/визуальный результат, pawn replacement | Предпочтительный минимальный эксперимент; один свой объект и естественная actor-component принадлежность |
| Отдельный PointLight Actor | Binding доступен; spawn, default flash, flags, actor ownership/travel, attachment и destroy ещё отдельно не проверены | Резерв, если pawn-component путь не проходит конкретную проверку; сейчас больше новых предположений |
| Штатный Glimmer или его шаблон | Зависимость от Lights/fades/visibility/VFX и игровых состояний | Исключён требованиями; исследован только для установления границы |

Отключение собственного света технически просто через visibility, затем native destroy. Поведение при level travel **не доказано ни для одного варианта**; компонент имеет меньшую отдельную lifecycle-поверхность по source ownership, а не уже принятую игровую безопасность.

## 6. Минимальный следующий эксперимент — пока только спецификация

Один research-only transient компонент в одной загруженной gameplay-сцене, после отдельного задания на код/установку. Проверить: создание невидимым → native register/attachment к root → короткое выключено/включено с несколькими шагами Хильды → ручная очистка и timeout как страховка. Log должен связать точные pawn/root/own component, flags/owner/parent, ненулевую регистрацию по доступным readbacks, параметры/units и native-validity после destroy. Пользователь подтверждает реальный локальный свет на модели и поверхности и его исчезновение; одни property readback этого не доказывают.

Если baseline Glimmer уже доступен, отдельный короткий on/off этой штатной механики проверяет, что свой компонент не входит в `Lights` и не гасится её найденной веткой; не менять прогрессию ради подготовки сцены. Не разрабатывать автоматический уровень/кат-сцену/respawn harness. Переход уровня и pawn replacement — отдельный следующий lifecycle gate до production, а визуальная настройка — после технического PASS.

Неизвестны точные визуальные параметры/lighting-channel overlap/блики/просвет стен без теней, эффект действующих настроек/модов, игровая политика в кат-сценах/меню/смерти, повторное включение после travel. Материальная утечка света через стены переоткрывает выбор кандидата; не добавлять тени или глобальные коррекции молча.

В этом этапе не создано Lua/DLL/pak, не запускалась игра, не установлено ни одного файла. Сторонние community snippets не понадобились: внутренней базы, официальных docs и pinned source достаточно для выбора эксперимента.
