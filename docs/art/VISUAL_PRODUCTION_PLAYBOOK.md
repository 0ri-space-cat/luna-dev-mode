# LUNA: Dev Mode — производственный арт-мануал и банк промптов

> **[АВТОР §08.28]** Экономный интерьер: цельный румбокс с большей частью мелкого декора, ограниченная общая библиотека самостоятельных предметов; вся реальная съедобная еда отдельно. Не заказывать весь список реквизита. Призма проявляет исходный шифр, никакого перевода. Следы Прото — отсутствие связей, не вырезанный силуэт группового фото. Исследовательский уголок Они в Забытом крае, место открыто. Программируемые расходники пока проект на обсуждении.

> **Обновление автора §08.27:** [повторный аудит недостающих ассетов](ASSET_GAP_AUDIT_2026-11-27.md). Все интерьеры — цельная архитектурная румбокс-картинка и статичная камера; отдельные игровые объекты. Латинский шифр A–Z, русские надписи обычные. Видимые ноги/крылья существ имеют отдельные варианты; см. новый P17. Один интерьер с выходом на задник и доступом к HUD; не выбирать место без автора.
**27.11.2026 · Рабочий производственный регламент для ImageGen, арт-агента и интегратора.** Не второй игровой канон. Действующие игровые решения — [единый мануал](../manual/00_LUNA_PRODUCTION_MANUAL.md), прежде всего §08.26 и §09.8. Автор выбрал 2D+Z, модульные нарисованные окружения, фиксированный ракурс, отдельные 2D-спрайты и пространственные каркасы только для изнанки/специальных задач. Не начинать миграцию в полноценный 3D/HD-2D, не производить шесть текстур здания, не заменять готовых персонажей. Точное разрешение и плотность на экране ещё не утверждены: калибровка ниже обязательна. Это инструкция, не заявление о выполненной генерации или интеграции.

## 0. Вход в работу и источники
Открыть реальные файлы и изображения до заказа; не использовать описание как замену визуальному референсу. Если исходник недоступен, указать это и не утверждать совпадение стиля. Последняя прямая правка автора приоритетна.
- [Реестр подготовленных ассетов](../../assets/production/ART_ASSET_REGISTER.md), [существующая инструкция экспорта](../../assets/production/ART_PRODUCTION_MANUAL.md), [передача партии](../../assets/production/ART_HANDOFF.md), [одобренное](../../assets/approved/README.md).
- Эталон Classic: [Луна](../../assets/approved/characters/luna/palette_blue_lilac/explorer_v1/front.png); [Они](../../assets/approved/characters/oni/idle_front.png); [сводный лист пяти ракурсов](../../assets/production/characters/previews/classic-five-views.png); [фронты и диагонали](../../assets/production/characters/previews/classic-front-right.png); [авторский lineup](../../assets/production/characters/source/author-lineup.png). Для нового кадра главный референс — утверждённый кадр именно этого героя в той же форме/ракурсе; второй — эталон общего языка.
- [Манифест Classic](../../assets/approved/characters/luna/explorer_animation/manifest.json), [Chibi](../../assets/approved/characters/luna/chibi/manifest.json), [Chibi actions](../../assets/approved/characters/luna/chibi_actions/manifest.json). У них свои исходные размеры и pivots, не подменять размером нового экспорта.
- [Арт-направление окружения](ENVIRONMENT_ART_DIRECTION_AND_PROMPTS_V1.md), [атлас](ENVIRONMENT_REFERENCE_ATLAS_V1.md), [слои сцены](SCENE_ENVIRONMENT_LAYERING_AND_ANIMATION_V1.md), [бриф](SCENE_BRIEF_TEMPLATE.md), [предварительная ведомость](HYBRID_ENVIRONMENT_ASSET_PLAN_DRAFT.md), [правила сценария](../scenario/SCENARIO_DESIGN_GATE.md). Концепты — настроение, не карты или эталон точного пиксельного шага.
- [Утверждённый HUD-референс](../../references/hud/HUD_APPROVED_CURRENT_REFERENCE_2026-11-21.png), [исходный комплект](../../assets/approved/hud/godot/retro-ui-kit/README.md), [его промпты](../../assets/approved/hud/source/ui-pixel-v1/PROMPTS.md).
- В каждом заказе использовать **один главный референс + 1–2 строго целевых дополнительных**, с подписью роли каждого. Не смешивать десять разных картинок и стили других игр. Для персонажей приоритет идентичности, для тайлов приоритет геометрии, для окружения приоритет общего визуального языка.
- Перед пакетным заказом сверить последние авторские изменения, существующие ресурсы и только недостающие позиции. Никогда не считать наличие PNG доказательством готовности игры.

## 1. Художественная конституция
Этерния — оригинальная уютная пастельная матовая пиксельная RPG, живой современный/слегка футуристический магитех-город, природа, острова, животные, бытовой юмор. Каждый биом имеет собственную локальную палитру; не заливать всё лиловым. Натуральные крупные цветовые кластеры, намеренные ступенчатые контуры, 3–4 читаемые ступени на материале как ориентир, сдержанные блики, цельные тени, минимум шумных одиночных пикселей. У лиц сохранить характер и возраст. Вся сцена читается в реальном игровом масштабе, а не только при увеличении.
- **MAIN_WIDE_34** — основной внешний ракурс мягко сверху-сбоку: читаются фасады и широкая двуосевая игровая плоскость. **COMPACT_SEMISIDE** — заранее заданные компактные полубоковые композиции; не новый режим физики. **INTERIOR_ISO** — изометрические румбоксы по §09.8, с согласованными направлениями стен/пола и опорами предметов. **META_SPECIAL** — только явно заданная метасцена.
- Не генерировать 3D-рендеры для обычного мира, свободное вращение камеры, псевдо-объёмные гладкие здания, перспективное искажение из кадра в кадр. Иллюзия глубины: правильные перекрытия, высота, плоские спрайты здания, раздельные планы, дальний параллакс, контактные тени.
- Не копировать персонажей, тайлы, UI, фирменные элементы из других игр. Другие игры — только указание художественного принципа.
- Мир существует до механик: реальные дороги, дома, растения, быт; не вводить нелепые тестовые грузы/объекты для пазлов. Удалённые корневая скамья, каменная чаша, доска, табурет, RE70/71 не возвращаются. Стартовый холодильник — намеренный гэг; обычные холодильники также в интерьерах.

