# LUNA · очередь ассетов и промпты

[Размеры, референсы, палитры и компоновка](README.md). Перед запуском модели прикладывай именно те изображения, которые указаны для задания. Четыре концепта уже сохранены рядом с пакетом. Текст внутри них служит примером оформления. Для соответствия персонажу приложи его PNG из репозитория и, у Луны, актуальный игровой кадр нужного облика.

## С чего начать

| Партия | Состав | Что посмотреть перед следующей |
|---|---|---|
| **A. Первый экран Луны** | Рамка портрета, портрет Chibi, рюкзак, 3 ресурса, часы, карта, 9+5 слотов, палочка, ACTIVE_TOOL, вертикальный взлом, выделение слота и существа. | Один комплект, собранный поверх реального кадра поляны. Проверить читаемость на свету и ночью, размеры и свободное пространство вокруг Луны. |
| **B. Остальные окна** | Широкая консоль Юки, компактный режим «Мир», квесты, кнопки и контролы, дополнительные значки, подсказки, адрес локации, попап восстановления. | Та же кромка работает у разных размеров. Длинные подписи, список параметров и превью нормально помещаются. |
| **C. Семь профилей** | Classic и Chibi у Луны, шесть остальных аватарок, семь рюкзаков, семь оформлений общей кромки. | Переключение на одной сцене. У всех рюкзаков совпадают координаты слотов, у всех портретов видны характерные детали. |
| **D. 17 артефактов** | Иконки 32×32, маленькие 24×24 там, где нужна ручная правка. По одному предмету за генерацию. Затем физические спрайты для тех, что нужны в сценах. | Иконки различимы в одной полосе без названий. Палочка выпущена в A и идёт отдельным инструментом. |
| **E. Эффекты и физический HUD** | Псевдообъёмное выделение, захват цели, HACK_SPELL, появление окна, управляемый сбой и восстановление, грань панелей, переносимый маркер карты. | Короткая запись эффектов на реальной сцене. Силуэт цели, содержимое окна и кнопка восстановления остаются читаемыми. |

Задание на первый запуск после переключения модели:

> Открой README.md и PROMPTS.md. Начни с партии A. Сначала сделай пробу художественного языка из четырёх элементов: рамка слота, левый верхний угол окна взлома, иконка палочки и передний угол выделения существа. Возьми концепты № 2 и № 4 для кромки и компоновки, кадр из Godot для масштаба пикселя и отдельный референс полумесяца для палочки. Сверь пробу в исходном размере и при ×2 на кадре поляны. После выбора кромки выпусти компоненты партии A отдельными PNG и собери из них контрольную композицию. Сохрани оригиналы и рабочие версии раздельно. Для каждого итогового файла запиши размер, назначение, состояние и привязку. Если ImageGen отдаёт крупный исходник, доведи спрайт до целевой пиксельной сетки и поправь его вручную там, где пропал силуэт.

## Общий префикс для ImageGen

Добавляй перед конкретным заданием. Для каждого запуска также указывай нужный референс, целевой размер из README и один основной результат.

```text
Create a single production source for the game LUNA: DEV MODE. Match the crisp, hand-placed pixel clusters of the attached in-game Luna sprite. The world is matte pastel fantasy magitech. UI surfaces are quiet dark plum with a narrow lilac-to-magenta stepped rim, a small cool specular accent and a deep purple outer keyline. Preserve solid readable silhouettes and a consistent square pixel unit. Draw deliberate 1–2 pixel outline steps at the target resolution. Use sharp, discrete color ramps and sparse spark pixels. Give important interface outlines one thin stepped lilac-white neon line and a restrained narrow violet halo, matching hack-border-reference.png. Use a single contour. Keep the underlying pixel contours crisp. Prepare glow separately where practical so its intensity can be controlled in Godot. Real transparent alpha outside the requested piece. Leave enough clear padding to extract the silhouette. The composition reference establishes shape and hierarchy only. Deliver the isolated component with no baked text, values, keyboard labels, background, scene, mockup, checkerboard, blurred pixel contours, smooth vector curves, painterly shading or 3D render.
```

Для повторяемых рамок, масок, шкал, таблиц и рамок состояний сначала выбери внешний вид по художественной пробе. Финальные размеры, однотонные пиксельные рёбра, нарезку и раскладку собирай точно по сетке. Пробный лист можно разрезать для работы, исходник и готовые RGBA сохраняются отдельно. Варианты тем делай из утверждённой базовой кромки и тематических углов. У одной анимации общий холст и одинаковый pivot во всех кадрах.

## A. Первый экран Луны

