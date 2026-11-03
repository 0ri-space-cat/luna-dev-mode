extends RefCounted
## Shared atomic JSON file storage for run snapshots, profiles and future saves.
## Not responsible for domain schema validation.

static func write_document(path: String, payload: Dictionary) -> Dictionary:
	var encoded := JSON.stringify(payload, "\t")
	var temporary := path + ".tmp"
	var stream := FileAccess.open(temporary, FileAccess.WRITE)
	if stream == null:
		return {"ok": false, "error": "Cannot open temporary file: %s" % FileAccess.get_open_error()}
	stream.store_string(encoded)
	stream.flush()
	stream.close()
	var error: Error = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary),
		ProjectSettings.globalize_path(path)
	)
	if error != OK:
		return {"ok": false, "error": "Cannot replace file: %s" % error}
	return {"ok": true}


static func read_document(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "File not found"}
	var stream := FileAccess.open(path, FileAccess.READ)
	if stream == null:
		return {"ok": false, "error": "Cannot open file: %s" % FileAccess.get_open_error()}
	var content := stream.get_as_text()
	stream.close()
	var parser := JSON.new()
	var error: Error = parser.parse(content)
	if error != OK:
		return {"ok": false, "error": "Invalid JSON at line %d" % parser.get_error_line()}
	if typeof(parser.data) != TYPE_DICTIONARY:
		return {"ok": false, "error": "Document root must be a dictionary"}
	return {"ok": true, "data": parser.data}
