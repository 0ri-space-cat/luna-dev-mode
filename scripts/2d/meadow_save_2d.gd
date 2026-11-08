extends RefCounted
## Separate, validated 2D save; never parses old Vector3 saves as Vector2.
const Store = preload("res://scripts/core/json_store.gd")
const VERSION := 2
const SCENE := "eternia_meadow_2d"
const DEFAULT_PATH := "user://luna_meadow_2d_v2.json"
var path: String
var last_error := ""

func _init(save_path: String = DEFAULT_PATH) -> void:
	path = save_path

func has_save() -> bool:
	return FileAccess.file_exists(path)

func snapshot(player: CharacterBody2D, world, session) -> Dictionary:
	var entries := {}
	for id in world.list_ids():
		var actor: Node = world.get_entity(id)
		if not is_instance_valid(actor):
			continue
		var rec: Variant = actor.get("record")
		var packed := {}
		for key in rec.parameters.keys():
			var value: Variant = rec.parameters[key]
			packed[str(key)] = value.to_html(true) if value is Color else value
		entries[id] = {
			"category": str(rec.category), "name": str(rec.display_name),
			"position": [actor.position.x, actor.position.y], "parameters": packed
		}
	return {
		"version": VERSION, "scene": SCENE, "player": [player.position.x, player.position.y],
		"entities": entries, "hack_session": session.export_data()
	}

func write(player: CharacterBody2D, world, session) -> bool:
	last_error = ""
	var answer: Dictionary = Store.write_document(path, snapshot(player, world, session))
	if not bool(answer.get("ok", false)):
		last_error = str(answer.get("error", "write failed"))
		return false
	return true

func read(player: CharacterBody2D, world, session, registry) -> bool:
	last_error = ""
	var received: Dictionary = Store.read_document(path)
	if not bool(received.get("ok", false)):
		last_error = str(received.get("error", "read failed"))
		return false
	return apply_snapshot(received["data"], player, world, session, registry)

func _position(value: Variant) -> Dictionary:
	if not (value is Array) or value.size() != 2:
		return {"ok": false}
	if typeof(value[0]) not in [TYPE_INT, TYPE_FLOAT] or typeof(value[1]) not in [TYPE_INT, TYPE_FLOAT]:
		return {"ok": false}
	var x := float(value[0])
	var y := float(value[1])
	if x != x or y != y or absf(x) > 100000.0 or absf(y) > 100000.0:
		return {"ok": false}
	return {"ok": true, "value": Vector2(x, y)}

func apply_snapshot(data: Dictionary, player: CharacterBody2D, world, session, registry) -> bool:
	last_error = ""
	if int(data.get("version", -1)) != VERSION or str(data.get("scene", "")) != SCENE:
		last_error = "Несовместимое сохранение; старая 3D-версия остаётся отдельно"
		return false
	var start: Dictionary = _position(data.get("player"))
	if not bool(start.get("ok", false)):
		last_error = "Неверные координаты Луны"
		return false
	var entries: Variant = data.get("entities")
	if not (entries is Dictionary) or entries.size() != world.count_live():
		last_error = "Неверный список существ"
		return false
	var state: Variant = data.get("hack_session")
	if not session.validate_data(state):
		last_error = "Неверное состояние палочки"
		return false
	# Preflight every value and entity before mutating anything.
	var planned: Array[Dictionary] = []
	for id in world.list_ids():
		if not entries.has(id) or not (entries[id] is Dictionary):
			last_error = "Нет сущности " + id
			return false
		var actor: Node = world.get_entity(id)
		var rec: Variant = actor.get("record")
		var entry: Dictionary = entries[id]
		if str(entry.get("category", "")) != str(rec.category) or str(entry.get("name", "")) != str(rec.display_name):
			last_error = "Несовпадение сущности " + id
			return false
		var pos: Dictionary = _position(entry.get("position"))
		if not bool(pos.get("ok", false)):
			last_error = "Неверная позиция " + id
			return false
		var parameters: Variant = entry.get("parameters")
		if not (parameters is Dictionary) or parameters.size() != rec.parameters.size():
			last_error = "Неверные параметры " + id
			return false
		var checked := {}
		for key in rec.parameters.keys():
			if not parameters.has(key):
				last_error = "Нет параметра " + str(key)
				return false
			var value: Variant = parameters[key]
			var definition: Dictionary = registry.get_spec(rec.category, str(key))
			if str(definition.get("kind", "")) == "color":
				if typeof(value) != TYPE_STRING or not Color.html_is_valid(value):
					last_error = "Неверный цвет"
					return false
				value = Color.html(value)
			var valid: Dictionary = registry.normalize(rec.category, str(key), value)
			if not bool(valid.get("ok", false)):
				last_error = "Некорректный параметр: " + str(key)
				return false
			checked[key] = valid["value"]
		planned.append({"actor": actor, "position": pos["value"], "parameters": checked})
	for step in planned:
		var actor: Node = step["actor"]
		actor.position = step["position"]
		for key in step["parameters"].keys():
			actor.call("set_parameter", str(key), step["parameters"][key])
	player.position = start["value"]
	session.import_data(state)
	return true
