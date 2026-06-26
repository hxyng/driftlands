class_name FrameAnimator
extends Node
## Drives a [Sprite2D] through the named animations in a sheet's manifest entry
## by setting [member Sprite2D.region_rect] each frame. Lightweight alternative
## to building SpriteFrames resources by hand.

signal finished(anim_name)

var sprite: Sprite2D
var _def: Dictionary = {}
var _anim := ""
var _frames: Array = []
var _fps := 8.0
var _loop := true
var _time := 0.0
var _index := 0


func setup(target: Sprite2D, sheet_name: String) -> void:
	sprite = target
	_def = SpriteDB.entry(sheet_name)
	sprite.texture = SpriteDB.texture(sheet_name)
	sprite.region_enabled = true
	sprite.centered = true


func play(anim: String, loop := true) -> void:
	if _anim == anim:
		return
	if not _def.get("anims", {}).has(anim):
		return
	_anim = anim
	var a: Dictionary = _def["anims"][anim]
	_frames = a.get("frames", [0])
	_fps = float(a.get("fps", 8))
	_loop = loop
	_index = 0
	_time = 0.0
	_apply()


## Force a non-looping animation to restart even if already current (attacks).
func restart(anim: String) -> void:
	_anim = ""
	play(anim, false)


func _process(delta: float) -> void:
	if _frames.size() <= 1:
		return
	_time += delta
	if _time < 1.0 / _fps:
		return
	_time = 0.0
	_index += 1
	if _index >= _frames.size():
		if _loop:
			_index = 0
		else:
			_index = _frames.size() - 1
			finished.emit(_anim)
			return
	_apply()


func _apply() -> void:
	if sprite == null or _frames.is_empty():
		return
	var fw: int = _def.get("fw", 16)
	var fh: int = _def.get("fh", 16)
	sprite.region_rect = Rect2(int(_frames[_index]) * fw, 0, fw, fh)
