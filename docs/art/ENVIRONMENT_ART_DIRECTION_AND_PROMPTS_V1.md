# LUNA: Dev Mode — мастер-гайд и промпты для интерьеров и экстерьеров V1

> **Для будущих моделей и художников.** Производственная арт-дирекция на основе авторски подтверждённых решений. Это не автоматически утверждённая карта Этернии.  
> **Приоритет:** прямая новая правка автора → [библия V6](../canon/20_V6_AUTHOR_ONLY_BIBLE.md) → [итоговые визуальные решения](../canon/22_V6_FINAL_AUDIT_VISUALS_AND_HANDOFF.md) → этот гайд. Старые V2–V5 — исторические материалы; не брать оттуда придуманные уровни и стили по умолчанию.  
> **Изображения с разбором того, что брать и чего не брать:** [атлас референсов](ENVIRONMENT_REFERENCE_ATLAS_V1.md).  
> **Обязательный производственный раздел по разделению фона, взламываемых объектов и анимации:** [SCENE_ENVIRONMENT_LAYERING_AND_ANIMATION_V1.md](SCENE_ENVIRONMENT_LAYERING_AND_ANIMATION_V1.md). Читать **до генерации**: при расхождении прежних общих подсказок об отделении объектов руководствоваться более точным новым правилом. Здесь здания и дальняя масса леса обычно часть фона, а NPC, отдельные кусты, деревья, таблички, двери, механизмы, мерцающие вывески и любые объекты с поведением или взломом — отдельные ассеты/Entity.
> **Шаблон задания от автора на сцену:** [SCENE_BRIEF_TEMPLATE.md](SCENE_BRIEF_TEMPLATE.md).

## 1. Художественное ядро — что мы хотим получить

**LUNA: Dev Mode — оригинальный, отчётливо пиксельный, матовый и пастельный сказочно-магитехнический мир**. Красота композиции сочетается с читаемостью игровой сцены и физической свободой песочницы. На улицах Этернии есть современные и местами слегка футуристичные кафе, магазины, жильё, фонари на кристальной энергии, абстрактные линейные руны и живые скаты-транспорт. Рядом существуют широкие поляны, сады, леса, пещеры, озёра, маленькие скрытые миры и Пустота. Разные места обладают собственными цветами и настроениями, не следует заливать все сцены одним пурпурным цветом.

**Критерии по важности:**
1. Не изменить авторскую геометрию Google Sheets и расстановку/ракурс с эскиза PaintTool SAI.
2. Сохранить достаточную свободную игровую площадь, дорожки, проходы и реальные отношения размеров.
3. Сделать **один масштаб пикселя** для персонажей, NPC, пола, архитектуры и предметов; никаких сглаженных мультяшных героев поверх зернистого пиксельного фона.
4. Согласовать художественную палитру, свет, читаемость и ощущение уютной живой Этернии.
5. Только затем добавлять осмысленные детали. Украшения не должны перекрывать маршрут или превращать карту в непроходимую открытку.

**Важно:** прекрасный арт, который переставил стены, сузил площади, добавил несуществующие входы или невидимые препятствия, непригоден как игровая карта.

## 2. Два игровых способа компоновать окружение + специальные метасцены

### A — MAIN_WIDE_34: главный ракурс большинства играбельных локаций

**Авторский ориентир REF-01** — первая широкая сиреневая площадь с кафешкой, Луной и скатом. Это **золотая середина**: красивый вид на фасады и их высоту, достаточная плоскость пола перед ними, широкая прогулочная область, много пространства для NPC/живых вещей/взлома, перемещение Луны **по двум осям**.

- Ракурс **мягкий 3/4 сверху-сбоку**, визуально пониже ортогонального top-down, с фасадами, перспективой улиц, ступенями, навесами, цветущими деревьями и архитектурной глубиной.
- Видно, какая поверхность доступна для ходьбы, где обход, куда ведут двери; Луна не выглядит наклеенным постером в центре и соотносится с дверями/скамейками/NPC.
- Уровень может продолжаться за границей кадра; дальний план отличается от реальной игровой зоны. Крыши, небо и далёкие окна не становятся автоматически доступным этажом.
- Удерживать выразительную просторную игровую площадь, а не только узкую полоску под зданиями.
- **Не повторять экстремум Pokémon/MOTHER 3:** строго верхняя карта из дорожек/прямоугольников/крыш без объёма фасадов.
- **Не повторять экстремум платформера:** всё действие по одной горизонтальной линии, невозможность свободно гулять вверх/вниз.