### A1. Рамка портрета и полосы

Референс № 2 и выбранный угол из первой пробы.

```text
Design the isolated frame and resource ornaments for Luna's top-left HUD. Make a 56x56 stepped circular portrait rim with an empty opening for a separate 48x48 face, a dark outer keyline and two short lilac highlights. Pair it with three separate 16x16 resource pictograms: pink heart, cyan faceted mana crystal, amber lightning bolt. Design an end-cap pair and a straight repeatable edge for a 104x8 gauge. Give each fill a darker lower pixel row and a bright upper row. Keep silhouette differences strong on bright grass and a dark night scene. Separate opening mask, empty gauge and colored fill; leave all space above the gauge open for live labels and values.
```

Один раунд — рамка и пиктограммы как художественная проба. После выбора собрать отдельные треки и края, затем проверить 0%, 1%, 50%, 100%. Состояние низкого ресурса — короткая подсветка контура и видимый остаток. Подписи и цифры рисует Godot.

### A2. Рюкзак и хотбар

Референс № 1 и `assets/characters/luna/ui/backpack.png`. Аватар Луны взять из C1.

```text
Redraw the reference Luna backpack as an isolated front-facing pixel-art UI housing, on a 144x156 native grid. Preserve its purple witch-school silhouette, handle, top cat patch, small gold buckles and crescent side pocket. Keep a quiet, dark 84x84 insert beginning at native (30,54), where the game will add three by three square item slots. Keep all straps, buckles and pocket art clear of that insert. Draw a matching short, low, stepped rail for five independent quick slots to sit immediately to its right. Keep the bag silhouette readable on bright terrain.
```

```text
Draw a single 26x26 square pixel slot with clipped corners, a 24x24 clear item area, a dark rim and a quiet dark face. Provide registered separate overlays for hover corners, bright active frame, focused frame, drag destination, disabled lock and invalid cross-hatched corners. Reserve the center for an item and the lower-right corner for a live stack count. Add a separate small stepped keycap backing above a quick slot. No digits or baked item art.
```

Состояния «пусто» и «занято» используют один корпус. Выбранный слот читается по непрерывной рамке, hover по углам, недоступный — по замку. Оверлей перезарядки рисуется по данным с отдельным контуром, счётчиком или маской. Проверить перетаскивание между ячейками и читаемость цифровых назначений.

### A3. Часы и карта

Референс № 2 по компоновке. Для пробной подложки — кадр реальной поляны.

```text
Design an 80x80 native pixel minimap ring with a precisely centered empty opening and an inset dark keyline, plus a small companion clock plate. Use short lavender corner highlights and keep the sides quiet. Draw four separate compact time pictograms on 16x16 grids: dawn sun emerging from a horizon, round day sun, dusk half-sun descending below a horizon, night crescent. Provide separate zoom plus and minus pictograms, and a north notch on the frame. Leave the entire map aperture transparent and the clock plate empty beside the time icon.
```

```text
Draw five matching minimap icons on individual 16x16 grids: Luna is a lilac crescent with a pink star like her wand, any discovered passage is a doorway, any discovered bridge is a small bridge, a quest objective is a yellow star, and a marked point is a classic map pin with round top and pointed bottom. Distinct silhouettes, shared dark outline, transparent background.
```

Метки ставятся на карту только при наличии игровых данных. Для расширенной партии — выделение границы видимости, три размера подсказок и отдельные варианты месяца со звездой «лежит / в руках / перенос разрешён».

### A4. Палочка и ACTIVE_TOOL

Референс полумесяца и игровой Classic из README. Одна иконка палочки с розовой звездой для обоих обликов Луны. Референс № 4 только для места и размера блока.

```text
Pixel-redraw Luna's exact reference wand as an isolated 32x32 inventory icon. Preserve the broad lilac crescent opening to the right, the small star visibly suspended inside its negative space, and a short subtly tapered handle running down-left. Keep clear air between the star and both crescent horns. Use the reference pink star for the single shared UI design. Keep the crescent, star and handle legible at 24x24. No enclosing orb, independent projectile, hands or smoke.
```

```text
Draw a compact Luna active-tool holder for the bottom-right HUD, around 104x40 native pixels. Place a 32x32 illuminated item cradle to the left and a wide quiet field to the right for the live tool name and status. The dark plum base has a narrow stepped neon-lilac edge and a short cyan inset. Reserve a bottom strip for a cooldown mask. A separate hover chevron and a separate unavailable overlay sit clear of the item. Draw the holder empty and isolated.
```

### A5. Вертикальный взлом