## 2. Один пиксель: калибровка прежде производства
**Четыре разных величины:** (1) исходный размер файла ImageGen, например 1024×1536; (2) размер подготовленного холста спрайта (у нового Classic 128×192); (3) логический художественный пиксель на общей сетке; (4) физический пиксель дисплея при масштабировании. Они не взаимозаменяемы. PNG 128×192 может содержать мелкий шум вместо чистых кластеров; одинаковые размеры файлов не гарантируют равную плотность. Промпт не гарантирует математическую сетку.
Подтверждённые исходные контракты:
| Набор | Холст / опора | Особенности |
|---|---|---|
| Подготовленный новый Classic | 128×192; pivot (64,184), нижний непрозрачный ряд y=183 у стойки | y от верхнего края; сохранять фазовые смещения, не подгонять каждую позу по высоте |
| Classic старого банка Луны и Chibi | собственные размеры и pivots из манифестов | не перезаписывать, конверсия только после калибровки |
| Слаймы | 64×48; pivot (32,43) | фазы прыжка, физическая высота отдельно |
| Взмах Луны, подготовленный | тело/пальцы 128×192; палочка 96×96; wand_grip (48,48) в данном атласе | индивидуальный grip каждого кадра из JSON; другие атласы сверять |
| Пробуждение | опора (96,184) в действующем манифесте | не насильно приводить к (64,184) |
| HUD | текущий UI-манифест, своя экранная сетка | не наследует зум/цвет мира |

**Gate P0 — эталонная калибровочная сцена.** Без массовых заказов взять неизменённые Classic/Chibi, Они, слайма, один новый тестовый тайл травы, камень, куст, дерево, дверной проём, один кристалл. Использовать один фиксированный ракурс, текущую физику 2D+Z и игровой зум. Отдельно показать сравнительный ряд на общей линии опоры и вид целого экрана с ходьбой, прыжком, поворотом, зумом (если предусмотрен). Сравнить 320×180 и 640×360 как прежние кандидаты, а также подходящее разрешение под реальные исходники и формат окна; **не объявлять любой из них выбранным**. Текущий game/project.godot задаёт viewport 1280×800 и canvas_items: это настройка прототипа, не художественное решение о сетке. HUD вне низкоразрешённого мира.
- Согласовать, сколько логических пикселей занимает стоящая Classic/Chibi в обычном кадре; зафиксировать U (world units на art pixel), W×H внутреннего мира, integer upscale/letterbox или crop, главный ракурс, размер тайла T (кандидаты 16/32), эталон роста и 3 образцовых материала. Не подгонять каждую новую картинку под другой масштаб.
- Превратить один эталонный PNG и кусок сетки в **reference calibration sheet**: трава, камень, персонаж, контур, кластеры, опора, дверь. Метки и сетка вне production PNG. Сохранить native + nearest ×4; версия калибровки, параметры и исходники записываются в реестр. Автор утверждает один набор. До P0 все размеры новых модулей только тестовые.
- Генерировать в высоком разрешении при необходимости, но привести к утверждённой логической сетке один раз. Определить фактический шаг кластеров по эталону, проверить горизонтали/вертикали и диагонали. Если шаг плавает, локально переработать или отклонить исходник; простое nearest-уменьшение не превращает живопись в пиксель-арт.
- Программный экспорт: RGBA, nearest, выровнять опору по метаданным, фиксированный canvas, обрезать только по известным границам, не деформировать пропорции. Для непрозрачных спрайтов жёсткая альфа 0/255 без цветного ореола; существующий экспорт Classic использует порог 144, не применять вслепую к другим семействам, воде, свечению и эффектам. Прозрачные пиксели очищать. Проверить native, ×4, игровой масштаб, светлый/тёмный фон. Полупрозрачность только в специально обозначенном эффекте/маске.
- В Godot: nearest-фильтрация, без потерь, без незапланированных mipmaps/сглаживания/дробного масштабирования; движение симуляции непрерывное, округлять при необходимости только визуальную проекцию, не позиции, коллизии, взгляды и хак. Проверить дрожание при FOLLOW и LOCKED, отсутствие швов в движении; не считать настройки применёнными без теста.

## 3. Общий конвейер и статус
1. Получить карточку заказа: ID, назначение, сценарий, референсы, ракурс, версия сетки, целевые размеры/опора, состояние, список того, что сохраняется и меняется.
2. Сделать 1–2 стилевые пробы; выбрать одну, не заказывать весь каталог по непринятой пробе. Сохранить оригинал без разрушительных правок.
3. Для серии использовать **один и тот же утверждённый кадр** как основу плюс ближайшую фазу, локально менять только нужный участок. Нельзя генерировать каждый кадр с нуля или делать 50 разных героев одним листом.
4. Экспорт детерминированным скриптом (Pillow/существующие export_*.py), манифестом и проверкой. Не извлекать кадры из визуально красивого, но кривого листа угадыванием. ImageGen — исходный рисунок; сборка, точная нарезка, палитра, опоры и атлас — код/ручная пиксельная доводка.
5. Превью: отдельные PNG, контактный лист в натуральном размере и ×4, GIF/loop только как QA (не production-источник), вид сцены в Godot. Проверить рядом с эталоном, а не отдельно. Если обнаружен лишний палец, рука, плавающий глаз, сломанная сетка или пересечение — отклонить/исправить локально, затем перепроверить соседние кадры.
6. Статусы: planned → source_candidate → prepared → visual_checked → author_approved (только явное одобрение) → integrated → runtime_verified. Не путать с approval GitHub или успешным экспортом. Арт-агент записывает реальный путь и статус в ART_ASSET_REGISTER; не менять уже одобренный кадр без причины. Автотесты только подтверждают структуру, не качество рисунка.
7. Пути существующих банков сохранять; новые партии в соответствующих source/prepared/previews, при необходимости approved после решения автора. Один asset ID, ревизии в Git; не перезаписывать чужой коммит. Не хранить огромный набор отклонённых дублей в production; не удалять исторические/используемые файлы без миграции. 

