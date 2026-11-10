# Luna — первый отдельный pixel-art ассет

Статус: ImageGen мастер готов; проверка масштаба в Godot ещё не завершена. Не считать готовым персонажем или анимацией.

## Файлы

- Устаревший мастер v1: `art/generated/luna/luna_front_idle_source.png` (1024×1536 RGBA); он был слишком живописным для 64×96 и не используется.
- Сохранённый мастер v2: `art/generated/luna/luna_front_idle_source_v2.png`; 64×96 импорт — `assets/2d/characters/luna/luna_front_idle_64x96.png`. Пользователь одобрил стиль, но затем запросил больше исходного разрешения.
- Мастер v3 на сетке 128×192: `art/generated/luna/luna_front_idle_source_v3_128_grid.png`.
- Предыдущий вариант с маленьким серпом: `art/generated/luna/luna_front_idle_source_v4_crescent.png`.
- Одобренный пользователем вариант с крупной серповидной луной и звездой внутри: мастер `art/generated/luna/luna_front_idle_source_v5_large_crescent.png`, игровой PNG `assets/2d/characters/luna/luna_front_idle_128x192.png`.
- Референсы: `art/references/luna-prototype-2026-11-09/`.

## Воспроизведение ImageGen-запроса

```text
Use case: stylized-concept. Asset type: single production game character sprite for a 2D pixel-art Godot prototype. Create ONE standalone full-body idle front-view sprite of LUNA, a small chibi witch girl, based on the approved LUNA character in reference image 4; references 1-3 show the desired colorful whimsical game world but are mood/style references only. She has voluminous lilac-pink hair, large expressive eyes behind round glasses, oversized deep violet witch hat with a small star, purple outfit and tiny wand held at her side. Polished modern large-pixel art with carefully grouped clean pixels, soft detail, charming cartoon expression, crisp dark-violet outline and controlled lavender, pink, plum and teal highlight palette. Entire hat and boots visible, centered upright relaxed pose, transparent background, intended to fit a 64x96 source frame. Exactly one character and one pose; no sprite sheet, variants, props, environment, ground shadow, text or watermark. Preserve recognizability and outfit cues from reference 4. Avoid vector edges, blurry pixels, tiny noisy pixel texture, extra limbs, detached body parts, cropped hat or cropped feet.
```

## Техническая обработка

Исходный альфа-канал сохранён в мастере. Мастер v5 имеет размер 1024×1536 — ровно 128×192 ячеек по 8×8. Игровой PNG извлечён nearest по целочисленной сетке; кадр не обрезается и не растягивается. В preview используется scale 1 и `CanvasItem.TEXTURE_FILTER_NEAREST`, поэтому экранный размер совпадает с предыдущей 64×96 текстурой при scale 2.

## Чек-лист Godot

- [x] Подтвердить визуальное направление изображения в чате: пользователь одобрил второй, пиксельно-ориентированный вариант.
- [x] Проверить RGBA-альфу и grid extraction 8×8.
- [x] Пользователь одобрил крупный сиреневый серп со звездой внутри, без эффектов вокруг.
- [x] Сохранить одобренный мастер и извлечь 128×192 без ресайза.
- [ ] Проверить его в работающем Godot-окне; UI-захват macOS пока недоступен.
- [ ] Сверить размер с существами и камерой в той же сцене.
- [ ] Только после проверки зафиксировать импорт и перейти к следующему рисунку.
