extends RefCounted
## Commands operate on the same typed fields as the field editor.

const HELP := "help · get ID FIELD · set ID FIELD VALUE\nВ режиме полей достаточно точного имени из окна взлома."

static func find_field(registry, category: String, name: String) -> Dictionary:
	for spec in registry.get_specs_for(category):
		if spec.label == name and spec.id not in ["material", "access_level"]:
			return spec
	return {}

static func run(game, input: String) -> String:
	var tokens := input.strip_edges().split(" ", false)
	if tokens.is_empty():
		return ""
	match tokens[0]:
		"help": return HELP
		"get", "set":
			var writing := tokens[0] == "set"
			if tokens.size() != (4 if writing else 3):
				return HELP
			var actor = game.world_registry.get_entity(tokens[1])
			if not is_instance_valid(actor):
				return "Неизвестная цель."
			var spec := find_field(game.parameter_registry, actor.record.category, tokens[2])
			if spec.is_empty():
				return "У этой цели нет такого поля."
			if writing:
				var typed: Variant = parse_value(spec.kind, tokens[3])
				if typed == null or not game.edit_remote(tokens[1], spec.id, typed):
					return "Поле не приняло это значение."
			return "%s = %s" % [spec.label, actor.get_parameter(spec.id)]
		_: return "Неизвестная команда. Список команд — help."

static func parse_value(kind: String, source: String) -> Variant:
	match kind:
		"bool":
			if source in ["true", "false"]:
				return source == "true"
		"int":
			if source.is_valid_int():
				return source.to_int()
		"float":
			if source.is_valid_float() and is_finite(source.to_float()):
				return source.to_float()
		"color":
			if Color.html_is_valid(source):
				return Color(source)
		"enum":
			return source
	return null
