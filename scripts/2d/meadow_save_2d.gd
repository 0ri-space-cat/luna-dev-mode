extends RefCounted
## Strict 2D snapshots. Never deserialize old Node3D/Vector3 format.
## Dynamic copies and reversible deletions share Entity IDs with CommandProcessor.
const Store = preload("res://scripts/core/json_store.gd")
const VERSION := 3
const SCENE := "eternia_meadow_2d"
const DEFAULT_PATH := "user://luna_meadow_2d_v3.json"
const LIMIT := 36
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
			"position": [(actor as Node2D).position.x, (actor as Node2D).position.y],
			"parameters": packed
		}
	return {
		"version": VERSION, "scene": SCENE,
		"player": [player.position.x, player.position.y],
		"entities": entries, "deleted_entities": world.deleted_ids(),
		"hack_session": session.export_data()
	}

func write(player: CharacterBody2D, world, session) -> bool:
	last_error = ""
	var answer: Dictionary = Store.write_document(path,snapshot(player,world,session))
	if not bool(answer.get("ok", false)):
		last_error = str(answer.get("error", "write failed"))
		return false
	return true

func read(player: CharacterBody2D, world, session, registry, lifecycle = null) -> bool:
	last_error = ""
	var result: Dictionary = Store.read_document(path)
	if not bool(result.get("ok",false)):
		last_error = str(result.get("error","read failed"))
		return false
	return apply_snapshot(result["data"],player,world,session,registry,lifecycle)

func _position(value: Variant) -> Dictionary:
	if not (value is Array) or value.size() != 2:
		return {"ok":false}
	if typeof(value[0]) not in [TYPE_INT,TYPE_FLOAT] or typeof(value[1]) not in [TYPE_INT,TYPE_FLOAT]:
		return {"ok":false}
	var x := float(value[0])
	var y := float(value[1])
	if x != x or y != y or absf(x) > 100000.0 or absf(y) > 100000.0:
		return {"ok":false}
	return {"ok":true,"value":Vector2(x,y)}

func apply_snapshot(data: Dictionary, player: CharacterBody2D, world, session, registry, lifecycle = null) -> bool:
	last_error = ""
	if int(data.get("version",-1)) != VERSION or str(data.get("scene","")) != SCENE:
		last_error = "Несовместимое сохранение; старые 3D файлы не затрагиваются"
		return false
	if not is_instance_valid(player):
		last_error = "Герой не загружен"
		return false
	var location: Dictionary = _position(data.get("player"))
	if not bool(location.get("ok",false)):
		last_error = "Некорректная позиция Луны"
		return false
	var values: Variant = data.get("entities")
	if not (values is Dictionary) or values.size() > LIMIT or values.is_empty():
		last_error = "Неверный реестр сущностей"
		return false
	var state: Variant = data.get("hack_session")
	if not session.validate_data(state):
		last_error = "Неверное состояние палочки"
		return false
	var deleted: Variant = data.get("deleted_entities",[])
	if not world.validate_deleted_ids(deleted):
		last_error = "Неверный список удалённых объектов"
		return false
	var planned: Array[Dictionary] = []
	for id in values.keys():
		if typeof(id) != TYPE_STRING or not str(id).is_valid_identifier() or str(id).length() > 90:
			last_error = "Некорректный ID"
			return false
		if deleted.has(id):
			last_error = "Удалённая сущность всё ещё присутствует"
			return false
		var entry: Variant = values[id]
		if not (entry is Dictionary):
			last_error = "Некорректный объект " + str(id)
			return false
		var pos: Dictionary = _position(entry.get("position"))
		if not bool(pos.get("ok",false)):
			last_error = "Неверные координаты " + str(id)
			return false
		var category := str(entry.get("category",""))
		var name := str(entry.get("name",""))
		var parameters: Variant = entry.get("parameters")
		if not (parameters is Dictionary) or parameters.size() != registry.get_specs_for(category).size():
			last_error = "Неверный набор свойств " + str(id)
			return false
		var checked := {}
		for spec in registry.get_specs_for(category):
			var key := str(spec["id"])
			if not parameters.has(key):
				last_error = "Нет параметра " + key
				return false
			var value: Variant = parameters[key]
			if str(spec["kind"]) == "color":
				if typeof(value) != TYPE_STRING or not Color.html_is_valid(value):
					last_error = "Неверный цвет " + str(id)
					return false
				value = Color.html(value)
			var check: Dictionary = registry.normalize(category,key,value)
			if not bool(check.get("ok",false)):
				last_error = "Неверный параметр " + key
				return false
			checked[key] = check["value"]
		var blueprint := {
			"id": str(id), "category": category, "name": name,
			"position": pos["value"], "parameters": checked
		}
		if lifecycle != null and not lifecycle.validate_blueprint(blueprint):
			last_error = "Не прошла проверка сущность " + str(id)
			return false
		var existing: Node = world.get_entity(str(id))
		if existing != null:
			var record: Variant = existing.get("record")
			if str(record.category) != category or str(record.display_name) != name:
				last_error = "Подмена ID " + str(id)
				return false
		elif lifecycle == null:
			last_error = "Нет адаптера восстановления"
			return false
		planned.append(blueprint)
	# Complete preflight before changing world state.
	for current in world.list_ids():
		if not values.has(current) and lifecycle == null:
			last_error = "Несовпадение количества объектов"
			return false
	if lifecycle != null:
		for current in world.list_ids():
			if not values.has(current):
				if lifecycle.delete_entity(current).is_empty():
					last_error = "Не удалось удалить старую сущность"
					return false
	for blueprint in planned:
		var id := str(blueprint["id"])
		var actor: Node = world.get_entity(id)
		if actor == null:
			actor = lifecycle.restore_entity(blueprint)
			if actor == null:
				last_error = "Не удалось восстановить " + id
				return false
		(actor as Node2D).position = blueprint["position"]
		for key in blueprint["parameters"].keys():
			actor.call("set_parameter", str(key),blueprint["parameters"][key])
	player.position = location["value"]
	session.import_data(state)
	world.restore_deleted_ids(deleted)
	return true
