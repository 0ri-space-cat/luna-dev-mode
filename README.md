# LUNA: DEV MODE 🌙

**Актуальная единая творческая документация: 07.11.2026.** Исторический технический прототип: Godot 4 graybox 0.27. Полноценные миры, семь персонажей и мета-финал пока описаны как дизайн и **не заявлены реализованными**.

> Яркая RPG-песочница об одной цифровой реальности. Луна изучает магию, свойства объектов, скрытые правила, интерфейс и наконец обнаруживает игрока. Знание позволяет пользоваться реальными секретами без обязательной сюжетной прокачки.

## 🌙 Единый канон — начинать здесь

**[Открыть весь новый актуальный мануал: docs/canon](docs/canon/00_START_HERE.md)**

1. [Библия игры — одна кампания Луны](docs/canon/01_GAME_BIBLE.md)
2. [Персонажи, редактор Ори, зелья Мии и побочные сюжеты](docs/canon/02_CHARACTERS_AND_SIDE_STORIES.md)
3. [WORLD 00–03, VOID, адреса, карманные пространства, Óни](docs/canon/03_WORLD_ADDRESS_AND_VOID.md)
4. [Взлом палочки, себя, HUD, редактора, рамки, POV, 2D, REWIND](docs/canon/04_HACKING_MANUAL.md)
5. [Одна кампания, все прежние квесты Y/O/M/E/T/N, финал через стекло](docs/canon/05_CAMPAIGN_AND_SCENES.md)
6. [Карта миграции старых сцен, технические проверки и открытые вопросы](docs/canon/06_MIGRATION_AND_PRODUCTION.md)

**Новые решения:** семь отдельных кампаний заменены **одной историей Луны**; открытые герои — самостоятельные NPC и переключаемые персонажи со своими побочными линиями. Óни проявляется в архивных обломках Пустоты после открытия остальных шести и совмещает виды зрения плюс следы прошлого/вероятного будущего. WORLD 00 отделён от лаборатории. Финал — взлом оконной границы, взгляд Луны на игрока и короткая секция от первого лица; после финала появляется 2D-бонус.

## Историческая сюжетная и системная документация

Файлы [00](docs/00_GAME_LEVELS_AND_ROUTES.md), [28](docs/28_AUTHORITATIVE_GAME_BIBLE.md)–[42](docs/42_V2_EDITORIAL_DECISIONS.md) содержат **множество ценных** сцен, рецептов, реплик, пазлов, предметов и программных контрактов. Они сохранены, но разделы про семь обязательных рутов, только постгейм-смену героев, отдельный финал Óни и отложенную встречу с игроком **устарели**. Использовать [карту миграции](docs/canon/06_MIGRATION_AND_PRODUCTION.md), не удалять детали без разбора.

## Исторические технические и дизайн-мануалы (01–27)
Их нельзя бездумно удалять: они содержат полезную архитектуру, факты реализации и ранний мозговой штурм. **Новый каталог docs/canon имеет приоритет над конфликтующими ранними идеями**, а реализационные утверждения 07–27 нужно сверять с кодом.

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

Дизайн: стилизованное 3D с ощущением 2D, неоновые пиксельные HUD/инвентарь/редактор, яркие многоярусные карты, тёмно-фиолетовые контуры. Технические поля английскими CAPS: `HEALTH`, `IS_ALIVE`, `TRUE/FALSE`; всплывающие подсказки при наведении, кнопки `COPY DELETE DONE` (не возвращать SHOW_HINTS). У Юки — **неоновый розовый 3D-куб выделения с парящим объектом**, как на авторском референсе.

**Принципы разработки:** общий Entity/Effect/Rule-дизайн; физика не меняется от наблюдателя; ничего нового не называть «реализовано», пока не проверены код и CI; ветка вместо прямого изменения main, если проект находится в фазе обсуждения; нет настоящего доступа к ОС через игровые мета-секреты.

## Технический статус и UX

Godot 4 + GDScript; действующий graybox 0.27 содержит универсальные Entity/Command/Effect/Rule-сервисы, инвентарь и сохранения, описанные в docs/07–27. Это фундамент прототипа, не готовый контент. Визуал: стилизованное 3D, пиксельно-неоновый интерфейс, CAPS-поля HEALTH/MANA/STAMINA, TRUE/FALSE, COPY/DELETE/DONE, подсказки по наведению. У Юки — розовая 3D-рамка выделения.

Всю дальнейшую сюжетную консолидацию вести в этой рабочей ветке и docs/canon. Main и код не изменены этим сценарным обновлением. До merge сверить документы с реализованными сервисами и провести тесты из docs/canon/06.
