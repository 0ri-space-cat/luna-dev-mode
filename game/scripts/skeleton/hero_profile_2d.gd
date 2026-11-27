extends RefCounted
## One physical traveler, seven profiles; no duplicate Entity, wand or bank.
const LUNA := "LUNA"
const ONI := "ONI"
const YUKI := "YUKI"
const ORI := "ORI"
const MIA := "MIA"
const LEIA := "LEIA"
const TOFFI := "TOFFI"
const ORDER := [LUNA, YUKI, MIA, ORI, LEIA, TOFFI, ONI]
const NAMES := {LUNA: "Луна", ONI: "Они", YUKI: "Юки", ORI: "Ори", MIA: "Мия", LEIA: "Лея", TOFFI: "Тоффи"}
const DESCRIPTIONS := {LUNA: "Обычный профиль", YUKI: "Общие возможности", MIA: "Общие возможности", ORI: "Общие возможности", LEIA: "Зверьки тянутся к Лее", TOFFI: "Видит незримых существ", ONI: "Изнанка с закрытыми глазами"}
var active := LUNA


static func completed_branches(yuki_stage: int, mia_stage: int, ori_stage: int, leia_completed: bool, toffi_stage: int, oni_completed: bool) -> Dictionary:
	# Existing final episode states are authoritative, not loan ownership,
	# ordinary meetings, invitations, or a new duplicated unlock counter.
	return {YUKI: yuki_stage == 2, MIA: mia_stage == 2, ORI: ori_stage == 2,
		LEIA: leia_completed, TOFFI: toffi_stage == 2, ONI: oni_completed}


func available(completed: Dictionary) -> Array[String]:
	var ids: Array[String] = [LUNA]
	for id in ORDER:
		if id != LUNA and completed.get(id, false) == true:
			ids.append(id)
	return ids


func restore(value: Variant, completed: Dictionary) -> bool:
	if not value is String or value not in available(completed):
		return false
	active = value
	return true


func choose(value: String, completed: Dictionary, authorized: bool) -> bool:
	return authorized and restore(value, completed)


func sees_underside(eyes_open: bool) -> bool:
	return active == ONI and not eyes_open


func sees_hidden_creatures() -> bool:
	return active == TOFFI


func attracts_animals() -> bool:
	return active == LEIA


static func within_projected_control(body: Node2D, camera: Camera2D, target: Control, reach: float) -> bool:
	if not is_instance_valid(body) or not is_instance_valid(camera) or not camera.is_current() or not is_instance_valid(target) or not target.is_visible_in_tree():
		return false
	camera.force_update_scroll()
	var screen: Rect2 = camera.get_viewport().get_visible_rect()
	var bounds: Rect2 = target.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, target.size)
	var point: Vector2 = camera.get_canvas_transform() * body.global_position
	return bounds.has_area() and screen.has_point(point) and bounds.grow(reach).has_point(point)