## 4. Персонажи и анимации
**Очередь:** сначала инвентаризация Luna Classic/Chibi и всех шести друзей, только недостающие ракурсы, движения, действия. Пять базовых направлений front, front_right, side_right, back_right, back; левые через зеркалирование только если не теряются асимметричные детали, ведущая рука, принт/застёжки, хвост и характерные особенности. Если зеркалить нельзя, отдельный левый кадр. Не утверждать, что все действия уже готовы. Front-right по действующему гайду — поворот примерно 40°, оба глаза видны, дальняя сторона сокращена. Вид со спины сохраняет задний силуэт, не рисовать второй фронт.
- Прежде чем делать движение, утвердить turnaround из существующих стоек и карточку идентичности: рост относительно Луны, силуэт, цветовые ramps кожи/волос/одежды, глаза, контур, обувь, аксессуары, асимметрия. Использовать точные образцы цвета из утверждённого PNG; не придумывать HEX. Одна форма Classic, отдельная согласованная Chibi для клонов; не добавлять третий дизайн.
- Луна: голубовато-сиреневый банк; не менять шляпу, лицо, возраст, волосы, костюм и пропорции при новой позе. Они: кит на худи, голубые шорты, босые ноги, **колени без швов** во всех ракурсах. Тоффи: выбранный второй фронт, длинные белые уши, жёлто-оранжевая полосатая толстовка, круглый подвес. Ори: белый худи, Земля на груди, голубой кончик хвоста. Лея: зелёное платье, длинные тёплые волосы, жёлтый полумесяц. Мия: две косы, очки, халат, пробирки трёх жидкостей, карман перекрывает нижнюю часть. Юки: выбранный костюм, круглый кулон, ярко-розовые волосы без ухода в фиолетовый. Источник — реестр, рисунок конкретного героя выше текста. Прото/Омега — [отдельный согласованный визуальный бриф](PROTO_LUNA_OMEGA_LUNA_VISUAL_REFERENCES_2026-11-19.md), не редизайн обычной Луны.
- Приоритет движения: idle/blink, walk, run, jump (подготовка/отрыв/воздух/посадка), хват/предмет/взмах палочки. Затем нужные по сценарию сон/пробуждение, двери, сидение/езда, плавание, полёт и эмоции/редкие постановки. Не рисовать весь декартов продукт действий и предметов: отдельно тело и предмет. Четыре фазы ходьбы/бега — ориентир существующих банков; длительности из манифеста, не объявлять универсальными. Для новых движений сначала одна диагональ, проверка на контакте и скорости, потом остальные нужные виды.
- Анатомия: ровно две руки и две ноги у гуманоидного героя (если скрыта одна — она не должна появляться дополнительно); плечо→локоть→кисть и таз→колено→стопа прослеживаются; никакой третьей руки, лишних пальцев, лишних глаз, дублирующих волос/ушей, сросшихся конечностей. Упрощённая пиксельная кисть допустима, не пытаться прорисовать пять микропальцев в каждом кадре. У фауны число конечностей из её эталона, не человеческий шаблон. Для Леи ноги над кучей зверей — отдельная постановочная поза, звери сохраняют реальные ID/слои.
- Одинаковый pivot тела на всех кадрах обычного цикла, стопы и посадка проверяются отдельно. Для прыжка и бега воздушная фаза сохраняет относительное смещение, не выравнивать её по нижней непрозрачной строке. Контроллер отвечает за реальную высоту, импульс, контакт, движение по земле; спрайт не телепортирует. Приземление по событию физики. Не сжимать голову и туловище при автоматической подгонке кадра. Проверка walk: planted foot не скользит относительно земли при выбранной скорости; нет мерцания неподвижных деталей, смены цвета, скачков ширины.
- Для предметов/палочек: тело с пустой рукой, отдельная нейтральная поза хвата, предмет отдельным PNG и отдельная маска пальцев поверх предмета. У каждого кадра grip(x,y), ориентация, слой перед/за корпусом. Не генерировать пальцы поверх уже вшитой палочки и затем добавлять вторую. Для взмаха использовать manifest release_frame; эффекты отдельно. Смена предмета не требует перерисовки всего героя. Зеркалирование переносит координаты по реальной ширине кадра и меняет нужные слои, не просто flip текстуры.
- Выборочные отдельные лицевые/портретные кадры для UI: сохранить узнаваемость, не переносить мелкие линии в игровой спрайт. Существующий HUD- портрет не мерило роста.

## 5. Банк промптов: обязательный заголовок + один модуль
Каждый заказ состоит из MASTER, конкретного модуля ниже, карточки переменных и NEGATIVE. Перед отправкой заменить все [PLACEHOLDER]; не отправлять пустые поля или неизвестные размеры как факты. Английский рабочий текст выбран для однозначности, но при необходимости можно переводить без изменения смысла. При редактировании вложить именно утверждённый кадр, задать область изменения. Референс прикладывается, а не только называется.