Референсы № 2 и № 4. Слот из A2 задаёт толщину обводки.

```text
Design a tall blank pixel-art inspector shell for LUNA, target native 195x240. Draw a dark plum inset with a three-step bevel at each corner, sharp lilac-white inner keyline and a restrained magenta outer rim. Keep long edges repeatable and reserve an 8-pixel 9-slice border. Make only a small bright accent at the upper-left corner and a smaller echo at bottom-right. The central area is quiet and even behind long rows. Prepare separate horizontal header and footer dividers, a small square live-preview surround, a tab backing and a thin outer glow overlay. The panel must remain recognizable when the list grows or the window is anchored above a world object.
```

Первые компоненты для проверки — иконка общих параметров, сердце, глаз, скорость, поведение, копировать, удалить, сохранить, закрыть. Строки и контролы из B2. На контрольном экране оставить место под имя существа, ID и живую миниатюру.

### A6. Плоское наведение

Референсы № 1 и № 4. Под тест приложить один реальный спрайт маленького и один крупного существа.

```text
Draw a transparent cyan corner bracket kit for selecting pixel-art creatures on a game field. Make one crisp 16x16 stepped L corner with a two-pixel light core, a dark one-pixel outline and a one-pixel soft cyan step outside the corner. Derive matching corner directions without changing line thickness. Normal target: sparse four corners. Selected target: stronger interior highlight and a tiny diamond lock indicator separate from the corners. Blocked target: warm amber broken brackets with an obvious gap. Keep the middle fully open for the creature.
```

## B. Окна, контролы и пиктограммы

### B1. Широкая, компактная и малая панели

Референс № 3 для пропорций, A5 для родства форм.

```text
Extend the accepted Luna inspector skin into three empty scalable window shells. First a wide 310x146 console shell with a narrow tab rail and a quiet code or card workspace. Second a compact 126x88 quest window with a short header and stackable rows. Third a low 100x52 popup with an open message area and reserved bottom action space. For the console's World mode, make a low 280x52 strip with anchor points for object selection, group filter, and a link status control. Use identical edge thickness and square pixel unit across all shells. Keep them restrained and clearly part of the same game. Each corner, edge, header accent and fill can be reused independently. Leave room for scrolling, Cyrillic and live values.
```

В чистовых файлах — общая основа и три раскладки. Для Юки дополнительно нужны жетоны событий, условий и действий, соединители, узлы, маркер направления, подсветка цели на уровне, полоса ошибок и подложка автодополнения. Для квестов — состояние строки, галочка, сворачивание. Для HUD — короткий фон адреса, отдельная контекстная плашка клавиш, подсказки, предупреждение и подтверждение.

### B2. Ряды параметров, кнопки, вкладки и шкалы

```text
Design a compact pixel-art control kit matching the attached Luna inspector rim. Use separate straight tiles and small end-caps. Include a single-row parameter backing, icon tab, button, numeric field, toggle with a movable square thumb, dropdown arrow, slider track and draggable diamond thumb, scroll track and thumb, and a compact removable target-tag chip with a separate plus and close glyph. Make distinct idle, hover, focus, pressed, active, read-only, disabled, invalid and confirmed treatments where relevant. Error gets a broken warm rim and an icon position. Success gets a small solid check position. Include a horizontal color-control frame with an independent pointer and a swatch holder. Color ramp, labels, text and live values will be supplied in Godot.
```

### B3. Иконки вкладок и действий

Применить промпт к каждой группе из списка. Сверять значения с реестром параметров и доступными действиями игры.

```text
Draw a coherent family of single-color 12x12 or 16x16 pixel UI glyphs for LUNA, one isolated glyph per cell, each with consistent optical weight and generous open spaces. Use the listed subjects for this batch. A gesture or object should remain legible at native size and in a single color. Give the active state a small bright accent as a separate tintable layer. Keep the outer transparent padding clean.
```

- **Вкладки.** Семь значков: ползунки «Общее», палитра «Облик», куб «Физика», мозг «Разум», маршрут «Поведение», два сердца «Отношения», крыло со звездой «Способности». Банк способностей доступен внутри соответствующей вкладки.
- **Параметры.** Сердце, глаз, след движения, маршрут, шаги, размер, цвет, замок, управление, автономность.
- **Действия.** Копия, корзина, дискета, крест, стрелки undo/redo, подтвердить, раскрыть, плюс, минус, забрать, передать, вернуть мгновение.
- **Юки.** Событие, условие, действие, иначе, ожидание, объект, группа, связь, сломанная связь, состояние запуска. Текст карточек добавляется в Godot.

