extends RefCounted
## Optional K1 cove, one physical collection, no pass or plot gate.
const PATH := Rect2(2330, 815, 90, 305)
const COVE := Rect2(2330, 1080, 410, 250)
const DECKS := [PATH, COVE]
const ENTRY := Vector2(2375, 1095)
const TRAY := Rect2(2520, 1100, 205, 185)
const OCTOPUS := "K1_COLLECTION_OCTOPUS"
const OCTOPUS_POINT := Vector2(2685, 1300)
const NATURAL_PREFIX := "K1_COLLECTION_SHELL_"
const COPY_PREFIX := "WAND_SHELL_COPY_"
const REQUIRED := 30
const LABEL := "Маленькая ракушка"


static func natural_id(index: int) -> String:
	return NATURAL_PREFIX + str(index)


static func indexed_id(identity: String, prefix: String, maximum: int) -> bool:
	if not identity.begins_with(prefix):
		return false
	var suffix := identity.trim_prefix(prefix)
	return suffix.is_valid_int() and int(suffix) >= 1 and int(suffix) <= maximum and suffix == str(int(suffix))


static func is_shell(identity: String) -> bool:
	return indexed_id(identity, NATURAL_PREFIX, REQUIRED) or indexed_id(identity, COPY_PREFIX, 32)


static func shell_point(index: int) -> Vector2:
	var slot := index - 1
	return Vector2(2360 + (slot % 5) * 31, 1140 + int(slot / 5.0) * 30)


static func identical_count(registry) -> int:
	var groups := {}
	var largest := 0
	for identity in registry.list_ids():
		if not is_shell(identity):
			continue
		var body = registry.get_entity(identity)
		if body == null or body.record.category != "prop" or body.is_attached() or body.has_passenger() or not body.motion.grounded or not is_zero_approx(body.motion.elevation) or not TRAY.has_point(body.position):
			continue
		var signature := str([body.get_parameter("material"), body.get_parameter("size"), body.get_parameter("color"), body.get_parameter("mass")])
		groups[signature] = int(groups.get(signature, 0)) + 1
		largest = maxi(largest, groups[signature])
	return largest


static func offsets() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for ring in range(1, 5):
		for y in range(-ring, ring + 1):
			for x in range(-ring, ring + 1):
				if maxi(absi(x), absi(y)) == ring:
					result.append(Vector2(x, y) * 26.0)
	return result


static func draw_on(canvas: Node2D) -> void:
	for deck in DECKS:
		canvas.draw_rect(deck, Color("a69b87"))
	canvas.draw_rect(TRAY, Color("8c8078"))
	canvas.draw_rect(TRAY.grow(-3), Color("c8b9a1"), false, 2.0)
	# Existing collection of spoons is background decoration, not a selectable item.
	for index in range(5):
		var point := Vector2(2348 + index * 9, 1308)
		canvas.draw_line(point, point + Vector2(3, -12), Color("c8c8b6"), 2.0)
		canvas.draw_circle(point + Vector2(3, -12), 3.0, Color("c8c8b6"))