### P-MASTER (в каждый заказ)
~~~text
LUNA: Dev Mode, original cozy magical-tech 2D pixel-art adventure.
Use the attached APPROVED reference(s), not a redesign. Ref A = [PRIMARY exact asset and what to preserve]. Ref B = [style/grid or direction reference and its role]. Match the calibrated logical pixel grid [GRID VERSION / reference sheet], square pixel clusters, edge-step rhythm, outline weight, restrained matte shading, coherent color ramps and scale relative to the reference. Deliberate hand-placed pixel clusters, not high-resolution illustration downsampled into noise.
Camera/art view: [VIEW]. Output type: [ASSET TYPE]. Intended world size: [W x H logical pixels or calibrated ratio]. Source canvas: [W x H / aspect]. Output ONLY the requested element(s), with the specified empty margins, registration point and background. Preserve every approved detail outside [CHANGE REGION]. Keep the rest unchanged. No new story, geometry, characters, props, text or mechanics. Do not redesign to make the image prettier.
~~~
### P-NEGATIVE (в каждый заказ)
~~~text
No painterly blur, soft anti-aliased silhouette, airbrush, glossy 3D or plastic render, vector-smooth lines, fake pixel filter, inconsistent pixel sizes, random micro-noise, gradients on solid materials, texture compression artifacts, unrequested glow, watermarks, text, signatures, grid labels inside production art, shadows baked into isolated assets, extra objects or duplicates. No third arm, duplicated hand or leg, fused limbs, floating fingers, misplaced eyes, extra pupils, new costume details, changing face, wrong proportions, unrequested age change, clipped body, perspective drift or palette drift. No borrowed franchise designs. If an occluded limb is hidden, leave it hidden; never add an extra limb to make the pose clearer.
~~~
### P01 CHARACTER IDLE / TURNAROUND
~~~text
Generate ONE full-body transparent-background sprite of [CHARACTER / CLASSIC or CHIBI] in [DIRECTION], neutral relaxed idle. Ref A is the exact approved design of this character; Ref B defines only the view. Preserve facial identity, age, hair masses, outfit seams and markings, accessories, shoes, skin and color ramps. [CHARACTER-SPECIFIC LOCKS]. Arms empty, two arms and two legs total, natural occlusion, no object in hands. [DIRECTION DESCRIPTION]. Show the whole silhouette with clear padding around hair, feet and hands. Keep body proportions, head-to-body ratio and ground scale unchanged. Ground contact at intended anchor [PIVOT GUIDE]; exact positioning will be aligned by export. No floor, cast shadow, prop, labels, border, second pose. The result must read alongside the reference at actual game size.
~~~
Использование: front — симметрия исходника, side_right — профиль без второго видимого дальнего глаза, back — затылок/спина и правильные задние детали, diagonal — утверждённый угол. Для текущих подготовленных Classic исходная практика 1024×1536 → 128×192, при иной форме следовать манифесту, не навязывать старым Chibi.

### P02 ONE ANIMATION KEYFRAME (предпочтительный режим)
~~~text
Edit the attached approved [CHARACTER] sprite. Change ONLY body pose to [ACTION / PHASE / DIRECTION]; use Ref B as the neighboring accepted phase, not a new design. Exact pose: [LEFT LEG / RIGHT LEG / LEFT ARM / RIGHT ARM / torso / gaze]. Preserve fixed silhouette identity, face, palette, hair shape, clothes, accessories, proportions and view. Keep [PLANTED FOOT] in the same ground-relative location if this is a contact phase; [AIRBORNE OFFSET] must not be flattened. Exactly two arms and two legs, no duplicate fingers or wrists, correctly occlude the far limb. Empty hands unless grip specified. Transparent isolated full-body, same canvas/padding, no floor or motion lines. Do not bake translation, jumping trajectory, object or magical VFX into the body.
~~~
Пример WALK diagonal: contact — левая пятка впереди, правая сзади, противоположная рука вперёд; passing — левая опорная, правая проходит, кисти естественно меняются; затем противоположный контакт/проход. Это рабочая позовая схема, не замена существующего цикла. Для спрайт-листа максимум маленькая серия 2×2/1×4 только как концептуальный лист: клетки строго одинаковые, по одной позе, без надписей/перекрытия; если не соблюдено — генерировать по одному кадру. Нарезать и выравнивать программно; не просить ImageGen выдавать точный atlas JSON.

### P03 LOCAL CORRECTION (лишняя рука, лицо, цвет)
~~~text
Use the exact attached image as the base. Only edit the marked region [REGION]. Correct [SPECIFIC DEFECT]: [e.g. remove the duplicated third arm; retain one arm resting on the surface and one on the knees]. Preserve all pixels and features outside this region as closely as possible: face, eyes, hair, costume, silhouette, position, palette, pixel cluster size, transparency and view. Do not regenerate the whole character, add limbs, move the feet or change proportions. Return the same full canvas with the corrected localized region, no other modifications.
~~~
Промпт не гарантирует неизменность вне маски. Сравнить изображение с исходником: при возможности использовать маску и программный композит исправленной области, проверить стык; если правка изменила лицо или одежду, не принимать.

### P04 HAND GRIP / ITEM / WAND
~~~text
Same approved character and pose, edit only the indicated hand into a relaxed closed grip around an IMAGINARY item. No item drawn, no second hand, no duplicated fingers. Retain arm anatomy and body. The grip point is [x,y relative guide], consistent with neighboring frames. For the separate item request: draw exactly one [ITEM] at the calibrated scale and view, transparent background, no hand, no glow or shadow, clearly readable handle. Front fingers/occlusion mask is a separate aligned layer created during export.
~~~
Для движения палочки разделить body, wand, fingers по действующей схеме; точный угол/хват проверять наложением, не требовать от генератора математически точных координат.

### P05 FAUNA
~~~text
One original [SPECIES / state / direction] sprite for LUNA, based on approved [SPECIES REF] and the calibrated Luna/slime size sheet. Exact body plan: [limb count, eyes, tail, ears, species anatomy]; silhouette [DESCRIPTION], behavior/phase [IDLE, squash, takeoff, air, landing, walk, swim, etc.]. Same physical body and palette between frames, only pose changes. Feet/body base anchored consistently, no extra limbs, no added horns, wings or abilities. Clear compact pixel clusters, transparent isolation, no terrain, shadow or FX. Keep the species recognizable at [world size].
~~~
Для лягушки: квадратная низкая форма, глаза сверху, светлые щёки по реестру. Слайм — один желейный купол, один силуэт для согласованных стихийных цветов, форма меняется фазой, не каждый цвет новый зверь. Неон/яд/способности из действующих игровых данных, не из цвета. Гигантский розовый аксолотль-босс — рабочий кандидат, сначала силуэт обычного вида, затем позы/анимации отдельной утверждённой сцены, не заказывать арену как канон. Пиксель — особый белый кот, ступени отдельными игровыми объектами; не донор AIR_STEP.

