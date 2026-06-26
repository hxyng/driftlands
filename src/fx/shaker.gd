class_name Shaker
extends Node
## Trauma-based screen shake. Callers add trauma; the offset scales with its
## square (so small hits barely nudge, big ones kick) and decays smoothly.

@export var max_offset := 6.0
@export var decay := 1.6

var camera: Camera2D
var _trauma := 0.0


func add(amount: float) -> void:
	_trauma = clampf(_trauma + amount * 0.1, 0.0, 1.0)


func _process(delta: float) -> void:
	if camera == null:
		return
	_trauma = maxf(0.0, _trauma - decay * delta)
	var shake := _trauma * _trauma
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake * max_offset
