class_name Effect
extends Node2D
## A one-shot animated sprite (slash, hit spark, death poof) that frees itself
## when the animation finishes.

var _sprite: Sprite2D
var _anim: FrameAnimator


func play(sheet: String, rot := 0.0) -> void:
	rotation = rot
	z_index = 50
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_anim = FrameAnimator.new()
	add_child(_anim)
	_anim.setup(_sprite, sheet)
	_anim.finished.connect(func(_a): queue_free())
	_anim.play("play", false)