### P17 MODULAR ANATOMY / REMOVE LIMB MODULE
~~~text
Edit the exact approved [SPECIES / VIEW / PHASE] sprite. Make the matched [BODY WITHOUT LEGS / WITHOUT WINGS / WITHOUT BOTH] variant. Preserve the original body shape, face, eyes, skin/fur, color ramps, head, tail, proportions and calibrated pixel grid. Remove ONLY the specified appendages, reconstruct the naturally continuous body contour where they attached; no stumps, wounds, holes, replacement limbs, new fins, extra eyes or altered scale. Keep the same canvas and registered body anchor; the contact geometry for this state will be validated separately. For separate appendage request, render ONLY the original [LEGS / WINGS] in exact corresponding view, phase and alignment, transparent, no body; front/back overlap and attachment anchors are defined in export. Do not change the creature's design, expression or other anatomy.
~~~
Готовить при первой генерации вида normal и варианты без ног/крыльев (оба и комбинированный при необходимости). Проверить overlay, фазы и точки крепления, не масштабировать тело; IS_ALIVE OFF не равно удалению модулей. Природно безногих не менять без причины, FLY не выдаётся наличием рисунка. Для сложных силуэтов допустимы согласованные полные кадры вместо модульного overlay. См. §08.27 и аудит §2.

## 6. Модульный мир: ручная карта, программная сборка, декоративная вариативность
**Не процедурная генерация уровней.** Авторская топология, высоты, секретные пути, проходы, здания, характерные виды, сцены и пустые зоны определяются картой (Sheets + SAI/эскиз). Сборщик выбирает только подходящие варианты поверхности и разрешённого декора по seed, не переставляет ключевые Entity и не меняет физику. Большие уникальные острова и панорамы не обязаны состоять из прямоугольной плитки. Тайлы задают материал, свободные пропсы — композицию, крупные модули — форму места. Игровые зоны непрерывны; шов рендера не равен смене Location ID.
### 6.1 Слои
1. Far backdrop: небо, облака, дальние скаты/острова, панорама; не коллизия, медленный параллакс.
2. Terrain: чистые поверхности пола/земли/воды, дорожки, переходы; ходьба и высота из отдельной авторской карты.
3. Elevation: стенки уступов, края островов, обрывы, маски/опоры, раздельные верх/бок/передний край. Не наклонять всю физику по нарисованному фасаду.
4. Static architecture/decor: цельные здания/фасады, большие массы леса, скалы, навесы. Отдельный front occluder при необходимости, не рисовать проходы поверх декора.
5. Gameplay Entity: отдельно каждый перемещаемый/оживляемый/клонируемый/взламываемый предмет, дверь, куст, одиночное дерево, зверь, мост. Чистая поверхность под ним, отдельная тень/коллизия. При удалении ни призрачного дубликата, ни дыры в фоне.
6. Animated decor: вода, листва, окна, листья, рыбы дальнего плана, частицы; шейдеры/малые циклы только когда это не настоящая Entity.
7. Foreground: навесы, кроны, края, локальная окклюзия; обычные физические цели и скрытые пути не путать с декором. Не повторять один шаблон тайника.
8. Light/masks and information: свет, день/ночь, руны/Призма, Фонарь, изнанка; отдельно от базового арта и HUD.

### 6.2 Тайловая матрица и бесшовность
После P0 выбрать T и модульные размеры кратные T. Для каждой необходимой пары материалов сначала один базовый квадрат, затем 3–6 **рабочих кандидатов** центра, 4 прямых края, 4 внутренних и 4 внешних угла, дополнительные комбинации только когда реально нужны. Ориентиры для autotile: 16 вариантов четырёх соседей или 47 blob-комбинаций восьми соседей, выбрать после теста карты. Не заказывать все пары всех биомов. Граница совпадает не только цветом, но и геометрией рисунка: край A должен встречать тот же материал на B; переходы A/B имеют согласованную ширину и одну ориентацию. Не поворачивать автоматически тайл с направленным светом/высотой.
- ImageGen сначала выдаёт **образец материала** и небольшую контактную плитку/пару переходов. Код или пиксельный редактор фиксирует точные крайние пиксели, wrap/edge signatures, маски углов, atlas grid. Если сетка модели неровная, не растягивать произвольно каждую ячейку: отбирать и дорабатывать отдельные элементы. Сгенерированный тайл не гарантированно seamless; тест обязательный.
- Проверка 3×3 и 8×8 повторов, случайные варианты в большой связке, прямой стык, все углы, Т-перекрёстки, внутреннее отверстие, ручей/берег и граница высоты. Сопоставить повторяемый рисунок на соседних краях по пикселям либо по заранее заданной edge signature; одинаковость граничной строки сама по себе не гарантирует отсутствие визуального шва. Проверить nearest, atlas gutters/extrusion при необходимости, движение камеры, day/night, отсутствие белой линии и повторяющихся пятен. Объекты/детали поверх поверхности не вшивать в каждый тайл.
- Начать с травы, сухой земли и камня, перехода трава↔тропа, воды/берега и скалы. Для леса тёмная подстилка/корни как отдельные модули, для города мостовая/плитка/газон, для побережья песок/мокрый песок/камень. Пещеры: стенки и пол, светящиеся кристаллы отдельно. Список расширять по карте и [ведомости](HYBRID_ENVIRONMENT_ASSET_PLAN_DRAFT.md), а не по симметрии таблицы.

