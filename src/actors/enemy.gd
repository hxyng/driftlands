class_name Enemy
extends CharacterBody2D
## A monster that hunts the player with A* pathfinding through the dungeon and
## deals contact damage. Stats scale with floor depth. Reused for bosses with a
## scaled-up configuration.

signal died(enemy)

var kind := "slime"
var stats: Stats
var health: Health
var xp_reward := 0
var soul_reward := 0
var loot_chance := 0.1
var contact_cd := 1.0
var knock_strength := 40.0
var radius := 5.0
var is_boss := false

var _level: Level
var _sprite: Sprite2D
var _anim: FrameAnimator
var _path: Array[Vector2i] = []
var _path_i := 0
var _repath := 0.0
var _contact := 0.0
var _knockback := Vector2.ZERO
var _flash := 0.0
var _shoot_t := 2.5


func configure(kind_name: String, floor_num: int, level: Level) -> void:
	kind = kind_name
	_level = level
	var k := EnemyKinds.get_kind(kind_name)
	var hp_value := float(k["hp"]) * (1.0 + floor_num * 0.25)
	var atk_value := float(k["attack"]) * (1.0 + floor_num * 0.18)
	stats = Stats.make(hp_value, atk_value, floor_num * 0.5, 0.03, 1.5, float(k["speed"]), 1, 0, 0)
	xp_reward = int(k["xp"])
	soul_reward = int(k["souls"])
	loot_chance = float(k["loot"])
	contact_cd = float(k["contact_cd"])
	knock_strength = float(k["knock"])
	radius = float(k["radius"])

	_sprite = Sprite2D.new()
	add_child(_sprite)
	_anim = FrameAnimator.new()
	add_child(_anim)
	_anim.setup(_sprite, String(k["sprite"]))
	_anim.play(String(k["anim"]))

	health = Health.new()
	add_child(health)
	health.setup(hp_value)
	health.died.connect(_on_died)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	col.shape = shape
	add_child(col)
	add_to_group("enemies")

	is_boss = kind_name == "warden"
	if is_boss:
		_sprite.scale = Vector2(1.25, 1.25)


func boostf(scale: float) -> void:
	# Used by bosses: multiply size/visual after configure.
	_sprite.scale = Vector2(scale, scale)


func receive_hit(damage: int, crit: bool, from_pos: Vector2) -> void:
	if health == null or not health.is_alive():
		return
	health.take_damage(damage, crit, global_position)
	_flash = 0.12
	var away := (global_position - from_pos)
	if away.length() < 0.01:
		away = Vector2.RIGHT
	_knockback = away.normalized() * knock_strength * (1.8 if crit else 1.0)
	if _level:
		_level.spawn_damage_number(global_position + Vector2(0, -radius - 4), damage, crit)
		_level.spawn_effect("hit", global_position)


func _physics_process(delta: float) -> void:
	if _level == null or _level.player == null or not is_instance_valid(_level.player):
		return
	_contact = maxf(0.0, _contact - delta)
	_flash = maxf(0.0, _flash - delta)
	_sprite.modulate = Color(2.0, 1.4, 1.2) if _flash > 0.0 else Color.WHITE

	var ppos: Vector2 = _level.player.global_position
	var to_player := ppos - global_position
	var desired := Vector2.ZERO

	_repath -= delta
	if _repath <= 0.0:
		_repath = 0.35
		var from := _level.dungeon.world_to_cell(global_position)
		var to := _level.dungeon.world_to_cell(ppos)
		_path = _level.dungeon.path(from, to)
		_path_i = 0

	if to_player.length() < 26.0:
		desired = to_player.normalized()        # close enough: charge directly
	elif _path.size() > 1:
		while _path_i < _path.size() and global_position.distance_to(
				_level.dungeon.cell_to_world_center(_path[_path_i])) < 4.0:
			_path_i += 1
		if _path_i < _path.size():
			desired = (_level.dungeon.cell_to_world_center(_path[_path_i]) - global_position).normalized()
	else:
		desired = to_player.normalized()

	_knockback = _knockback.move_toward(Vector2.ZERO, 260.0 * delta)
	velocity = desired * stats.move_speed + _knockback
	move_and_slide()
	if absf(velocity.x) > 1.0:
		_sprite.flip_h = velocity.x < 0.0

	if to_player.length() < radius + 8.0 and _contact <= 0.0:
		_contact = contact_cd
		_level.enemy_hits_player(self)

	if is_boss:
		_shoot_t -= delta
		if _shoot_t <= 0.0 and to_player.length() < 160.0:
			_shoot_t = 2.4
			_flash = 0.18
			_level.boss_shoot(global_position, ppos)


func _on_died() -> void:
	died.emit(self)
	if _level:
		_level.spawn_effect("poof", global_position)
	queue_free()
