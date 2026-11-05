extends SceneTree

const AssetRegistry = preload("res://scripts/core/asset_registry.gd")
const LunaShell = preload("res://scripts/luna_shell.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var registry := AssetRegistry.new()
	assert(registry.load_catalog())
	assert(registry.list_ids().size() >= 12)
	assert(registry.get_path("luna.portrait") == "res://assets/generated/luna_portrait.png")
	assert(registry.load_asset("luna.portrait") == null)
	assert(registry.get_path("unknown.asset").is_empty())
	var shell := LunaShell.new()
	root.add_child(shell)
	await process_frame
	assert(shell.find_child("HEALTHSlot", true, false) != null)
	assert(shell.find_child("MANASlot", true, false) != null)
	assert(shell.find_child("STAMINASlot", true, false) != null)
	for panel_id in ["INVENTORY", "HACK", "MAGIC", "DIALOGUE", "JOURNAL", "MAP", "SETTINGS", "HELP"]:
		assert(shell.buttons.has(panel_id))
	shell.queue_free()
	await process_frame
	await process_frame
	print("PASS: asset catalog fallbacks and asset-ready UI slots")
	quit()