### P06 MATERIAL TILE
~~~text
One square base material swatch for LUNA: [MATERIAL], in [VIEW and light direction]. Match the approved calibration sheet and target tile [T x T logical pixels]. Uniform playable surface, broad purposeful pixel clusters, restrained texture density, no isolated prop, flower, path, shadow, border, hole or elevation. Visually seamless repeat in both axes, motifs continue naturally across opposite edges; no central focal point or directional seam. Output a single flat square material swatch, exact edges to be finalized programmatically; no preview grid, text or character.
~~~
### P07 TRANSITION / EDGE MODULE
~~~text
Create a single transition between approved material A [ATTACHED] and material B [ATTACHED], orientation [N/E/S/W or INNER/OUTER CORNER]. Use both approved palettes and textures exactly, same logical pixel grid and art view. Mask/edge guide [ATTACHED] defines which side is A and B; do not change boundary layout. Consistent transition width [value], small natural clusters, no new objects, no cast shadows, no border frame. This module must join the existing material tiles; exact edge signatures and cell dimensions will be validated and repaired during export. Output one tile only.
~~~
### P08 ELEVATION / CLIFF
~~~text
One reusable height-edge module [edge orientation/inner/outer corner/vertical wall], using approved [top material] and [side material]. Fixed MAIN_WIDE_34 view, top surface and face meet at the supplied edge guide, height [world units / logical pixels]. Preserve the exact traversable top boundary. No invented stairs, hidden passage, holes or new ledges. Modular join at both ends, same texture scale. Output clean top/face or requested isolated part; do not bake separate crystals, trees, shadow or gameplay objects into it.
~~~
### P09 FREESTANDING PROP / TREE / FURNITURE
~~~text
One isolated 2D pixel-art [PROP] of [BIOME / function] in the calibrated fixed view. Match the size reference [Luna/door/object comparison], ground footprint [W x D] and visual height [H]. Full silhouette, clean empty transparent background, natural material and restrained matte colors. Readable silhouette, no invented face, arms, legs, glow or spell unless the specified state requests it. No ground tile, cast shadow, surrounding plants, separate copies or other objects. Keep the point of contact at the intended anchor. This will be independently moved, cloned or reprogrammed: do not bake it into scenery.
~~~
Примеры: обычный холодильник, столик кафе, стул, фонарь, ракушка, настенный кристалл (опора крепления к стене, не стопы), потолочный кристалл (подвес), отдельное дерево, куст. Обычная и оживлённая формы используют исходное тело. Для простых пропсов движение прыжком, WALK — универсальные ноги отдельным слоем, не отдельный новый вид. Ноги согласовать с pivot/шириной опоры; не вклеивать глаза всем предметам. Индивидуальный хлебушек — исключение с собственным рисунком.
### P10 ARCHITECTURE / LARGE SCENE MODULE
~~~text
One complete reusable building / facade / island module [ROLE] in LUNA's approved fixed [VIEW]. Preserve supplied footprint, entrances, wall/roof lines, floor heights and scale reference. Authentic matte pixel art with rounded modern magitech architecture or the specified local style; clear grouped planes and readable windows. Do not generate other sides or a 3D model. [REQUESTED occluder / clean base / roof / wall module] only. No actors, independent doors, movable furniture, signs with text, detached props or baked cast shadows. Do not invent geometry or passages. Separate transparent silhouette where applicable; no full-screen landscape.
~~~
### P11 INTERIOR ROOMBOX / CLEAN BASE
~~~text
One complete clean isometric 2D roombox architecture image of [ROOM], designed for a static camera; no tile-based room shell, exactly matching the attached authored floor plan and perspective guide. Preserve every wall, floor, entry, window, walkable area and height. Fixed shared logical grid and scale relative to the approved character. Purposeful matte pixel clusters, warm/coherent local palette. Draw only static architectural shell and explicitly named fixed details. No characters, freestanding furniture, fridge, chairs, products, removable door, animated effects or baked shadows from those objects. Clean complete floor under all future movable props. No extra room, altered route, text, HUD or perspective change. 
~~~
### P12 FAR PANORAMA / FOREGROUND
~~~text
One independent [FAR BACKDROP / MID DISTANCE MASS / FOREGROUND OCCLUDER] for [BIOME]. Same coherent pixel-art language, deliberately simpler silhouette and contrast at distance, preserve the authored horizon and layering. [SEAM/OVERLAP GUIDE] for horizontal scrolling; no change to playable topology, no fake traversable doors or hidden rewards. No foreground actors or interactive items. Output the requested layer alone, with transparent alpha if appropriate. Edge colors and composition consistent with neighboring approved panels; seams will be tested in motion.
~~~
### P13 SCENE PREVIEW (НЕ production)
~~~text
A concept assembly preview using the supplied authored map and approved separate modules, same camera and calibrated world scale. Keep all walkable areas, elevations, entries, prop positions, secret geometry and intentional empty spaces. Show the scene's atmosphere and readable composition. Do not add furniture, creatures, puzzles, runes, paths or doors beyond the brief. No HUD unless explicitly supplied. This is a visualization of the assembly, not a replacement for individual production assets.
~~~
Собирать реальную карту в Godot/редакторе из готовых модулей. Не просить ImageGen нарисовать весь фон, затем вырезать из него тайлы/объекты. Концепт может направлять формы, но итоговый фон не источник коллизии.