**Где уместно:** главные городские площади, большие дворы, парки, лесные поляны, обширные помещения, вода/озёра, большинство зон для экспериментов с предметами.

### B — COMPACT_SEMISIDE: отдельные небольшие, более полубоковые композиции

**Ориентиры REF-02/REF-03**: большая фронтальная архитектура современного города, камерная улица и скат по центру, высота фасадов, атмосферные передние планы. Визуально напоминает платформер, но **не требовать внезапной смены контроллера**.

- Узкое или среднее по глубине игровое пространство может быть специально задумано автором; стены и фон архитектурнее, движение преимущественно вдоль улицы.
- **Двухосевое управление и уже существующие физические правила остаются основой**, если автор отдельно не решит делать полноценный платформер.
- Смена композиции не подразумевает третьего режима камеры: артефакт камеры по-прежнему имеет только FOLLOW / LOCKED.
- Подходят камерные вступительные участки региона, небольшие улицы, магазины, интерьеры, минизоны, скрытые переходы и некоторые постановочные эпизоды.
- Не превращать каждую большую территорию в боковой коридор и не строить отдельный полностью платформенный движок без решения автора.

### C — META_SPECIAL: Пустота, изнанка и необычные игровые представления

Допускается нестандартная фронтальность, парящие обломки, технические окна и необычные пустые пространства. **Геометрию, возможные переходы, количество головоломок задаёт автор**, нельзя автоматически превращать Пустоту в десятки комнат-испытаний. Сам факт метауровня не отменяет общий пиксельный язык. Указанные в истории двухосевые движения и физические законы сохраняются, пока автор не задаст иное.

**Ключевое различие:** смена **композиции арта** и реальная **смена физики перемещения в Godot** — разные задачи. Пиксель-арт из нескольких подходов не должен сам собой ломать управление.

## 3. Пиксель: точность, плотность и масштаб

**Обязательное ощущение:** настоящий handcrafted pixel art с читаемыми ступеньками, намеренными компактными цветовыми кластерами, ограниченной гармоничной палитрой, ясно выделяемыми массами света и тени. Всё должно выглядеть созданным в одном арт-производстве.

**Не допускать:**
- smooth digital painting reduced to 720p, псевдо-пиксель из микрозерна, «обычная рисованная картинка просто низкого разрешения»;
- размытия, airbrush по всему кадру, фотореалистичного материала, сложных мельчайших кистевых штрихов;
- у Луны пиксели 3–4 раза мельче, чем у окружения, или наоборот;
- растровой живописной Луны на пиксельном полу; агрессивного размытого bloom;
- сверхкрупной Луны ради демонстрации персонажа, если это **скриншот игровой локации**;
- неконтролируемых текстовых AI-артефактов на вывесках и нечитаемых рунах.

**Реальное разрешение пока НЕ утверждено.** Предложенные контрольные тесты, а не обязательные спецификации:
- **640×360 internal @ integer 2x → 1280×720**: больше мелких деталей, риск слишком тонкого пикселя.
- **320×180 internal @ integer 4x → 1280×720**: отчётливее крупный пиксель, риск потерять мимику, руны и архитектуру.
- Если оба края не подходят, выбрать промежуточную внутреннюю сетку и **целочисленное масштабирование или продуманную рамку/кроп** только после сравнения реальных спрайтов в Godot. Не заявлять, что именно эти два режима уже внедрены.
- Размер нарисованной Луны и угол обзора выбирать тестом в настоящем движении, по уже подготовленным анимациям, а не по одному удачному крупному концепту.

**CLASSIC / CHIBI:** обе версии Луны автор хочет оставить. CLASSIC — подросток с более длинными ногами; CHIBI — **тоже подросток**, но с большим отношением головы к телу, короткими ногами и большой худи. Не рисовать CHIBI младенцем, CLASSIC взрослой длинноногой моделью; не выдумывать промежуточную третью версию. При использовании Луны запрашивать **конкретный утверждённый спрайт**, сохранять розовые волосы, круглые очки, звёздную фиолетовую шляпу, фиолетовую худи с котом, шорты, обувь и палочку с полумесяцем.

## 4. Матовая палитра и зональная цветокоррекция

