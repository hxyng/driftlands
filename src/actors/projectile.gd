class_name Projectile
extends Node2D
## A boss ember-orb. Flies in a straight line, damages the player on contact,
## and bursts on walls or after a short lifetime.

const GRAB := 7.0
const MAX_LIFE := 4.0

var damage := 10
var speed := 80.0

var _level: Level
var _dir := Vector2.RIGHT
var _life := 0.0
var _sprite: Sprite2D
var _anim: FrameAnimator


func setup(level: Level, dir: Vector2, dmg: int, spd := 80.0) -> void:
	_level = level
	_dir = dir.normalized()
	damage = dmg
	speed = spd
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_anim = FrameAnimator.new()
	add_child(_anim)
	_anim.setup(_sprite, "orb")
	_anim.play("spin")
	z_index = 6


func _process(delta: float) -> void:
	_life += delta
	global_position += _dir * speed * delta
	if _level == null or _level.dungeon == null:
		return
	if _level.dungeon.is_wall(_level.dungeon.world_to_cell(global_position)) or _life > MAX_LIFE:
		_burst()
		return
	var p := _level.player
	if p != null and is_instance_valid(p) and global_position.distance_to(p.global_position) < GRAB:
		p.receive_hit(damage, false, global_position)
		_burst()


func _burst() -> void:
	if _level:
		_level.spawn_effect("hit", global_position)
	queue_free()
