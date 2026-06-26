class_name Pickup
extends Node2D
## A collectible dropped by slain monsters: XP orbs, soul coins, gear, or heals.
## It pops out, then magnetises toward the player once inside pickup range and
## applies its effect on contact.

enum Kind { XP, SOUL, ITEM, HEAL }

const GRAB_RADIUS := 7.0
const MAGNET_SPEED := 150.0

var kind: int = Kind.XP
var value := 0
var item: Item

var _level: Level
var _player: Player
var _vel := Vector2.ZERO
var _magnet := false
var _t := 0.0
var _glow := Color(0, 0, 0, 0)


func setup(level: Level, pickup_kind: int, payload) -> void:
	_level = level
	kind = pickup_kind
	match kind:
		Kind.XP:
			value = int(payload)
			_make_anim("orb")
			_glow = Palette.LEAF
		Kind.SOUL:
			value = int(payload)
			_make_anim("coin")
			_glow = Palette.GOLD
		Kind.HEAL:
			value = int(payload)
			_make_icon("heart")
			_glow = Palette.BLOOD
		Kind.ITEM:
			item = payload
			_make_icon(item.icon_name())
			_glow = item.color()
	_vel = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(16, 34)
	z_index = 5


func _make_anim(sheet: String) -> void:
	var s := Sprite2D.new()
	add_child(s)
	var a := FrameAnimator.new()
	add_child(a)
	a.setup(s, sheet)
	a.play("spin")


func _make_icon(icon: String) -> void:
	var s := Sprite2D.new()
	s.texture = SpriteDB.texture("items")
	s.region_enabled = true
	s.region_rect = SpriteDB.item_region(icon)
	s.centered = true
	add_child(s)


func _process(delta: float) -> void:
	_t += delta
	if _player == null or not is_instance_valid(_player):
		_player = _level.player if _level else null
	if _player != null:
		var to := _player.global_position - global_position
		var d := to.length()
		if _magnet or d < _player.stats.pickup_range:
			_magnet = true
			_vel = to.normalized() * MAGNET_SPEED
		if d < GRAB_RADIUS:
			_collect()
			return
	if not _magnet:
		_vel = _vel.move_toward(Vector2.ZERO, 70.0 * delta)
	global_position += _vel * delta
	queue_redraw()


func _collect() -> void:
	match kind:
		Kind.XP:
			_player.gain_xp(value)
		Kind.SOUL:
			_player.gain_souls(value)
		Kind.HEAL:
			_player.health.heal(value)
		Kind.ITEM:
			_player.collect_item(item)
			_level.toast(item.display_name, item.color(), global_position)
	queue_free()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 6.0)
	draw_circle(Vector2.ZERO, 5.0 + pulse * 2.0, Color(_glow.r, _glow.g, _glow.b, 0.22))