**Автор утвердил:** общая матовая цветокоррекция **игрового слоя**, включая саму Луну, NPC и объекты, с отдельными параметрами биома: **saturation / contrast / tint / brightness** и плавными переходами между зонами. **HUD и редактор** лучше рисовать поверх уже обработанного мира, чтобы они оставались читаемыми. Контраст интерфейса не копировать на каждую стену.

**Примерные настроения (без утверждённых RGB-кодов):**
- Магитех-город: пыльная сирень, лавандовые фасады, мягкий розовый цвет цветущих деревьев, кремово-янтарные окна, нежные голубые кристаллы.
- Природа: естественная матовая зелень, тёплое солнце, локальные сиреневые/розовые детали. Не перекрашивать каждый лес в пурпур.
- Пещера/подземелье: цвет породы и конкретные источники света; не делать одинаковый кристальный зал во всех пещерах.
- Верхняя Пустота: романтические тёмно-сиреневые глубины и плавающие фрагменты Этернии.
- Средняя Пустота: тающая материальность, **голубые контуры** и геометрические пробои, невесомость.
- Белая Пустота: **главный цвет — почти белый**, локально серебристый шум, бледный сиреневый глитч и серые окна разработчиков.

**Техническое правило на будущее:** цветокоррекция не должна превращать прозрачные прямоугольники героев в видимые, размывать пиксели или уничтожать границы спрайтов. Постобработка CanvasItem / SubViewport — **вариант для будущего прототипа Godot**, а не уже реализованный шейдер. Исходные ассеты всё равно рисуются в едином пиксельном языке, фильтр не исправит разную стилистику.

## 5. Архитектура и детали Этернии

### Городской экстерьер

В Этернии есть **настоящий современный город**, а не замковое средневековье. Читаемые жилые дома, магазины, кафе, рестораны, киоски, террасы, остановки и пассажиры; фасады могут быть прямыми или плавно закруглёнными, с магитехническими элементами, кристаллическим освещением и слегка космическим дизайном. Рядом могут быть деревья в городских кадках и розовые цветущие кроны; не заполнять ими каждую площадь автоматически.

- **Скат-аэробус**: живое, доброе, понятно устроенное существо с естественной мордочкой и анатомией ската; на спине **прозрачный купол и под ним подушки**. Не заменять его космическим кораблём, кибердраконом или механическим мобом. Не плодить дополнительные глаза. Сохранять размер и место только по плану.
- **Линейные геометрические руны** на отдельных фасадах: загадочные, тонкие, составленные из черточек и фигур, не случайные строки псевдоалфавита в каждом углу. Они связаны с предложенной автором системой чтения/монокля, тексты ещё не утверждены.
- Технологичность без тяжёлого киберпанка и бесконечной голографической рекламы.
- **Никаких** замков, средневековых знамен, канатных подвесных мостов, одинаковых башен и парящих островов **по умолчанию в городе**. Эти мотивы могут появиться только по отдельной задумке, например в Пустоте.
- Название города всё ещё **не выбрано окончательно**: Люма, Люмен, Люмин. Не вставлять на вывеску любое из них как канон без просьбы.

### Природа и внешние игровые зоны

Лес, поляна, водопад, озеро, берег, поляна со слаймами, цветочная чаща, обычные и кристальные пещеры, секретные микромиры: сохранять **свой характер каждому биому**, большую читаемую игровую зону и предметы, с которыми можно взаимодействовать. Природные части могут быть красивыми и необычными, но не надо лепить в каждый кадр сразу порталы, водопады, сотни кристаллов, три каменных арки, летающие замки и магическую башню.

Системные объекты (живые деревья, холодильники, животные, физические мосты, редактируемые двери, невидимые камни) должны существовать **как отдельные сущности** в производственной сцене, даже если для предварительного концепта они показаны вместе с фоном.

### Интерьеры: обязательная стилистика

**В этой подборке пользователь ещё НЕ утвердил конкретный художественный интерьер**, поэтому новый интерьер создаётся на основе **его будущего SAI-эскиза, текста и таблицы геометрии**, а не автоматически по чужим V5-комнатам.

