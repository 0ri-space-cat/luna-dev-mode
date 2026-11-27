extends RefCounted
## One catalog and one shared ability bank. Form discovery is independent of modules.
const FORMS := {"cat": "Котик", "fox": "Лисичка", "ray": "Скат", "lizard": "Ящерка", "trollik": "Троллик"}
const RELATIONS := ["FRIEND", "NEUTRAL", "HOSTILE", "AFRAID"]
const MODULES := ["", "GLOW", "FLY"]
const MAX_SERIAL := 999999 # Stable ID bound; live bodies are limited by the shared world.
var ownership := 0
var known: Array[String] = []
var template: Dictionary = {}
var serial := 0
var order_id := ""


func discover(form: String) -> bool:
	if not FORMS.has(form) or form in known:
		return false
	known.append(form)
	return true


func valid_template(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 4 or data.get("form") not in known or data.get("relation") not in RELATIONS or data.get("ability") not in MODULES:
		return false
	var size: Variant = data.get("size")
	return typeof(size) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(size)) and float(size) >= 0.5 and float(size) <= 2.0


func snapshot() -> Dictionary:
	return {"ownership": ownership, "known": known.duplicate(), "template": template.duplicate(true), "serial": serial, "order_id": order_id}


func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 5:
		return false
	var state: Variant = data.get("ownership")
	var count: Variant = data.get("serial")
	if typeof(state) not in [TYPE_INT, TYPE_FLOAT] or float(state) not in [0.0, 1.0, 2.0]:
		return false
	if typeof(count) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(count)) or float(count) != floorf(float(count)) or float(count) < 0 or float(count) > MAX_SERIAL:
		return false
	var forms: Variant = data.get("known")
	if not forms is Array or forms.size() > FORMS.size():
		return false
	var checked: Array[String] = []
	for form in forms:
		if not form is String or not FORMS.has(form) or form in checked:
			return false
		checked.append(form)
	var saved_template: Variant = data.get("template")
	var order: Variant = data.get("order_id")
	if not saved_template is Dictionary or not order is String:
		return false
	if not order.is_empty() and (not order.begins_with("ORI_CREATED_") or not order.trim_prefix("ORI_CREATED_").is_valid_int() or int(order.trim_prefix("ORI_CREATED_")) < 1 or int(order.trim_prefix("ORI_CREATED_")) > int(count)):
		return false
	known = checked
	if not saved_template.is_empty() and not valid_template(saved_template):
		return false
	ownership = int(state)
	serial = int(count)
	template = saved_template.duplicate(true)
	order_id = order
	return true
