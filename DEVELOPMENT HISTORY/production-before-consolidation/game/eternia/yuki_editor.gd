extends RefCounted

const Model = preload("res://eternia/yuki_rules.gd")
var game
var ui
var engine
var selected: Array[String] = []
var linking := false

func setup(owner_game) -> void:
	game = owner_game
	ui = game.ui
	engine = game.yuki_rules

func show_home() -> void:
	ui.page("Консоль Юки")
	ui.button("Карточки",cards)
	ui.button("Мир",pick_in_world)
	ui.button("Код",code)
	ui.button("Остановить все программы" if engine.running else "Запустить программы",func():
		engine.running = not engine.running
		show_home())
	ui.button("Убрать правило котов" if game.bag.has("_cats") else "Пример Юки · CAT_DENSITY",func():
		game.toggle_cat_rule()
		show_home())
	for i in engine.rules.size():
		ui.words(engine.describe(engine.rules[i]))
		ui.button("Удалить правило "+str(i+1),func(): engine.remove(i); show_home())
	ui.button("Закрыть",ui.close)

func code() -> void:
	ui.page("Юки   /   Код")
	ui.words("NEAR ID 60 SET ID IS_ALIVE false\nEVERY WORLD 5 SET @creature BASE_COLOR #deb8ff\nON_PAD meadow_pad 0 SET slime FROZEN true\nМожно добавить IF ID PARAMETER VALUE, ELSE VALUE и WAIT SECONDS")
	var input := LineEdit.new()
	ui.content.add_child(input)
	var result := Label.new()
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.content.add_child(result)
	ui.button("Сохранить правило",func():
		if engine.add(engine.parse(game,input.text)): show_home()
		else: result.text = "Проверь ID, название поля и значение. Всего помещается 12 правил.")
	ui.button("Назад",show_home)
	input.grab_focus()

func cards() -> void:
	ui.page("Юки   /   Карточки")
	var source := OptionButton.new()
	source.add_item("Каждые пять секунд здесь")
	source.set_item_metadata(0,"EVERY HERE 5")
	source.add_item("Каждые пять секунд во всей Этернии")
	source.set_item_metadata(1,"EVERY WORLD 5")
	for zone in game.rooms[game.current_location_id].get("zones",[]):
		source.add_item("Когда нажимают плиту ("+zone.id+")")
		source.set_item_metadata(source.item_count-1,"ON_PAD "+zone.id+" 0")
	var target := OptionButton.new()
	for id in game.world_registry.list_ids():
		var actor = game.world_registry.get_entity(id)
		if actor.location_id == game.current_location_id and game.can_see(actor) and id != "luna":
			source.add_item("Когда я подхожу к "+actor.record.display_name+" ("+id+")")
			source.set_item_metadata(source.item_count-1,"NEAR "+id+" 60")
			if id not in Model.PROTECTED:
				target.add_item(actor.record.display_name+" ("+id+")")
				target.set_item_metadata(target.item_count-1,id)
	for group in [["Все звери","@creature"],["Все предметы","@object"],["Все эмоты","@emot"]]:
		target.add_item(group[0])
		target.set_item_metadata(target.item_count-1,group[1])
	if selected.size() == 2:
		for i in source.item_count:
			if source.get_item_metadata(i) == selected[0]: source.select(i)
		for i in target.item_count:
			if target.get_item_metadata(i) == selected[1]: target.select(i)
	selected.clear()
	ui.words("Когда")
	ui.content.add_child(source)
	ui.words("Кого меняем")
	ui.content.add_child(target)
	var action := OptionButton.new()
	for choice in [["Оживает","IS_ALIVE true"],["Замирает","IS_ALIVE false"],["Идёт за мной","BEHAVIOR_MODE FOLLOW"],["Убегает","BEHAVIOR_MODE FLEE"],["Становится сиреневым","BASE_COLOR #deb8ff"],["Замерзает","FROZEN true"],["Оттаивает","FROZEN false"]]:
		action.add_item(choice[0])
		action.set_item_metadata(action.item_count-1,choice[1])
	ui.words("Что делает")
	ui.content.add_child(action)
	ui.button("Сохранить правило",func():
		var line := "%s SET %s %s" % [source.get_selected_metadata(),target.get_selected_metadata(),action.get_selected_metadata()]
		if engine.add(engine.parse(game,line)): show_home()
		else: ui.words("Не получилось сохранить правило."))
	ui.button("Назад",show_home)

func pick_in_world() -> void:
	linking = true
	selected.clear()
	ui.close()
	game.note("Сначала щёлкни по плите, существу или предмету, который запускает правило.")

func pick(at: Vector2) -> void:
	var best := 42.0
	var identity := ""
	for id in game.world_registry.list_ids():
		var actor = game.world_registry.get_entity(id)
		if actor.location_id != game.current_location_id or id == "luna" or not game.can_see(actor): continue
		if not selected.is_empty() and id in Model.PROTECTED: continue
		var distance: float = actor.global_position.distance_to(at)
		if distance < best:
			best = distance
			identity = id
	if selected.is_empty():
		for zone in game.rooms[game.current_location_id].get("zones",[]):
			var bounds := Rect2(zone.rect[0],zone.rect[1],zone.rect[2],zone.rect[3])
			if bounds.has_point(at):
				selected.append("ON_PAD "+zone.id+" 0")
				game.note("Теперь щёлкни по тому, кто будет реагировать.")
				return
		if not identity.is_empty():
			selected.append("NEAR "+identity+" 60")
			game.note("Теперь щёлкни по тому, кто будет реагировать.")
		return
	if identity.is_empty(): return
	selected.append(identity)
	if selected.size() == 2:
		linking = false
		cards()