- Современное, уютное, обжитое помещение, стилистически связанное с улицей: естественные человеческие дверные проёмы, диваны/столы/стулья/полки в масштабе Луны, естественный свет окна и локальное кристаллическое освещение.
- Допускаются мягкие фасадные/комнатные перспективы чуть ближе к фронтальному виду; важны **видимость пола и доступные маршруты**, не только красивая задняя стена.
- Не превращать автоматически любую комнату в школу магии, волшебную библиотеку, средневековый трактир, алхимическую лабораторию или дворец.
- Кафе, квартира, мастерская, общественный интерьер, магитех-помещение, домик фей или румбокс — только **если выбран такой тип комнаты**.
- Микродомики фей могут быть проходными при маленьком SCALE Луны: **размеры/наполнение автор сам придумает**.
- Передние стены и мебель, которые визуально заслоняют Луну, должны отделяться в foreground; физические стены и двери сверяются с авторской картой.

### Пустота, Они и изнанка

- **Верхняя глубина Пустоты:** воздушная, романтичная, фрагменты знакомых мест в темно-сиреневом просторе.
- **Средняя:** знакомая материальная Этерния разрушается и показывает голубые контурные формы. Не рисовать лишь голую техническую сетку.
- **Белая:** преимущественно белая, ТВ-рябь, небольшие глитчи, парящие обломки, **серые Windows-подобные окна с осмысленными программистскими интерфейсами**, огромная искра-глаз в верхней центральной части кадра. **Они** на отдельном обломке: голубая худи с китом (не плащ), синие мягкие волосы без электрических игл, шорты, босиком, безэмоциональное выражение, глаза **почти полностью белые** с тонкими серыми бегущими линиями. Нельзя переносить внешность Жемчуг из Steven Universe.
- **Голубая изнанка** проявляется **когда Луна бросает палочку и выходит за радиус проекции**. Не переворачивать правило и не изображать как обычный отдельный биом по умолчанию.
- **Невидимые мосты/камни/двери** должны сохранять свой закон: если мост невидим — рисовать косвенные признаки, а не видимую декоративную дорожку. Застенчивый мост становится плотным без взгляда Луны; особая дверь, наоборот, становится неплотной без её взгляда; метамост реагирует на взгляд **игрока через камеру**. Конкретную загадку и геометрию не придумывать.

## 6. Геометрия от автора: таблица Google Sheets + набросок SAI

Автор рассматривает следующую производственную схему:

**Google Sheets:** буквальная геометрия (условные клетки пола, стен, препятствий, переходов, уровней, скрытых проходов) и связь между сценами; стрелки/ссылки между листами.  
**PaintTool SAI:** быстрый неидеальный рисунок внешнего вида, ракурс, расположение фасадов, подписи «где какой объект».  
**Генератор:** выдержанная в одном стиле пиксельная визуализация **по существующей карте**, а не создание новой карты.  
**Godot:** программные сцены, коллизии, навигация, переходы, Y-sort/закрывающие объекты и независимые взламываемые сущности.

**Правила сохранения блокинга:**
1. Положение и количество входов/выходов **точно из схемы**.
2. Не перемещать пропасти/мосты/двери, не закрывать путь декорацией.
3. Сохранять свободную ширину дорожек и масштаб важных объектов.
4. Различать пол, доступный игроку, и декоративные поверхности далёкого фона.
5. Подписи SAI не превращать автоматически в финальные надписи на картинке.
6. Если SAI и Sheets конфликтуют — **обозначить конфликт**, а не решать за автора.
7. Если геометрии ещё нет — генерация является **STYLE_CONCEPT**, а не готовым геймдев-ассетом.
8. Не наследовать из старой машинной картографии фиксированные девять районов, названия новых комнат, изобретённые квесты, адреса и состав NPC.

**Рекомендуемое разделение продакшен-сцены (названия условные):**
- background_far: дальняя архитектура/атмосфера/небо;
- ground_walkable: пол, дорожки, вода/берег по таблице;
- back_structures: задние стены, задние перила;
- foreground_occlusion: кроны, навесы, передние стены и любые перекрытия Луны;
- interactive_props: все отдельные взламываемые объекты, двери, NPC, животные, скаты;
- effects: свет, руны, вода, дождь, подсказки невидимости, глитчи;
- collision_navigation: источником правды выступает сетка и Godot, **не сама финальная картинка**;
- hud_ui: отдельная от зональной цветокоррекции система.

AI-генератор одного изображения **не гарантирует** готовые честные слои: при необходимости ассеты разрезаются/перерисовываются и проверяются в Godot. Рисунок с персонажем и HUD разрешён как демонстрационный concept screen, но для рабочего фона сцены Луну и HUD **не запекать в пиксели**.

## 7. Универсальный промпт для image generation — ENGLISH MASTER

