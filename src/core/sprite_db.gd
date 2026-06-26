class_name SpriteDB
extends RefCounted
## Loads the generated sprite manifest (assets/sprites/sprites.json) once and
## caches textures. The manifest is produced by tools/gen_assets.py and maps
## each sheet name to its frame size and named animations.

const DIR := "res://assets/sprites/"

static var _manifest: Dictionary = {}
static var _textures: Dictionary = {}


static func manifest() -> Dictionary:
	if _manifest.is_empty():
		var f := FileAccess.open(DIR + "sprites.json", FileAccess.READ)
		if f != null:
			var data: Variant = JSON.parse_string(f.get_as_text())
			f.close()
			if data is Dictionary:
				_manifest = data
	return _manifest


static func entry(name: String) -> Dictionary:
	return manifest().get(name, {})


static func texture(name: String) -> Texture2D:
	if not _textures.has(name):
		var e := entry(name)
		var file: String = e.get("file", name + ".png")
		_textures[name] = load(DIR + file)
	return _textures[name]


## Region rect for one frame of an atlas-style sheet (items, tiles).
static func atlas_region(name: String, index: int) -> Rect2:
	var e := entry(name)
	var fw: int = e.get("fw", 16)
	return Rect2(index * fw, 0, fw, e.get("fh", 16))


## Region rect for a named icon in the items atlas (by manifest index map).
static func item_region(icon: String) -> Rect2:
	var idx: int = entry("items").get("index", {}).get(icon, 0)
	return Rect2(idx * 16, 0, 16, 16)