## C. Портреты, рюкзаки, темы

Выполнять по одному герою. К каждому запуску прикладывать оригинальные `portrait.png` или `backpack.png` этого героя. Цвета и индивидуальные мотивы — в [таблице тем](README.md#темы-героев).

### C1. Портрет

```text
Redraw the exact attached character as a 48x48 square pixel-art HUD portrait, head and upper shoulders, looking near the camera. Preserve their recognizable species, face proportions, age, expression, eyes, ears or hat, hair silhouette, costume and colors. Use the attached Luna game sprite only as the standard of pixel density and edge treatment. Match the centerline and eye-height of the accepted Luna portrait while leaving room for tall ears or hat. Keep the jaw, outer hair and ears visible in the separate circular crop. Draw the face on real transparent alpha, without a frame or a different costume. For Luna Classic and Chibi, use the corresponding current in-game frame for face proportions, hat silhouette and palette.
```

### C2. Рюкзак

```text
Pixel-redraw the attached character's exact backpack as a 144x156 front-facing UI housing. Preserve the shape and unique ornaments from the provided backpack PNG. Match the accepted Luna backpack's pixel density, baseline and registered 84x84 insert starting at (30,54). Keep the insert flat and quiet so nine square slots can be laid on it. Place handles and all defining ornaments outside the insert. Match the character's individual colors from the reference. Draw an isolated housing on transparent alpha with no items, text, straps crossing the slots or decorative layout lines.
```

### C3. Общий интерфейс в теме героя

```text
Reskin the accepted Luna UI shell using the supplied character profile's primary, secondary, tertiary and panel colors. Preserve exact control sizes, keyline width, corner registration, text areas and sprite cut boundaries. Redraw only the small border ornaments and profile-specific corners using the motif given for this character. Keep the portrait rim, minimap, hotbar, active tool holder and inspector visibly related. Produce separate theme parts so an identical screen can swap profiles in game. Preserve independent semantic states for health, warning, success and invalid actions.
```

## D. Палочка и 17 артефактов

Палочка описана в A4. Следующие строки — **17 отдельных заданий**. К каждой добавь общий префикс и этот общий блок. Каноничны состав и назначение. Силуэты ниже — художественные предложения для первой пробы. [Авторский перечень](https://github.com/0ri-space-cat/luna-dev-mode/blob/main/docs/canon/25_V6_FINAL_AUTHOR_ARTIFACT_ROSTER.md).

```text
Make one isolated 32x32 inventory icon for the specified Eternia artifact, with 2 pixels of clean outer padding, one clear main silhouette and one distinct color accent. Draw a simple three-quarter view with top-left lighting, dark plum or material-colored pixel outline, and flat matte clusters. The object alone should read on both a purple active-tool holder and a dark inventory slot. Recheck its silhouette as a hand-tuned 24x24 variant. Keep emission and any moving parts separate. No pedestal, hand, eyes or cute face unless required by this object's description. Keep the game mechanic's visual cue legible without any letters or numbers.
```

| Артефакт | Индивидуальный промпт |
|---|---|
| **1. Кнопка времени** | Draw a squat dark-plum retro controller with one large coral push button under a half-open safety guard. Put a single left-curving rewind notch around the base, readable at 24×24. The round physical push surface dominates. Make idle, pressed and cooling overlays by moving or dimming the button while keeping the case fixed. |
| **2. Игровая камера** | Draw a compact periwinkle retro field camera in a near-frontal three-quarter view. Keep a projecting cyan glass lens with a deep indigo bevel and two concentrated reflections, a small coral shutter and a warm-white flash. Use adjacent periwinkle planes to show the case thickness. Make separate reticle and anchor glyphs for FOLLOW and LOCKED. |
| **3. Монокль** | Draw one thin warm brass lens ring with cool lavender glass and a short chain. One translucent abstract rune stroke refracts inside the lens. Make the round optical silhouette airy and clearly smaller and simpler than the box camera. |
| **4. Компас** | Keep the round near-frontal case and diagonal needle. Use icy cyan steel on the rim, saturated marine blue on the dial, and orange-red and icy white on the needle. A color reference guides only the palette. Keep needle and dial separate for animation. Add a separate plus-and-tag widget elsewhere in UI for selecting affected categories. |
| **5. Гравипушка** | Draw a short handheld cobalt and lilac grabber with two blunt open prongs around one cyan suspension core. Broad open claw silhouette and a compact grip. Provide a separate arc of pixel field energy between the prongs for capture or hold. |
| **6. Портал ган** | Draw a handheld projector in three-quarter side view with a rounded ivory ceramic rear shell, dark graphite core, bright blue oval aperture and three thin dark tips around the emitter. Add a lilac shadow to the ceramic. The silhouette tapers into the front and carries no vertical grip. Keep the casing distinct from the blue open-claw gravity tool. [Portal 2 visual reference](https://store.steampowered.com/app/620/Portal_2/). |
| **7. Песочные часы** | Draw an unmistakable hourglass silhouette with golden yellow caps and sunny sand. Keep frame and sand separate. The sand stream has three readings at the same overall pose, slow intermittent grains, steady line, and fast dense trail. |
| **8. Консоль Юки** | Draw a compact angled strawberry-pink keyboard with a translucent aqua holographic screen, a broad icy reflection and a thin berry edge. Group the cream keys in clear pixel shapes with one long space bar. Create hardware-only and screen-active layers. The wide software panel is handled by B1. |
| **9. Дверь в комнату Луны** | Draw an upright plum-painted door with a warm brass handle, one clearly visible pale pink crescent and a stepped doorframe. It reads as a physical door and an addressable passage. Prepare a second open silhouette for the world prop if needed. The inventory icon is a miniature representation. |
| **10. Зелье Мии** | Draw one spherical cobalt and periwinkle flask with a clean convex round silhouette, tiny tilted neck, terracotta cork and a strong icy glass highlight. Keep the liquid as a separate fill mask so its tint and pattern can change. The bottle silhouette stays fixed. |
| **11. Фонарь Тоффи** | Draw a small coral lantern with an arched handle, amber glass and one large pale-gold flame. A darker rose side plane gives the cap and base depth. Isolate flame and aura for the active state. |
| **12. Сердце Леи** | Draw a rose-pink crystal with a distinct two-lobed heart outline, three or four large beveled facets, a concentrated pale pink reflection, a berry shadow and one small mint reflection. Isolate a subtle colored aura as an optional active layer so the emotion color can change at runtime. |
| **13. Каталог Ори** | Draw a small blue-white bound field catalogue with cream indexed page edges and a cyan orbit clasp. One inset silhouette tab suggests browsing appearances. Rectangular closed book shape, with a separately drawn open book if needed for use. |
| **14. Свиток** | Draw one partly unrolled pale parchment on two short violet rollers. Show three small ordered magical marks along the exposed strip to suggest casting a sequence. Clear curled ends and warm page color distinguish it from Ori's book. |
| **15. Призма** | Draw a clear triangular crystal with hard lavender and cyan facets and a thin warm highlight. Keep a clear triangular silhouette when unlit. Draw a separate tiny angular parallax glint for activation. |
| **16. Цифровой глаз** | Draw a cyan amulet shaped like an almond eye with a faceted deep blue iris and a tiny mount. It should read as a digital eye or system optic at 24×24. Isolate an activation flicker. |
| **17. Пиксельный глобус** | Draw a small floating blue globe with clear green pixel continents and shaded ocean. Keep the sphere standalone, without stand, holder or decorative rings. |

Порядок для проверки силуэтов — камера и монокль рядом, гравипушка и портал ган рядом, Кнопка времени и часы рядом, Каталог и Свиток рядом. Цифровой глаз проверить на тёмном фоне и белой Пустоте. В художественных названиях файлов использовать рабочие имена. Внутренние Entity ID брать из проекта при подключении, где они уже определены.

Для спрайта предмета в мире повторить силуэт принятой иконки, взять ракурс из игрового кадра Этернии. Рисовать крупнее с нужной точкой опоры и направлением рукояти. Дверь, экран консоли и крупные эффекты получают размер по сцене. Движение песка, поворот стрелки, включение экрана и изменение цвета жидкости делать отдельными слоями.

## E. Псевдообъём, глитч и физический HUD

### E1. Псевдообъёмное поле выделения

```text
Create a modular pseudo-3D selection cage for a 2D pixel-art creature in a three-quarter game view. Use two offset open rectangular planes, a bright stepped cyan near set of corners and dim lavender far corners offset up-right by a few native pixels. Connect only the necessary corners with short diagonal strokes. Use a very faint transparent facet on one side and keep the creature's face and center open. Separate near lines, far lines, short depth connectors, optional transparent face and anchor mark. Native corner tiles are 16x16, repeatable edge 8x4. Provide an active capture accent and a broken amber denied accent using the same silhouette. No ground decal or perspective cage baked around a particular creature.
```

В Godot собирать объём по границам цели. Задняя плоскость тоньше, передняя ярче. Проверить в наведении на маленького слайма, крупное дерево и HUD-элемент. Из того же набора собрать выделение двух целей в режиме Юки «Мир», с отдельной линией связи и разными маркерами источника и приёмника.

### E2. Сканирование и снаряд HACK_SPELL

Два самостоятельных эффекта, чтобы наведение, попадание и открытие редактора читались по движению.

```text
Draw a short registered 6-cel pixel lock-on effect around an empty center, 64x64 native per cel. Keep the same pivot. Cels 1–2: four small cyan brackets appear and tighten. Cels 3–4: one thin segmented scan line crosses the empty target. Cel 5: one violet glint at each near corner. Cel 6: settle to the accepted steady target brackets. Keep the geometry clean and accents small. No text, filled center, creature or background.
```

```text
Draw separate transparent 2D pixel effects for Luna's HACK_SPELL. A 32x32 loop has a tiny bright lilac orb, two or three cyan detached square fragments, and short misaligned rows. Keep the same centered pivot across four flight cels. Draw a separate five-cel impact on a 64x64 grid: orb compresses, cyan squares expand toward the lock brackets, magenta fragments catch briefly on the rim, then fade to the stable selected state. Preserve the actor silhouette in the middle. Design a separate short trail piece for placement by Godot.
```

### E3. Появление окна, сбой и восстановление

```text
Design matching transparent pixel glitch elements for the approved Luna panel. Provide isolated clusters of 1–3 stepped lilac and cyan blocks, narrow horizontal tear strips with hard edges, corner fragments copied from the panel profile, and a quiet dissolve mask. Draw a 6-step opening strip: corners form, edge joins, brief scan accent, stable state. Draw a short corruption accent that can be confined to the perimeter and a reverse settle sequence that restores the original silhouette. Keep all animation pieces separable from the panel fill, text and controls. Avoid full-screen flashing and large fields of noise.
```

Предложение для первого теста — появление в районе 180–240 мс, одиночный сбой кромки около 300–500 мс, восстановление с коротким обратным оседанием пикселей. Проба со сниженной интенсивностью оставляет рамку и читаемое состояние без крупных вспышек. У аварийного восстановления отдельный понятный знак «Вернуть мгновение» и стабильная кнопка. Эффект Кнопки времени можно отличить обратным движением частиц, а темпы песочных часов — частотой зерна. Фоновую рассыпь Пустоты и эффект выхода из заморозки выпускать отдельно от UI.

### E4. Панель как поверхность и элементы для метасцен

```text
Create optional modular pixel-art depth pieces for the existing Luna interface shells when they become walkable in the game. Match the same lilac edge and dark plum material. Draw a clean top lip, a short near side, left and right caps, and a matching underside made from repeatable horizontal segments. Create one tiny matching pedestal lip for an inventory-room item and one larger freestanding version of the map's exact lilac crescent and pink star player marker with a distinct base or shadow as a separate layer. Preserve the screen UI face as its own sprite. Follow the actual world camera angle in the provided screenshot.
```

Подготовить слои «плоскость / ближняя грань / торец / тень» и отдельный короткий соединитель окна с целью. Для выхода из заморозки — кадры нарастающего дрожания кромки, устойчивый контур открытого окна и метка привязки к объекту. Для живой загрузки — разборная экранная рамка, кромка перехода, место под настоящий спрайт бегущей Луны. Коллизии, выход за рамку, перенос маркера, состояние симуляции и восстановление реализуются в игре.

## Что сохранить после партии

- Отдельные исходники и очищенные RGBA PNG. Имена описывают элемент, тему и состояние. Например, `luna_slot_selected_26.png` и `minimap_marker_player_16.png`.
- Короткий список файлов с размерами, полями девятисрезовой рамки, центром привязки, порядком кадров и фактическим местом проверки.
- Контрольный скриншот или короткое видео сборки. Для игрового атласа — сетка, отступы и точная нарезка. Для предпросмотра — отдельная картинка.
- В конце сверить каждый пункт очереди с фактическими файлами. Перед интеграцией сравнить со схемой ввода, реестром ресурсов и актуальным игровым размером пикселя.

## A. Проба художественного языка · 13 ноября 2026

Создана одна обзорная генерация четырёх деталей, она сохранена как исходная проба в [assets/ui-pixel-v1/probes/party-a-style-probe.png](../../assets/ui-pixel-v1/probes/party-a-style-probe.png).
Проверка рамки слота при ×2 на игровом кадре: [party-a-on-luna-2x.png](../../assets/ui-pixel-v1/probes/party-a-on-luna-2x.png). Это ручная пробная раскладка, кадр служит только подложкой для оценки пикселя.

- Слот, уголок панели и палочка держат общий светлый сиреневый контур и тёмную сливовую обводку. Звезда палочки розовая, иконка подходит обоим обликам Луны.
- Бирюзовый угол выделения отделяется от фиолетовой рамки окон.
- Генерация показала крупную рамку вместе с портретом и не удержала отдельный передний угол поля. Силуэт окна требует отдельной пробы без портрета. До сетки размеров и проверки на игровом кадре это художественный эскиз, а не готовый игровой набор.

Точная запись промпта этой пробы:

```text
Create one pixel-art visual language contact sheet for the game LUNA: DEV MODE. Use the attached in-game Chibi Luna frame to match its visible coarse stepped pixel scale, outlines, compact pixel clusters, soft matte pink and violet character palette. The UI is designed to harmonize with a matte pastel fantasy magitech game. Quiet dark plum surfaces, sharp stepped lavender-magenta trim, cool cyan glints and sparse pink spark pixels. Create EXACTLY FOUR isolated UI asset studies arranged in a clean 2 by 2 grid on true transparent alpha, with generous separation, no cell lines, no labels and no background. TOP LEFT: one compact square inventory slot frame, approximately 32 by 32 design pixels, clipped stepped corners, empty transparent center. TOP RIGHT: only the upper-left corner sample of a tall dark-plum inspector window, showing an 8-pixel-scale stepped beveled rim and small live-preview inset. BOTTOM LEFT: Luna's crescent wand icon, broad lilac crescent open to the right, short handle slanting down-left, one small pink star suspended clearly inside the crescent's negative space. Preserve the exact reference silhouette and pink star. BOTTOM RIGHT: one luminous cyan front-facing L-shaped creature selection corner, stepped with a crisp light core and dark plum outline. Keep all pieces orthogonal pixel art, crisp and readable, no blur, bloom, smooth vector curves, painterly finish, text, interface mockup, full window, extra icons, item art in slot, or grid lines. Pixel art, transparent background, four isolated samples.
```

Следующая итерация — попросить отдельно изолированный угол панели и именно передний угол выделения, затем привязать лучший вариант к целевой сетке и проверить на игровом кадре.

## Партия A · первый комплект проб · 13 ноября 2026

Это отдельные генерации из партии A. Все файлы сохраняются как исходные листы; перед импортом в игру их нужно привести к сетке, нарезать и проверить альфа-края.

| Исходник | Назначение | Результат и следующий шаг |
|---|---|---|
| [luna-portrait-source.png](../../assets/ui-pixel-v1/party-a/luna-portrait-source.png) | Chibi портрет | Узнаваемое лицо, розовые волосы, очки и шляпа читаются. Исходник получился крупным. Нужны ручная пикселизация на 48×48, центрирование и проверка круглой маски. |
| [luna-backpack-source.png](../../assets/ui-pixel-v1/party-a/luna-backpack-source.png) | Корпус рюкзака | Удержал фиолетовый корпус, ручку, кота, пряжки, звезду и месяц. Поле 3×3 осталось свободным. Высокая плотность бликов требует чистки при уменьшении до 144×156. |
| [resource-icons-source.png](../../assets/ui-pixel-v1/party-a/resource-icons-source.png) | Здоровье, мана, выносливость | Три пиктограммы разного силуэта на прозрачном листе. Уменьшить и убедиться, что кристалл и молния читаются в 16×16. |
| [time-icons-source.png](../../assets/ui-pixel-v1/party-a/time-icons-source.png) | Время суток | Генератор нарисовал горизонт, день и ночь, но не дал ясные четыре отдельных состояния. Перед сборкой иконок повторить сумерки и упрощённый месяц отдельно. |

В первой пробе были слот, кромка окна и палочка. Для следующих решений использовать только общую палочку с розовой звездой. Chibi-кадр показывает золотой спецвариант непосредственно в руке персонажа.

## Обновление окна и компонентов

По пожеланию автора высота окна взлома уменьшена. Новый предварительный ориентир 195×240 логических пикселей при масштабе ×2, с прокруткой списка внутри. Точные размеры проверяются на реальном экране. Исходники рамки мини-карты, блока активного инструмента, уголка выделения и компактного окна находятся в [папке партии A](../../assets/ui-pixel-v1/party-a/). Высокая пробная версия убрана из рабочей папки после выбора более компактного окна. Все исходники требуют доведения до игровой сетки и проверки в Godot.

## Неоновое направление · уточнение автора

Интерфейс — стилизованный пиксель-арт с заметным сиренево-фиолетовым неоновым свечением, как на исходных концептах. Яркое световое ядро следует ступенчатому пиксельному контуру; вокруг него может быть мягкий ореол. Текст и значения должны оставаться читаемыми. По возможности готовить свечение отдельным слоем для регулировки в Godot. [Проба окна с одним контуром](../../assets/ui-pixel-v1/party-a/hack-window-single-neon-source.png) — художественный исходник, свечение нуждается в доработке перед использованием.

## Уточнение свечения и контура

Автор выбрал один тонкий ступенчатый пиксельный контур и узкое сиреневое свечение по [образцу](../../references/ui-pixel-v1/hack-border-reference.png). [Новая проба окна](../../assets/ui-pixel-v1/party-a/hack-window-single-neon-source.png) задаёт это направление. Внешний ореол на пробе ещё требует очистки, генератор оставил отдельные розовые точки по краям. Для игры рамку и свечение нужно подготовить отдельными слоями.

## Партия A · обод и иконки

По просьбе автора обод мини-карты стал толще и остался округлым. Созданы исходники: minimap-thick-neon-source.png, wand-pink-star-source.png, slot-states-source.png, minimap-markers-source.png. Они лежат в ../../assets/ui-pixel-v1/party-a/. Для игрового использования требуется привести их к заданным размерам, очистить ореолы и разделить состояния/значки. На исходнике палочки виден светлый фон, его нужно убрать с сохранением розовой звезды; маркер игрока необходимо проверить по силуэту отдельно от флажка задания.

## Утверждение маркеров и окно взлома

13.11.2026 автор утвердил [пять маркеров мини-карты](../../assets/ui-pixel-v1/party-a/minimap-markers-v2-source.png). Сохранять их дизайн при подготовке игровых размеров и переносимого маркера Луны.

Созданы исходные листы [значков вкладок](../../assets/ui-pixel-v1/party-a/inspector-seven-tabs-source.png), [иконок действий](../../assets/ui-pixel-v1/party-a/inspector-actions-source.png) и [контролов](../../assets/ui-pixel-v1/party-a/inspector-controls-source.png). Последний вариант заменяет пробу со слишком широким общим свечением. Это крупные художественные исходники: нужно разделить элементы, подготовить прозрачные края и игровые размеры, собрать состояния кнопок, отдельно задать заполнение слайдера и проверить читаемость в Godot.

## Семь вкладок и иконки способностей · 14 ноября 2026

[Семь значков вкладок](../../assets/ui-pixel-v1/party-a/inspector-seven-tabs-source.png) соответствуют утверждённым разделам: общее, облик, физика, разум, поведение, отношения и способности. [Проба иконок способностей](../../assets/ui-pixel-v1/party-a/ability-icons-first-source.png) показывает ходьбу, полёт, плавание и огненное дыхание как примеры для дальнейшего обсуждения. Оба листа — исходники для нарезки, приведения к игровой пиксельной сетке и проверки при 1× и 2× в Godot.

Удалены из рабочей папки заменённые пробы: старые маркеры с каплями, высокий и чрезмерно яркий вариант окна, тонкий и ранний обод мини-карты, ранние контролы и прежний лист вкладок. Файлы перемещены в системную корзину. Утверждённые маркеры и остальные исходники сохранены.

## Иконки 14 выбранных способностей

Исходники и разрезанные изображения лежат в `assets/ui-pixel-v1/abilities/`. Для обзора создан `preview.png`. Дополнительные иконки изображают свечение, лазание по стене, заморозку, электричество, яд, регенерацию, пение, дублирование, стойкость и гравилуч. Предыдущие четыре — ходьба, полёт, плавание и огненное дыхание.

PNG вырезаны из крупных исходников с сохранением прозрачности и служат художественной основой. Размеры ячеек пока различаются; перед подключением нужно очистить края, довести иконки вручную до единой сетки и проверить читаемость в игре. Набор способностей зафиксирован в главе 27 на GitHub.

## Следующая партия HUD

Созданы исходники рамки портрета, панели часов, панели квестов и углов выделения в папке `assets/ui-pixel-v1/party-a/`. Отдельно создан концепт псевдообъёмного выделения `target-depth-concept.png`. Контур рамки портрета крупно ступенчатый, для финальной версии следует сверить его с более округлым ободом карты. На концепте объёмного выделения свечение слишком широкое и форма запечена целиком: нужны независимые углы и рёбра с регулируемым свечением. Все элементы требуют подготовки к игровой сетке и проверки на реальной сцене.