**Скопировать целиком и вставить один модуль из следующей главы и конкретный brief автора.** Square-bracket placeholders must be filled from the provided level plan; do not guess.

~~~text
Create an original high-quality HANDCRAFTED PIXEL ART environment for the author's game LUNA: Dev Mode, set in Eternia, a contemporary and gently futuristic magical everyday world.

PRIMARY VISUAL IDENTITY:
Authentic deliberate pixel art, consistent visible square-pixel density and intentional pixel clusters across characters, creatures, floor, buildings and objects. Clearly stepped outlines, grouped foliage, grouped shadow shapes, readable silhouettes, careful hand-placed pixel detailing. Neither overly coarse blocky 8-bit art nor micro-detailed digital painting made artificially low-resolution. Gentle matte pastel lighting and a harmonious local palette, understated contrast and softly muted saturation, restrained luminous accents from windows, magical crystals and authored runes. A coherent adventure-game visual system; crisp nearest-neighbor pixel edges, no soft focus.

CAMERA:
Follow the SCENE MODE exactly. Default is WIDE PLAYABLE SOFT THREE-QUARTER, not strict top-down Pokemon mapping, not isometric diamond grids and not a fixed 2D sidescroller. Show inviting building facades, real sense of urban height and depth, but also a wide clearly readable ground plane for the character to roam in both horizontal and vertical directions. In compact staged locations a more front-facing semi-side composition is allowed, only if the author requests it. This is still one consistent 2D world.

AUTHOR'S LAYOUT IS FINAL:
Faithfully follow the supplied Google Sheets geometric grid and PaintTool SAI rough blocking sketch. Preserve every authored doorway, wall, exit, chasm, path, width, level boundary, collision obstacle and focal point. The authored sketch determines object placement, not the image generator's preference for symmetry or spectacle. Do not invent extra locations, paths, platforms or characters. Keep sufficient empty room for a sandbox game with moving creatures and hackable objects.

WORLD DIRECTION:
Modern or gently futuristic yet magical Eternia: lived-in facades, real cafes, houses, shops, warm windows, crystal-powered urban infrastructure, a few geometric line-rune inscriptions, charming living environments and playful mysterious details. No generic medieval castle-city. A manta-ray passenger bus, if explicitly requested, MUST be a readable living manta with a transparent passenger dome on its back, with comfortable cushions beneath the dome, and a natural friendly face. Natural locations have their own biome identity and do not all look like neon-purple ruins.

CHARACTER SCALE:
When the concept requests Luna, reproduce her supplied AUTHOR APPROVED CLASSIC or CHIBI sprite identity exactly; no newly invented hybrid character. CLASSIC is a pink-haired teen with glasses, purple starry witch hat, purple cat-emblem hoodie, shorts, striped socks, sneakers and crescent wand. CHIBI is a short-legged adolescent version, never a baby. Keep Luna in proportion to doors, NPCs and the nearby manta bus, and retain generous gameplay space. For PRODUCTION BACKGROUNDS omit Luna, NPCs, inventory, hack UI and moving hackable objects from the painted background.

COLOR:
Use a muted soft zone-specific color harmony: lavender/smoky lilac + warm amber windows for a city scene, mellow greens for nature, or the specified Void palette. Avoid uniform intense neon-purple coloring, acid cyan, excessive bloom and strong black shadows. Luna and the environment share coherent lighting. The runtime may use a world-wide matte grading filter while HUD remains separate; do not make the art blurry.

OUTPUT CONTRACT:
One art-consistent readable scene matching the author's exact composition and geometry. Crisp uniform pixels, useful playable ground, authored interactive places visible but not cluttered. Distinct depth layers feasible to cut out for future Godot production. No watermarks, gibberish lore labels, pretend HUD overlays (unless specifically requested), random quest items, new named NPCs or mandatory puzzles.

SCENE MODULE:
[PASTE EXACT MODULE BELOW]

