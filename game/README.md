# LUNA · Adventure

Единственная основная игра: [Adventure](scenes/skeleton/adventure.tscn). Открыть project.godot в Godot 4.3, F5 запускает Adventure; F6 — выбранную техническую сцену. WASD/стрелки, пробел, E — контекстное взаимодействие. Профили и ID не менять без проверенной миграции.

В самой игре Esc открывает меню с продолжением, сохранением, загрузкой и игровой рамкой. F5/F9 остаются быстрыми клавишами. Оконная рамка рисуется внутри игры.

Сборка **Adventure Alpha для macOS** запускается как отдельное приложение и сохраняет прогресс в `~/Library/Application Support/LUNA Adventure Alpha`. Для сборки из исходников нужен Godot 4.3 и его шаблон экспорта macOS. Из каталога `game/` выполнить `bash ci/build_macos_alpha.sh /absolute/path/LUNA-Adventure-Alpha.zip`. В архиве приложение с локальной подписью; публикация вне машины сборки потребует отдельной проверки подписи и нотарификации.

- scripts/core — общие реестры/команды/банк.
- scripts/runtime2d — общие системы и проверки.
- scripts/skeleton и scenes/skeleton — игровая сборка, география, тела, маршруты; fixture-сцены для регрессий.
- scenes/runtime2d — технические стенды, не вторые игры.
- tests и ci — автоматические проверки; [Actions](https://github.com/0ri-space-cat/luna-dev-mode/actions).

Старый обзор 24 комнат и специфический тест архивированы в [DEVELOPMENT HISTORY](../DEVELOPMENT%20HISTORY/production-before-consolidation/). Полный исходный срез [0faaf49](https://github.com/0ri-space-cat/luna-dev-mode/tree/0faaf49da6bc2e1f0d9683cf5e63132ff007724e).

Текущая очередь: [мануал §12](../docs/manual/00_LUNA_PRODUCTION_MANUAL.md#12-передача-следующей-модели--точное-следующее-действие).