## 7. Свет, эффекты, изнанка и секреты
Базовое окружение — нейтральный локальный свет и собственная палитра. День/ночь, зональная матовая цветокоррекция, тёплые окна, локальные свечения, тени и вода — через слои/маски/шейдеры/частицы; не генерировать заново весь мир для каждой фазы. Общий grading действует на мир и персонажей, HUD отдельно. Не разрушать логический пиксель слишком плавным шумом, сильным bloom и размазанной UV-дисторсией.
- Подвижная тень отдельно по опоре, высоте и источнику света, не в PNG. Локальная окклюзия материала может быть статической частью поверхности. Кристалл с отдельной маской emission; если оживлён — свет следует той же Entity.
- Призма: руны/скрытые надписи/музыкальные стрелки — отдельно. Не генерировать их как бессмысленные AI-буквы; точные глифы, строки, код и стрелки рисовать из согласованного программного шрифта/атласа. Тексты и ID из мануала/реального allowlist. Только 26 латинских глифов, стена всех пар A–Z; кириллица обычная, ночь/Призма. SPAWN CAT единожды в храме. Не рисовать текст генератором. Видимые/скрытые/ночные режимы, цвета по §07.4; не выдать тайну в обычный фон. Отдельные комнаты изучения обоих языков; раскладка по сценарию. META_WHITE_VOID только малозаметная запись в фоне самой Белой Пустоты после физического открытия, не на обычных стенах.
- Фонарь: восприятие реальных антимеметических Entity и звуков носителя Люмы; не перерисовывать сцену и не спавнить их из эффекта. Призма и Фонарь совместимы, но независимы.
- Изнанка: **простые 3D/low-poly proxy-каркасы** из реальной геометрии/позиции/высоты/масштаба, синий светящийся wireframe, редкие шейдерные акценты (звёзды/биты — кандидаты). Не генерировать шесть цветных текстур, отдельный комплект синих тайлов или копию всех ассетов. Прокси здания — несколько коробок, дерева — ствол и крона простыми объёмами, кристалла — гранёная форма; физический мир остаётся авторитетным, скрытые опоры реальны. Арт для обычного мира 2D. Перспектива первого лица не утверждена и не входит в работу. Не пересобирать движок в 3D.
- Забытый край: региональные визуальные глитчи/двоение/рябь/локальная неправильная геометрия, не глобальный хоррор. RE70/71 отменены; обычные случайные аномалии после overload, не маска на каждом экране. Пустота — отдельный special brief, белая с мягкой статикой; не добавлять HUD за рабочим столом. Пиксель растворяется под музыку после метафинала, отдельный эффект без награды.
### P14 VFX / MASK
~~~text
One isolated [VFX TYPE / emissive mask / particle sprite / frame phase] for LUNA, compatible with the approved logical pixel grid, restrained matte palette and readable silhouette. Transparent background; separate from character, item and environment. [Shape, color, duration phase, anchor]. Do not draw a hand, wand, floor, baked shadow, new rune, text or interface. For masks use the supplied asset silhouette/coordinates exactly; no independent shift. Alpha/glow only where explicitly needed; no broad blurry halo over the whole image. No animation trajectory baked into world geometry.
~~~
Для FX сначала ключевые силуэты/фазы, дальнейший цикл через код/атлас; точное timing, trigger, lifetime и blend по сценарию. Не делать каждому дереву персональную анимацию: общий ветер для статического декора, отдельная физика для живого дерева.

## 8. Интерфейс: совместная переработка с автором
Семь тем, подготовленные состояния рамок и кнопок, существующие портреты/иконки не выбрасывать. Сначала вместе с автором утвердить UI-композицию, масштаб, типографику, сетку, смысл всех состояний и конкретный стиль, затем заказывать элементы. Отдельный UI-шаг допустим, но все элементы одной панели согласованы, HUD не окрашивается зональным grading и не меняет масштаб с миром. Модель не выдумывает параметры, вкладки, новые артефакты или кнопки из картинки. 17 старых иконок не означают 17 действующих артефактов: Цифровой глаз исключён.
- Наборы: рамки (9-slice при подходящей геометрии), углы, кнопки normal/hover/focus/pressed/disabled, слот normal/selected/locked, полосы, курсор, иконки артефактов/заклинаний, портреты, инвентарь, редакторы палочки/Юки/Ори/Мии, хак HUD и необходимые метасостояния. Тексты, цифры, tooltip, полосы заполнения, интерактивные состояния — runtime, не печатать в текстуре. Реальные названия и доступы из мануала.
- Иконки в одном масштабе и с одинаковым оптическим весом, тест на целевом слоте; контраст фокуса клавиатуры/геймпада, узкое окно, длинный параметр, не вылезает за рамку. Точный размер и margins по UI-манифесту или авторской калибровке.
### P15 UI ELEMENT
~~~text
One isolated original LUNA pixel-art UI [ICON / FRAME CORNER / BUTTON / SLOT / PORTRAIT], based on the attached approved UI reference and chosen theme [THEME]. Match exact target logical canvas [W x H], border thickness, interior padding, optical size and approved palette. State [NORMAL / HOVER / FOCUS / PRESSED / DISABLED / SELECTED]. Change only the state-specific pixels; keep identical silhouette and registration. For a 9-slice frame, preserve corner geometry and straight repeatable edges; no text or symbol inside unless explicitly requested. Transparent RGBA, no mockup, screenshot, extra buttons or fake labels. Text, numeric values and input behavior will be implemented separately.
~~~
### P16 UI COMPOSITION CONCEPT
~~~text
UI-only design concept for the specified LUNA screen [SCREEN], using approved current HUD reference and the author's exact layout sketch. Preserve actual functions, labels and access states provided in the brief; do not invent menu entries, symbols, commands or artifacts. Original matte pixel aesthetic, consistent grid, hierarchy, spacing and readable at target window size. Mark output as a concept, not a production atlas or functional interface. No gameplay changes.
~~~

