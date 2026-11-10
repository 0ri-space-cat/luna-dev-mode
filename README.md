# LUNA: DEV MODE 🌙

**Актуальная творческая документация: 11.11.2026 — V6.** Состояние кода: исторический Godot 4 graybox 0.27; основные системы пиксельной игры, секреты и метафинал пока проектируются и **не заявлены реализованными**.

> Игра про Луну и Этернию, свободный взлом системных свойств, настоящие метасекреты и постепенное переосмысление знакомого мира. Игрок открывает секреты через знание и собственную изобретательность.

## 🌙 Авторский канон — начинать здесь

**[Библия V6 — только идеи автора и явно утверждённые предложения](docs/canon/20_V6_AUTHOR_ONLY_BIBLE.md)**

**[Копилка принятых сцен-набросков, механик и потерянных идей](docs/canon/21_V6_APPROVED_BRAINSTORM_SEEDS.md)** — встречи с Юки, Тоффи, Мией, Ори, Леей, секреты и отдельный список старых идей, ожидающих подтверждения.

**[Указатель, приоритеты и правила для моделей](docs/canon/00_START_HERE.md)**

Всё, что модели самостоятельно придумали из исходных идей (сценарная карта девяти районов, 26 конкретных эпизодов, прописанные диалоги, порядок и детальное наполнение секретных уровней), **перестало быть частью активного канона**. Прежние черновики V3–V5 и большие AI-сценарии сохранены только как история; последние находятся в [архиве V5](docs/archive/ai_generated_v5/). Точные локации, пазлы и реплики разрабатываются постепенно с автором, параллельно с прототипом.

Библия V6 сохраняет утверждённые механики: три вида мостов, раннюю стимпанковскую камеру FOLLOW/LOCKED, выход за радиус брошенной палочки ради изнанки, Озеро Дубликатов, палочку PLAYFUL→DEVELOPER, самовзлом Луны, физический HUD, девять карманных комнат инвентаря, телепорт движением маркера мини-карты, метамост внешнего наблюдателя, взлом GAME_FRAME, многослойную Пустоту и встречу с Они. Идеи рун/монокля и короткого эффекта Призмы пока записаны как **на рассмотрении**, без придуманной реализации.

## Готовые 2D-ассеты

[Каталог и статус](docs/art/ASSET_INDEX.md) · [21 артефакт](assets/artifacts/) · [семь интерфейсных тем](assets/ui/themes/) · [портреты и рюкзаки](assets/characters/) · [контактный лист](art/previews/artifacts.png). Для локальной галереи после скачивания репозитория откройте `art/previews/index.html`. Арт подготовлен, игровые способности и новый UI ещё не подключены.

## Историческая сюжетная и системная документация

Файлы [00](docs/archive/00_GAME_LEVELS_AND_ROUTES.md), [28](docs/archive/28_AUTHORITATIVE_GAME_BIBLE.md)–[42](docs/archive/42_V2_EDITORIAL_DECISIONS.md) содержат **множество ценных** сцен, рецептов, реплик, пазлов, предметов и программных контрактов. Они сохранены, но разделы про семь обязательных рутов, только постгейм-смену героев, отдельный финал Óни и отложенную встречу с игроком **устарели**. Использовать [карту миграции](docs/canon/06_MIGRATION_AND_PRODUCTION.md), не удалять детали без разбора.

## Исторические технические и дизайн-мануалы (01–27)
Их нельзя бездумно удалять: они содержат полезную архитектуру, факты реализации и ранний мозговой штурм. **Единственная художественная библия V6 имеет приоритет над историческими каталогами**, а реализационные утверждения 07–27 нужно сверять с кодом.

