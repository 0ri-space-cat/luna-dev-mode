# Документация LUNA: DEV MODE

> **V3 · 09.11.2026.** Главная точка входа — [canon/00_START_HERE.md](canon/00_START_HERE.md). Старые утверждения о трёх основных мирах, обязательных шести героях ради Oni или семи полноразмерных кампаниях **недействительны**.

## Читать в таком порядке
1. [Основная библия](canon/01_GAME_BIBLE.md) — замысел, сюжет и обычный/скрытый финал.
2. [Герои](canon/02_CHARACTERS_AND_SIDE_STORIES.md) — встроенные специализации и персональные мини-истории.
3. [Этерния и Пустота](canon/03_WORLD_ADDRESS_AND_VOID.md) — плотная единая география.
4. [Механика мира](canon/04_HACKING_MANUAL.md) — палочка, глаза, три типа мостов, камера, рамка, CHARACTER.
5. [Сценарий](canon/05_CAMPAIGN_AND_SCENES.md) и [связанные улики](canon/18_NARRATIVE_CLUES.md).
6. [Граф скрытых знаний и учебные зоны](canon/14_SECRET_KNOWLEDGE_GRAPH.md).
7. [Артефакты](canon/07_ARTIFACT_CATALOG.md), [производственный handoff](canon/08_ARTIFACT_AGENT_HANDOFF.md).
8. [Матрица переноса старых квестов](canon/17_QUEST_MIGRATION_MATRIX.md).
9. [Реестр подтверждённого/открытого](canon/15_CANON_DECISIONS_AND_OPEN_QUESTIONS.md) — когда нельзя додумывать сюжет.
10. [Миграция и безопасность](canon/06_MIGRATION_AND_PRODUCTION.md), [аудит репозитория](canon/16_REPOSITORY_AUDIT.md).

## Подробный план фактического создания игры
[Бестиарий](canon/19_BESTIARY_AND_ECOLOGY.md) · [Параметры, способности и реакции](canon/20_SYSTEMS_PARAMETERS_AND_INTERACTIONS.md) · [Атлас комнат и уровней](canon/21_ETERNIA_LEVELS_AND_INTERIORS_ATLAS.md) · [Постановочное прохождение](canon/22_FULL_PLAYTHROUGH_AND_DIRECTED_SCENARIO.md) · [Атлас секретов](canon/23_SECRETS_PUZZLES_AND_META_LEVELS_ATLAS.md) · [Аудит всех артефактов](canon/24_ARTIFACT_AUDIT_AND_ACQUISITION_ROUTES.md).

Эти главы расширяют концепцию до уровня постановочных спецификаций. Все конкретные цифры, названия залов и уникальные эффекты, которые не были прямо утверждены автором, остаются проектными до теста и согласования.

**[План реализации и критерии приёмки](canon/25_IMPLEMENTATION_HANDOFF_AND_ACCEPTANCE.md)** — последовательность вертикальных срезов S0–S8, тесты и handoff агентам. [Диалоги, жизнь Этернии и подсказки](canon/26_DIALOGUES_AMBIENT_LIFE_AND_HINTS.md) — реактивные реплики, повадки существ и скрытые улики без спойлеров.

## Инженерные материалы, не заменять фантомными требованиями
[Перенос способностей](canon/09_PROPERTY_TRANSFER_SYSTEM.md) · [2D-пайплайн](canon/10_2D_ASSET_PIPELINE.md) · [план Godot](canon/11_2D_IMPLEMENTATION_PLAN.md) · [Оракул](canon/12_TECH_LANGUAGE_ORACLE.md) · [очередь старых генераций](canon/13_GENERATION_BATCHES.md) · [старые docs/01–27](01_VISION_AND_WORLD.md).

## Архив
[Снимок предшествующего канона 08.11.2026](archive/2026-11-09-pre-eternia/README.md) и [исторические сценарии 00/28–42](archive/README.md). Использовать для поиска подробностей задач, физических решений, реплик и арта. Не смешивать прежние авторские решения с новой версией без явного согласования.

## Как вносить изменения
При творческом решении сначала обновить [реестр статусов](canon/15_CANON_DECISIONS_AND_OPEN_QUESTIONS.md), затем главы библии и граф знаний, квестовую матрицу и только после — код/ассеты. Вся работа отдельной веткой с PR; существующие 3D и 2D ветки не трогать во время документационной ревизии. Не утверждать, что сюжет реализован, пока нет воспроизводимого игрового теста.
