extends RefCounted
## Full-body authored cels: no detached limbs or runtime-drawn character art.
const MANIFEST := "res://assets/2d/characters/luna/explorer_animation/manifest.json"
const WALK_FPS := 8.0
const CAST_START_TIME := 0.06
const CAST_WINDUP_TIME := 0.11
const CAST_RELEASE_TIME := 0.19
const CAST_RECOVERY_TIME := 0.33
const CAST_DURATION := 0.42
var clips := {}
var idles := {}
var textures := {}

func configure(assets: Dictionary, feet: Dictionary) -> void:
 for view in assets:
  idles[view] = {"path": assets[view], "pivot": [512, feet[assets[view].get_file()]]}
 if FileAccess.file_exists(MANIFEST):
  clips = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)).get("views", {})

func texture_for_path(path: String) -> Texture2D:
 if not textures.has(path):
  var image := Image.load_from_file(ProjectSettings.globalize_path(path))
  assert(image != null and not image.is_empty(), "Missing Luna cel: " + path)
  textures[path] = ImageTexture.create_from_image(image)
 return textures[path]

func preload_cels() -> void:
 # Decode/upload before gameplay, so a first turn or cast does not hitch.
 for view_clips in clips.values():
  for clip in view_clips.values():
   for cel in clip:
    if cel is Dictionary: texture_for_path(cel["path"])

func frames(view: String, clip: String) -> Array:
 return clips.get(view, {}).get(clip, [])

func sample(view: String, clip: String, time: float) -> Dictionary:
 var available := frames(view, clip)
 if available.is_empty(): return idles[view]
 var entry = null
 match clip:
  "walk": entry = available[posmod(int(floor(time * WALK_FPS)), available.size())]
  "cast":
   if time < CAST_START_TIME or time >= CAST_RECOVERY_TIME: return idles[view]
   if available.size() >= 3:
    # Brief close anticipation, outward wind-up, then gaze-aligned release.
    entry = available[0 if time < CAST_WINDUP_TIME else (1 if time < CAST_RELEASE_TIME else 2)]
   else:
    entry = available[0 if time < CAST_RELEASE_TIME else mini(1, available.size() - 1)]
  "blink":
   if time < 0.035 or time > 0.14: return idles[view]
   entry = available[0]
  "hair":
   if time < 0.10 or time > 0.30: return idles[view]
   entry = available[0]
 return entry if entry is Dictionary else idles[view]

func apply(sprite: Sprite2D, view: String, clip: String, time: float, scale_value: float, bounce: float) -> void:
 var cel := sample(view, clip, time)
 var path: String = cel["path"]
 sprite.texture = texture_for_path(path)
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 sprite.set_meta("feet_y", cel["pivot"][1])
 sprite.set_meta("cel_path", path)
 sprite.scale = Vector2.ONE * scale_value
 sprite.position = Vector2((sprite.texture.get_width() * 0.5 - cel["pivot"][0]) * scale_value, (sprite.texture.get_height() * 0.5 - cel["pivot"][1]) * scale_value - bounce)
