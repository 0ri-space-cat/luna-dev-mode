extends PanelContainer
## Internal six-tab editor. Each input delegates to the world request.

func populate(tabs: Dictionary, submit: Callable) -> void:
	var stack := TabContainer.new()
	add_child(stack)
	for title in tabs:
		var page := VBoxContainer.new()
		page.name = title
		stack.add_child(page)
		for spec in tabs[title]:
			var row := HBoxContainer.new()
			page.add_child(row)
			var label := Label.new()
			label.text = spec["label"]
			label.custom_minimum_size.x = 160
			row.add_child(label)
			_add_input(row, spec, submit)


func _add_input(row: HBoxContainer, spec: Dictionary, submit: Callable) -> void:
	var key: String = spec["id"]
	var initial: Variant = spec["value"]
	match spec["kind"]:
		"action":
			var button := Button.new()
			button.text = initial
			button.pressed.connect(func():
				if spec["action"].call():
					button.disabled = true)
			row.add_child(button)
		"bool":
			var toggle := CheckBox.new()
			toggle.button_pressed = initial
			row.add_child(toggle)
			toggle.toggled.connect(func(value: bool):
				if not submit.call(key, value):
					toggle.set_pressed_no_signal(not value))
		"float":
			var number := SpinBox.new()
			number.min_value = spec["min"]
			number.max_value = spec["max"]
			number.step = maxf(float(spec["step"]), 0.01)
			number.value = initial
			row.add_child(number)
			number.value_changed.connect(func(value: float):
				if not submit.call(key, value):
					number.set_value_no_signal(float(number.get_meta("accepted")))
				else:
					number.set_meta("accepted", value))
			number.set_meta("accepted", initial)
		"enum", "color":
			var options := OptionButton.new()
			var choices: Array = spec["choices"]
			for choice in choices:
				options.add_item(choice["name"])
			for index in range(choices.size()):
				if choices[index]["value"] == initial:
					options.select(index)
			options.set_meta("accepted", options.selected)
			row.add_child(options)
			options.item_selected.connect(func(index: int):
				if submit.call(key, choices[index]["value"]):
					options.set_meta("accepted", index)
				else:
					options.select(int(options.get_meta("accepted"))))