AUTHOR SCENE BRIEF:
[PASTE AUTHOR'S BRIEF / GRID / SAI NOTES / REFERENCE IDs]
~~~

## 8. Готовые модули к мастер-промпту

### A. Широкий игровой городской экстерьер

~~~text
WIDE THREE-QUARTER MODERN MAGITECH CITY. A beautifully readable town square, urban street or courtyard with a broad traversable foreground and middle-ground floor, multiple clear paths and believable human-scale architecture. Softly rounded modern apartment and shop facades, small practical details, warm cafe/shop windows, crystal lamps, sparse geometric runic signs and some flowering foliage only where marked. Real distance and depth without a strict bird's-eye rooftop view. Ambient city life is calm and playful. Manta transport with transparent dome and cushions ONLY if required by the author's sketch. Composition and pixel size inspired by approved REF-01. Do not shrink the usable play area for a giant decorative facade.
~~~

### B. Компактная полубоковая улица / остановка

~~~text
COMPACT FRONT-FACING SEMI-SIDE SCENE. A small intimate staged urban location with strong contemporary facades, height, window life, storefronts, readable street edge, believable transit stop, perhaps a living manta bus if specifically authored. More side-on and theatrical than the default wide three-quarter camera, while preserving a physically traversable strip with some depth and the authored entrances. Best for introductions, micro-areas and small special scenes. Use the spatial mood of REF-03 but do not copy its entire futuristic rail system or place massive transit objects in every level. Same character pixel density and matte pastel style as other scenes, not a distinct platformer asset pack.
~~~

### C. Поляна / лес / сад / водопад / озеро / пещера

~~~text
WIDE PLAYABLE NATURAL ENVIRONMENT. Original hand-pixelled Eternia landscape in the specified biome: [EXACT BIOME]. Large clear walkable spaces and collision-aware terrain geometry according to the author's grid. Deliberately grouped foliage, stone, water, earth, paths and local magic. Soft matte daylight or authored night mood, atmosphere without excessive bloom. Natural readable elevation, distant depth, discrete interactive entities rather than scenery fully packed with arbitrary animals, ruins, portals and crystals. Preserve clear room for spell experiments, physical object manipulation and secret observations.
~~~

### D. Интерьер квартиры / кафе / магазина / мастерской

~~~text
PLAYABLE CONTEMPORARY MAGITECH INTERIOR. Use exactly the author's PaintTool SAI room sketch and Google Sheets geometry. A lived-in practical interior in the same pixel-art world as the street outside: warm home or shop lighting, comfortable modern furniture, appropriately sized windows and doors, occasional crystal-lit appliances and subtle geometric line runes if authored. Include visible accessible floor and clear paths around obstacles. A cozy semi-front-facing or wide three-quarter room composition as dictated by the level brief. No automatic medieval tavern, wizard classroom or alchemy laboratory. Keep foreground walls, big props and hackable objects feasible as separate layers in Godot. Do not invent what is stored in the room.
~~~

### E. Миниатюрный интерьер / румбокс / домик фей

~~~text
HIDDEN MICRO-INTERIOR / ROOMBOX. The scene should feel like a tiny crafted world genuinely enterable by Luna after changing her SCALE. The author defines every doorway, object, route and secret. Render the relative scale of furniture and objects carefully, with cozy layered matte-pastel lighting, readable usable floor and real depth. Do not assign any mandatory fairy NPC, new magic item, trap or prewritten puzzle unless specified. Match the broader pixel language of Eternia.
~~~

### F. Верхняя Пустота

~~~text
UPPER VOID. A romantic surreal night-blue / lavender expanse outside the game frame, containing only the floating fragments of familiar Eternia defined in the author's geometry. Fragments can contain bits of paths, foliage, buildings or bridges as specified. Dreamy beauty with a feeling of discovery, clear navigable surfaces, not a gray QA test room or obligatory puzzle corridor. Cinematic depth but authentic crisp pixel art and authored routes.
~~~

### G. Средняя Пустота

~~~text
MIDDLE VOID. Familiar authored fragments of Eternia gradually unravel into cyan wireframe geometry, missing pixel segments, cracked tiles, erased structures and a few floating luminous outlines. The space is haunting, graceful and readable. The bright contours are local and precise, not overwhelming acid neon. Use approved REF-05 as a visual anchor. No random newly scripted puzzles or unapproved door connections.
~~~

### H. Белая Пустота с Они

~~~text
FINAL WHITE VOID. Predominantly pale WHITE pixel-art space with fine TV static, gray interference, low-saturation lilac glitch breaks and a restrained number of floating pixel fragments. Scattered vintage gray Windows-like fictional developer windows with legible-style code, diagnostics and UI hierarchy. A luminous star-shaped EYE at the upper center if requested. If the author wants Oni in-frame, she sits expressionlessly on a separate small floating platform: soft naturally curly blue hair, blue whale hoodie (not a cape), shorts, barefoot, eyes almost completely WHITE with thin horizontal drifting gray scan lines; no normal pupils, no other character's facial structure or forehead jewel. ALL elements including characters, windows and platforms follow the same unmistakably pixel-art density. Much more white negative space than purple fog. Do not create a generic error wallpaper or determine the origin of the eye.
~~~

### I. Мосты и вещи с наблюдением

~~~text
OBSERVATION SECRET, SPECIFIC PHYSICAL STATE. An invisible bridge should be unpainted except for authored indirect clues such as rainfall, footsteps or tiny environmental reactions. A normal invisible obstacle can remain solid. A shy bridge becomes SOLID when Luna closes her eyes; a special inverse door becomes INTANGIBLE when she closes her eyes; the unique meta bridge requires removal of the PLAYER'S CAMERA gaze. Never collapse these into one generic invisibility effect. Produce exactly the before/after state asked by the author, without inventing a new solution or making all secret geometry constantly visible.
~~~

## 9. Негативный промпт и запреты для будущих моделей

~~~text
NO high-resolution painterly digital art masquerading as pixel art; NO over-detailed microscopic pixels or noisy post-downscale; NO airbrush blur, plastic 3D rendering, vector-smooth hero in pixel scenery, excessive dithering or giant glow gradients. NO inconsistent pixel unit sizes or palettes between Luna, NPCs and scenery. NO baby/toddler chibi, no elongated adult Luna, no third unapproved character design. NO Pokemon/MOTHER-3 pure overhead town-grid in wide three-quarter scenes; NO thin side-scroller-only movement strip in big sandbox scenes; NO automatic diamond isometric map. NO arbitrary medieval castles, pennants, floating islands and bridges in normal modern city streets. NO visually malformed manta-ray shuttle, random new eyes or giant ship engines. NO invented doors, routes, props, quests, NPCs, runic translation text or story beats. NO authored layout changes, blocked paths or inaccessible interactive objects. NO HUD, Luna or live entities baked into production background layers. NO same purple tint across every biome; NO oversaturated neon or washed-out unreadable colors. NO accidental false portrayal of observation mechanics. NO false claims that concept art is an already implemented Godot scene.
~~~

## 10. Критерии приёмки и фактические выходные файлы

**Типы запросов к художнику/генератору:**
- **STYLE_CONCEPT**: пробная цельная картинка для выбора тона/ракурса, допускается персонаж и HUD, если попросили. Не объявлять игровым фоном.
- **LAYOUT_CONCEPT**: точная композиция по Sheets/SAI; уже есть фиксированные двери/стены/площадь; проверять визуальную согласованность с коллизиями.
- **PRODUCTION_BACKGROUND**: фон без Луны, врагов, транспортных существ и UI. Отдельно при необходимости создаются логические компоненты.
- **SPRITE/PROP**: отдельные объекты/двери/транспорт/деревья в том же пиксельном языке; прозрачный фон/анимация лишь по ТЗ.
- **META_CONCEPT**: игровая аномалия, физический HUD или Пустота, с чёткой ссылкой на действующую логику V6.

**Проверить перед утверждением:**
1. Геометрия строго сохранена? Не придуманы новые пути?
2. Правильный A/B/C-ракурс и ширина доступного игрового пола?
3. Размер пикселя един у Луны, NPC, фасадов, травы, теней?
4. Луна в своём подтверждённом облике и реальном масштабе?
5. Матово-пастельная палитра сохраняет читаемость, свет и разнообразие биомов?
6. Современная городская архитектура не стала фэнтезийным замком?
7. Скат живой, с прозрачным куполом, подушками, мордочкой — если указан?
8. Текстовые руны не превращены в машинный gibberish на каждом предмете?
9. Все коллизии/закрывающие слои/взламываемые сущности отделимы в Godot?
10. HUD не запечён в игровой фон и остаётся вне зонального матового фильтра?
11. В метасцене соблюдены особенности Пустоты и законы наблюдения?
12. Произведён проверочный масштабный рендер с настоящим спрайтом Луны и one-room Godot тестом? Если нет — **concept only**.

**Статус:** конкретный угол, viewport, зум, физика платформерных вставок, точная карта, размеры ячеек Google Sheets, набор ассетов и способ разрезания изображения на слои по-прежнему открыты. Этот документ даёт максимально подробную художественную постановку, а не утверждает новые уровни за автора.
