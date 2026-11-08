extends RefCounted
## UI theme is presentation only; no parallel world simulation.
const THEMES := {
	"luna": {"accent": Color("#d85aff"), "secondary": Color("#45e9ef"), "title": "Луна", "tool": "Палочка"},
	"yuki": {"accent": Color("#f48ccf"), "secondary": Color("#ffd47e"), "title": "Юки", "tool": "Консоль"},
	"ori": {"accent": Color("#93d9ff"), "secondary": Color("#d7b6ff"), "title": "Ори", "tool": "Трафарет"},
	"mia": {"accent": Color("#f5a76a"), "secondary": Color("#fbe48c"), "title": "Мия", "tool": "Пипетка"},
	"leya": {"accent": Color("#ff94b6"), "secondary": Color("#a4f4bc"), "title": "Лея", "tool": "Сердце"},
	"toffi": {"accent": Color("#b5eb83"), "secondary": Color("#ffcc91"), "title": "Тоффи", "tool": "Наблюдение"},
	"oni": {"accent": Color("#b2a2ff"), "secondary": Color("#80e9ed"), "title": "Они", "tool": "Зрение"}
}
static func get_profile(character_id: String) -> Dictionary:
	return THEMES.get(character_id.to_lower(), THEMES["luna"]).duplicate(true)
