class_name Player
extends CharacterBody2D
## The Drifter. Top-down movement with a follow camera; combat and stats are
## layered on in later milestones.

@export var speed := 80.0

var facing := 1   # 1 = right, -1 = left

var _sprite: Sprite2D
var _anim: FrameAnimator


func _ready() -> void:
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_anim = FrameAnimator.new()
	add_child(_anim)
	_anim.setup(_sprite, "player")
	_anim.play("idle")

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	col.shape = shape
	col.position = Vector2(0, 3)
	add_child(col)


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * speed
	move_and_slide()

	if dir.x < -0.1:
		facing = -1
	elif dir.x > 0.1:
		facing = 1
	_sprite.flip_h = facing < 0

	if dir.length() > 0.1:
		_anim.play("walk")
	else:
		_anim.play("idle")
