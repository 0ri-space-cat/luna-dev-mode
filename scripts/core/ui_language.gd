extends RefCounted
## UI-only localization. Game data, Entity IDs, parameter labels, recipe IDs and
## technical TRUE/FALSE values are deliberately stable across locales.
const SETTINGS_PATH := "user://luna_ui_settings.cfg"
const EN: Dictionary = {
	"ЗАКРЫТЬ   [ESC]": "DONE  [ESC]",
	"ЗАКРЫТЬ [B]": "CLOSE [B]",
	"СОХРАНИТЬ ЗАКЛИНАНИЕ": "SAVE SPELL",
	"С НУЛЯ": "NEW",
	"РАЗОБРАТЬ:": "DISSECT:",
	"Название заклинания": "Spell name",
	"МОЙ ХАОС": "MY CHAOS",
	"МОЁ ЗАКЛИНАНИЕ": "MY SPELL",
	"Собери цепочку. А последствия посмотрим.": "Assemble your magic. We'll deal with the consequences.",
	"CREATE · Создать": "CREATE",
	"SHAPE · Форма": "SHAPE",
	"ELEMENT · Стихия": "ELEMENT",
	"BEHAVIOR · Поведение": "BEHAVIOR",
	"RELEASE · Выпустить": "RELEASE",
	"ON_HIT · Попадание": "ON_HIT",
	"Скорость полёта": "FLIGHT_SPEED",
	"Размер": "SIZE",
	"Одна цель": "Single target",
	"Взрыв вокруг цели": "Burst around target",
	"Цепная молния": "Chain lightning",
	"Радиус взрыва": "BURST_RADIUS",
	"Количество переходов": "CHAIN_JUMPS",
	"ПРИ ПОПАДАНИИ:": "ON_HIT FIELD:",
	"ДЕЙСТВИЕ:": "OPERATION:",
	"+ ДОБАВИТЬ БЛОК": "+ ADD BLOCK",
	"ON_HIT · Цепочка эффектов [до 12]": "ON_HIT · EFFECT CHAIN [UP TO 12]",
	"Разбери заклинание. Перепиши как хочешь.": "Take it apart. Rewrite it your way.",
	"Без создания": "None",
	"Энергия": "Energy",
	"Предмет": "Object",
	"Существо": "Creature",
	"Сфера": "Orb",
	"Кристалл": "Shard",
	"Разряд": "Bolt",
	"Огонь": "Fire",
	"Лёд": "Frost",
	"Молния": "Lightning",
	"Искать цель": "Seek target",
	"Лететь прямо": "Fly straight",
	"Бродить": "Wander",
	"Следовать": "Follow",
	"Преследовать": "Chase",
	"Убегать": "Flee",
	"Бездействовать": "Idle",
	"Запустить": "Launch",
	"Создать рядом с целью": "Place by target",
	"Задать": "Set",
	"Переключить": "Toggle",
	"Прибавить": "Add",
	"Умножить": "Multiply",
	"ЗАДАТЬ": "SET",
	"ИЗМЕНИТЬ НА": "ADD",
	"УМНОЖИТЬ": "MULTIPLY",
	"ПЕРЕКЛЮЧИТЬ": "TOGGLE",
	"Пока пусто. Добавь пару пакостей.": "Empty for now. Add a little chaos.",
	"Двенадцать блоков. Дальше уже издевательство.": "Twelve blocks. Even magic has boundaries.",
	"ОГНЕННЫЙ ШАР": "FIREBALL",
	"ЛЕДЯНОЙ ОСКОЛОК": "FROST SHARD",
	"ИСКРОВОЙ РАЗРЯД": "ARC BOLT",
	"LUNA: DEV MODE   ✦   ПРОТОТИП 0.17": "LUNA: DEV MODE   ✦   PROTOTYPE 0.17",
	"WASD — ходить   •   ЛКМ — взломать   •   Shift+ЛКМ — колдовать   •   1–9 / Tab — выбрать   •   B — конструктор": "WASD — MOVE   •   LMB — HACK   •   SHIFT+LMB — CAST   •   1–9 / TAB — SELECT   •   B — WORKSHOP",
	"Попробуй: FRIDGE → IS_ALIVE TRUE → BEHAVIOR_MODE CHASE → TARGET_GROUP TREE": "TRY: FRIDGE → IS_ALIVE TRUE → BEHAVIOR_MODE CHASE → TARGET_GROUP TREE",
	"ДНЕВНИК ЛУНЫ   [J]": "LUNA'S JOURNAL   [J]",
	"Что я уже успела исследовать:": "What have I figured out so far?",
	"Пока ничего. Даже обидно.": "Nothing yet. Rude.",
	"Смотрела, но пока не трогала.": "Looked, but didn't touch.",
	"МИР СОХРАНЁН": "WORLD SAVED",
	"МИР ЗАГРУЖЕН": "WORLD LOADED",
	"НЕТ СОХРАНЕНИЯ": "NO SAVE FOUND",
	"Огонь перекинулся!": "Fire is spreading!",
	"ПШШ! Пар!": "PSSSH! Steam!",
	"Потушили!": "Extinguished!",
	"Ледышка! Буквально.": "Frozen. Literally.",
	"Пшш! Лёд растаял.": "Psssh! Ice melted.",
	"Сверхразряд!": "Superconduct!",
	"Искры и огонь!": "Sparks and fire!",
	"Магия реагирует.": "Magic reacts.",
	"Магии слишком много. Даже для меня.": "Too much magic. Even for me.",
	"ЗАКЛИНАНИЕ:": "SPELL:",
	"ПАЛОЧКА:": "WAND:",
	"ПРОТОТИП": "PROTOTYPE",
	"ГОТОВО:": "DONE:",
	"ОШИБКА СОХРАНЕНИЯ:": "SAVE ERROR:",
	"ОШИБКА ЗАГРУЗКИ:": "LOAD ERROR:"
}
var locale := "en"

func _init() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		var stored: String = str(cfg.get_value("interface", "language", "en"))
		if stored in ["en", "ru"]:
			locale = stored

func set_locale(value: String) -> bool:
	if value not in ["en", "ru"]:
		return false
	locale = value
	var cfg := ConfigFile.new()
	cfg.set_value("interface", "language", locale)
	return cfg.save(SETTINGS_PATH) == OK

func translated(value: String) -> String:
	if locale == "en":
		return str(EN.get(value, value))
	for original in EN.keys():
		if EN[original] == value:
			return str(original)
	return value

func hint(spec: Dictionary) -> String:
	if locale == "ru":
		return str(spec.get("hint", ""))
	return str(spec.get("hint_en", spec.get("label", "")))

func text(english: String, russian: String) -> String:
	return english if locale == "en" else russian