1. [vision and world](docs/01_VISION_AND_WORLD.md)
2. [entity and gameplay systems](docs/02_ENTITY_AND_GAMEPLAY_SYSTEMS.md)
3. [magic and spellcraft](docs/03_MAGIC_AND_SPELLCRAFT.md)
4. [meta secrets and discovery](docs/04_META_SECRETS_AND_DISCOVERY.md)
5. [technical architecture](docs/05_TECHNICAL_ARCHITECTURE.md)
6. [decisions and open questions](docs/06_DECISIONS_AND_OPEN_QUESTIONS.md)
7. [first prototype](docs/07_FIRST_PROTOTYPE.md)
8. [behavior system](docs/08_BEHAVIOR_SYSTEM.md)
9. [save and events](docs/09_SAVE_AND_EVENTS.md)
10. [social relationships](docs/10_SOCIAL_RELATIONSHIPS.md)
11. [discovery profile](docs/11_DISCOVERY_PROFILE.md)
12. [spell foundation](docs/12_SPELL_FOUNDATION.md)
13. [arcane grammar](docs/13_ARCANE_GRAMMAR.md)
14. [area effects](docs/14_AREA_EFFECTS.md)
15. [elemental reactions](docs/15_ELEMENTAL_REACTIONS.md)
16. [environment interactions](docs/16_ENVIRONMENT_INTERACTIONS.md)
17. [steam and danger](docs/17_STEAM_AND_DANGER.md)
18. [visual direction and localization](docs/18_VISUAL_DIRECTION_AND_LOCALIZATION.md)
19. [rule automation](docs/19_RULE_AUTOMATION.md)
20. [implementation matrix](docs/20_IMPLEMENTATION_MATRIX.md)
21. [entity traits](docs/21_ENTITY_TRAITS.md)
22. [entity lifecycle](docs/22_ENTITY_LIFECYCLE.md)
23. [world transactions](docs/23_WORLD_TRANSACTIONS.md)
24. [target selectors](docs/24_TARGET_SELECTORS.md)
25. [components interactions abilities](docs/25_COMPONENTS_INTERACTIONS_ABILITIES.md)
26. [inventory and save rollback](docs/26_INVENTORY_AND_SAVE_ROLLBACK.md)
27. [asset ready ui foundation](docs/27_ASSET_READY_UI_FOUNDATION.md)

## Технический статус и UX
Godot 4 + GDScript; действующий graybox 0.27 содержит много универсальных подсистем, описанных в 07–27: Entity, CommandProcessor, EffectEngine, события, компоненты, инвентари, отношения, магию, сохранения. Это технический фундамент, а не готовая игра с семью кампаниями. Запуск: [07](docs/07_FIRST_PROTOTYPE.md); реализация: [20](docs/20_IMPLEMENTATION_MATRIX.md).

**Актуальный дизайн 08.11:** полностью рисованное **2D** с многоярусными тайловыми картами, короткими циклами воды, живой средой, ригами героев и тёмно-фиолетовым контуром. **Весь UI на русском**, в том числе «Общее», «Способности», «Банк способностей», «Сохранить»; английские CAPS только у технических ключей `HEALTH`, `IS_ALIVE`, `WALK`, `TRUE/FALSE` с русскими подсказками. У Юки отдельная розовая тема UI и уникальные оверлеи восприятия, а базовая изнанка светло-голубая для всех.

**Принципы разработки:** общий Entity/Effect/Rule-дизайн; физика не меняется от наблюдателя; ничего нового не называть «реализовано», пока не проверены код и CI. После объединения **main — единственная постоянная актуальная ветка**; для технических экспериментов допустимы короткие PR с удалением временной ветки после слияния. Нет настоящего доступа к ОС через игровые мета-секреты.

## Технический статус и UX

Godot 4 + GDScript; действующий graybox 0.27 пока использует **Node3D/CharacterBody3D**, при этом подготовленные 2D SVG/PNG **ещё не подключены** к игровым сценам. Действующая архитектура — технический фундамент для 2D-миграции. Подробности в [плане реализации](docs/canon/11_2D_IMPLEMENTATION_PLAN.md), новые 2D-поля и Банк — проектные, а не уже работающие механики.

**Единая точка входа:** [docs/README.md](docs/README.md) → [docs/canon/00_START_HERE.md](docs/canon/00_START_HERE.md). Все утверждённые правки после объединения вести из **main**, прежние сценарные документы перемещены в [docs/archive](docs/archive/README.md). История старых веток сохранена в Git; не брать из них устаревшие сюжетные решения. Механики, которые описаны, но ещё не реализованы в Godot, требуют отдельной разработки и тестов.
