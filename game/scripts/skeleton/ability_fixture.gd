extends "res://scripts/skeleton/entity_fixture.gd"
## P9-04 developer room. The three tools are physical test props.

const Bank = preload("res://scripts/core/ability_bank_service.gd")
const RECIPIENT_ID := "DEV_FLY_BENCH"
const INSTANCE_ID := "DEV_FLY_01"
const MODULE := {"ability_id": "FLY", "enabled": true, "protected": false}
const ARTIFACTS := {
	"ORI_CATALOG": {"label": "Каталог", "point": Vector2(145, 320)},
	"TAMAGOTCHI": {"label": "Тамагочи", "point": Vector2(176, 345)},
	"REALITY_STAMP": {"label": "Штамп", "point": Vector2(245, 350)},
}
var bank := Bank.new(entities, commands)


func _location_id() -> String:
	return "DEV_ABILITY_BANK"


func _ready() -> void:
	super._ready()
	var donor := entities.get_entity(TARGET_ID) as EntityBody
	var recipient := spawn_entity({
		"id": RECIPIENT_ID, "category": "prop", "label": "Скамейка", "material": "WOOD",
	}, Vector2(270, 298), UPPER_HEIGHT)
	donor.record.set_component("ABILITY_SET", {"instances": {INSTANCE_ID: MODULE}})
	for body in [donor, recipient]:
		body.set_parameter("alive", true)
		body.set_parameter("behavior_mode", "IDLE")
	for identity in ARTIFACTS:
		var item := spawn_entity({
			"id": identity, "category": "prop", "label": ARTIFACTS[identity]["label"], "material": "METAL",
		}, ARTIFACTS[identity]["point"], UPPER_HEIGHT)
		item.set_parameter("pickable", true)


func _holds_artifact(identity: String) -> bool:
	var item := entities.get_entity(identity) as EntityBody
	return item != null and item.is_carried_by(actor)


func has_bank_access() -> bool:
	for identity in ARTIFACTS:
		if _holds_artifact(identity):
			return true
	return false


func _in_transfer_reach(target: EntityBody) -> bool:
	if not (actor as EntityBody).accepts_player_input() or target == null:
		return false
	if target.entity_id not in [TARGET_ID, RECIPIENT_ID] or target.location_id != _location_id():
		return false
	var offset := actor.position - target.position
	var height_gap := actor.motion.elevation - target.motion.elevation
	return Vector3(offset.x, offset.y, height_gap).length_squared() <= WandPolicy.REACH_PX * WandPolicy.REACH_PX


func request_extract(target_id: String, instance_id: String) -> bool:
	var target := entities.get_entity(target_id) as EntityBody
	if not has_bank_access() or not _in_transfer_reach(target):
		return false
	if not wand_policy.authorize(actor, target, _location_id(), projection, access, parameters, "mass"):
		return false
	return bank.move_instance(ENTITY_ID, target_id, instance_id, true)


func request_catalog_install(target_id: String, instance_id: String) -> bool:
	var target := entities.get_entity(target_id) as EntityBody
	if not _holds_artifact("ORI_CATALOG") or not _in_transfer_reach(target) \
			or not target.get_parameter("alive"):
		return false
	return bank.move_instance(ENTITY_ID, target_id, instance_id, false)


func get_wand_editor_tabs(target_id: String) -> Dictionary:
	if ARTIFACTS.has(target_id):
		return {}
	var tabs := super.get_wand_editor_tabs(target_id)
	if tabs.is_empty() or not has_bank_access():
		return tabs
	var target := entities.get_entity(target_id) as EntityBody
	var installed := Bank.instances(target.record.get_components(), "ABILITY_SET")
	var fields: Array[Dictionary] = []
	for instance_id in installed:
		fields.append({
			"id": instance_id, "label": installed[instance_id]["ability_id"],
			"kind": "action", "value": "В банк",
			"action": func(): return request_extract(target_id, instance_id),
		})
	tabs["Способности"] = fields
	return tabs


func _unhandled_key_input(event: InputEvent) -> void:
	if keyboard and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER:
		if not is_instance_valid(_debug_editor) and request_catalog_install(RECIPIENT_ID, INSTANCE_ID):
			get_viewport().set_input_as_handled()
		return
	super._unhandled_key_input(event)


func _apply_keyboard_input() -> void:
	super._apply_keyboard_input()
	var thrust := not is_instance_valid(_debug_editor) and Input.is_physical_key_pressed(KEY_F)
	for identity in [TARGET_ID, RECIPIENT_ID]:
		var body := entities.get_entity(identity) as EntityBody
		body.thrust_requested = thrust


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	$BankReadout.text = "FLY в банке: %d" % bank.amount(ENTITY_ID, "FLY") if has_bank_access() else ""


func make_snapshot() -> Dictionary:
	var data := super.make_snapshot()
	for entry in data["entities"]:
		entry["components"] = entities.get_entity(entry["id"]).record.get_components()
	return data


func _build_saved_entity(state: Variant, version: int) -> EntityBody:
	var body := super._build_saved_entity(state, version)
	if body != null:
		var components: Variant = state.get("components")
		if not components is Dictionary or not body.record.set_components(components):
			body.free()
			return null
	return body


func _validate_saved_entities(candidates: Dictionary) -> bool:
	var expected := {ENTITY_ID: "player", TARGET_ID: "fridge", YETI_ID: "yeti", RECIPIENT_ID: "prop"}
	for identity in ARTIFACTS:
		expected[identity] = "prop"
	if candidates.size() != expected.size():
		return false
	var instance_count := 0
	for identity in expected:
		var body: EntityBody = candidates.get(identity)
		if body == null or body.flight_enabled or body.record.category != expected[identity]:
			return false
		var components := body.record.get_components()
		for component_id in components:
			var owner_allowed: bool = (
				identity == ENTITY_ID if component_id == "ABILITY_BANK"
				else component_id == "ABILITY_SET" and identity in [TARGET_ID, RECIPIENT_ID]
			)
			if not owner_allowed:
				return false
			var component: Dictionary = components[component_id]
			if not component.get("ids", []).is_empty() or not component.get("stock", {}).is_empty():
				return false
			var instances := Bank.instances(components, component_id)
			if instances != {INSTANCE_ID: MODULE}:
				return false
			instance_count += 1
	return instance_count == 1


func _draw() -> void:
	super._draw()
	var font := ThemeDB.fallback_font
	for identity in ARTIFACTS:
		var entry: Dictionary = ARTIFACTS[identity]
		draw_string(font, entry["point"] + Vector2(-23, 12), entry["label"], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12)