## 9. Манифест и автоматическая приёмка
Новые форматы — рабочий контракт для будущего экспорта, не миграция существующих JSON. Координаты в пикселях от верхнего левого угла, world units отдельно; pivot относится к ячейке, не всему атласу. Для тайлов добавить material/transition/neighbor_mask/edge_signature; для декора biome/allowed_surface/variant_seed; для Entity footprint, occluder, collision_profile, underside_proxy (простая геометрия) отдельно от изображения. Пример карточки с тестовыми размерами:
~~~json
{
  "asset_id": "prop_city_fridge_a",
  "status": "planned",
  "grid_version": "P0_PENDING",
  "view": "MAIN_WIDE_34",
  "source": null,
  "prepared": null,
  "reference_paths": [],
  "canvas_px": null,
  "pivot_px": null,
  "grip_px": null,
  "world_size": null,
  "palette_ref": null,
  "layer": "entity",
  "alpha_policy": "binary",
  "collision_profile": null,
  "occluder": null,
  "shadow": "separate",
  "emission_mask": null,
  "underside_proxy": null,
  "animations": [],
  "author_approval": null,
  "validation": []
}
~~~
Никаких подставных hashes/ID Location, пустое поле значит не решено. Для анимации frames: id, region[x,y,w,h], duration_ms, pivot, grip, front_mask, release/contact event. Фазы, размер и состояние берутся из реально существующих манифестов при расширении.
**QA структурный (скрипт):** файл открывается, формат RGBA, размеры, границы альфы и отсутствие обрезанного тела, бинарная альфа если требуется, одинаковые клетки, нет наложения, все регионы/опоры/хваты в пределах допустимого холста (внешний pivot только явно документирован), ссылки существуют, нет незаявленного ресайза, одинаковые anchor/edge contracts, проверка швов, стабильное имя и checksum при повторном экспорте. Отдельно sprite atlas с прозрачными отступами; не разрезать по предположению.
**QA визуальный (агент + автор на контрольных этапах):** 1) идентичность героя и анатомия во всех фазах, 2) пиксельный шаг и кластеры, 3) палитра, 4) правильный ракурс/опора, 5) чистая альфа, 6) плавность на contact sheet и loop, 7) отсутствие дрожания/подмены деталей, 8) хват/пальцы/предмет, 9) визуальные швы тайлов и читаемость, 10) отсутствие вшитых Entity/теней, 11) тихие зоны и соблюдение карты. Не использовать численный цветовой threshold как единственное доказательство стиля; анатомию и красоту автоматически гарантировать невозможно.
**QA Godot:** walk/run/jump, пересечение по высоте, окклюзия, клонирование/перемещение/удаление, shadow/emission следуют телу, фон под ним целый, LOCKED/FOLLOW, day/night, Prism/Lantern без утечек, wireframe aligns, швы при движении, UI на разных окнах. Скриншоты native и целочисленное увеличение, журнал статуса. Не заявлять тест успешным, пока его не запускали.
**Стоп-партия:** различие размера пикселя, новая внешность героя, лишние руки, неверный ракурс, нестыкуемые тайлы, изменённая карта, потеря опоры/хвата, фон с двойным предметом, бессмысленный текст, новый секрет или несанкционированный стиль. Исправить эталон/конкретный файл до тиражирования, не разносить ошибку на сотню спрайтов.

## 10. План партий и передача генератору
| Партия | Выход | Ворота |
|---|---|---|
| P0 | Калибровочный лист и одна сцена с существующими героями, 1 материал + пропсы | Автор утверждает визуальную сетку и масштаб |
| P1 | Недостающие позы Luna Classic/Chibi, затем шесть друзей, grip/слои | Проверка анатомии, манифеста, циклов и действующего банка |
| P2 | Основная фауна по §04 и главам; слаймы/лягушка/хлеб, далее по приоритету | Размеры рядом с героями, циклы, индивидуальные состояния |
| P3 | Совместное обсуждение редизайна HUD, затем элементы/иконки/FX | Авторский UI-эталон, реальные состояния, не картинка интерфейса |
| P4 | Небольшой набор трава/тропа/камень/вода/края; дерево/куст/камень, чистая основа | 3×3/8×8, переходы, швы, одно целое пространство |
| P5 | 4 контрольных сборки: старт/луг, Люма, остров/высота, изометрический интерьер | единый пиксель, читаемость, день/ночь, объекты отдельно |
| P6 | Расширение библиотек по биомам и сценарным брифам, уникальные ключевые сцены | каждая партия проходит QA, авторская карта, тихие зоны |
| P7 | Специальные слои, эффекты, изнанка, секреты, сюжетные сцены | соответствие реальной геометрии, актуальный сценарий, без утечки тайны |

P1–P3 могут продолжаться с существующими форматами до утверждения глобальной сетки, но новые финальные world-экспорты требуют P0; не ломать готовые банки. Конкретный список недостающих кадров вывести из реального файлового дерева/манифестов, не заказать заново весь список. Для P4–P6 не заказывать целые сотни ассетов до проверки малой библиотеки. Финальный состав по карте, а не фиксированная квота. Авторское обсуждение интерфейса отдельно, не начинать полный редизайн без него.

**Готовая стартовая команда для арт-агента:**
~~~text
Работаем над LUNA: Dev Mode. Открой AGENTS.md, docs/art/VISUAL_PRODUCTION_PLAYBOOK.md, assets/production/ART_ASSET_REGISTER.md, ART_PRODUCTION_MANUAL.md, текущие манифесты персонажей, авторские PNG и актуальный §08.26 единого мануала. Не меняй игровую архитектуру, сценарий, одобренные изображения и UI без прямой команды. Обычный мир 2D+Z: фиксированные нарисованные спрайты, модульные поверхности, ручная топология, отдельные объекты. Изнанка — отдельные простые пространственные каркасы. Сначала выпиши, что реально готово и чего не хватает, и подготовь P0-калибровку; не утверждай глобальный размер пикселя заранее. Для каждого следующего заказа используй P-MASTER + конкретный P-модуль + P-NEGATIVE, прикладывай реальный утверждённый референс нужного героя/материала и явно отмечай, что менять. Генерируй малые партии, экспортируй скриптом, проверяй анатомию, сетку, опору, прозрачность, палитру, анимации и швы. Сохраняй исходники, подготовленные PNG, манифесты, превью и честный статус в реестре. Не рисуй лишние руки, не перегенерируй неизменяемое, не вшивай живые объекты в фон, не выдавай концепт за готовый уровень. Если нужный исходник не виден, не подменяй его похожим. UI перерабатываем совместно с автором; не начинай новый UI сам. После контрольной партии предложи следующий конкретный заказ и сохрани результат в GitHub.
~~~
