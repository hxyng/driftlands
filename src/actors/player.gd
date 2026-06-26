class_name Player
extends CharacterBody2D
## The Drifter: movement, an arc melee attack, and the home of the run's state
## (stats, health, progression, equipment, inventory). Combat resolution and FX
## are delegated to the [Level].

signal stats_changed
signal died

const ATTACK_BASE_INTERVAL := 0.45
const ATTACK_RANGE := 30.0
const ATTACK_ARC_DOT := -1.0   # radial whirl: hits everything in range (swarm-friendly)

var base_stats: Stats
var stats: Stats
var health: Health
var progression := Progression.new()
var equipment := Equipment.new()
var inventory := Inventory.new()
var run_souls := 0

var aim := Vector2.RIGHT
var facing := 1

var _level: Level
var _sprite: Sprite2D
var _anim: FrameAnimator
var _attack_cd := 0.0
var _attacking := 0.0
var _knockback := Vector2.ZERO
var _flash := 0.0


func setup_run(level: Level) -> void:
	_level = level
	base_stats = Upgrades.apply_to(Stats.player_base(), Game.meta)
	stats = base_stats.add(equipment.total_mods())

	_sprite = Sprite2D.new()
	add_child(_sprite)
	_anim = FrameAnimator.new()
	add_child(_anim)
	_anim.setup(_sprite, "player")
	_anim.play("idle")

	health = Health.new()
	add_child(health)
	health.setup(stats.max_hp)
	health.died.connect(func(): died.emit())

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	col.shape = shape
	col.position = Vector2(0, 3)
	add_child(col)


func recompute_stats() -> void:
	var prev_max := stats.max_hp if stats else 1.0
	stats = base_stats.add(equipment.total_mods())
	if health:
		var gained := stats.max_hp - prev_max
		health.max_hp = stats.max_hp
		health.hp = clampf(health.hp + maxf(gained, 0.0), 1.0, stats.max_hp)
	stats_changed.emit()


func apply_boon(boon: Boon) -> void:
	boon.apply(base_stats)
	recompute_stats()


func gain_xp(amount: int) -> void:
	progression.add_xp(amount)


func gain_souls(amount: int) -> void:
	run_souls += amount


## Picks up an item: auto-equips it when the slot is empty or it beats the
## current piece; otherwise stashes it in the bag.
func collect_item(item: Item) -> void:
	var current := equipment.get_item(item.slot)
	if current == null or item.power() > current.power():
		var prev := equipment.equip(item)
		if prev != null:
			inventory.add(prev)
		recompute_stats()
	else:
		inventory.add(item)


## Force-equips a bag item the player chose in the inventory screen, swapping
## whatever currently occupies the slot back into the bag (no power comparison).
func equip_from_bag(item: Item) -> void:
	if not inventory.items.has(item):
		return
	inventory.remove(item)
	var prev := equipment.equip(item)
	if prev != null:
		inventory.add(prev)
	recompute_stats()


func receive_hit(damage: int, crit: bool, from_pos: Vector2) -> void:
	if health == null or health.invuln > 0.0 or not health.is_alive():
		return
	health.take_damage(damage, crit, global_position)
	health.invuln = 0.45
	_flash = 0.18
	var away := global_position - from_pos
	if away.length() < 0.01:
		away = Vector2.LEFT
	_knockback = away.normalized() * 130.0
	if _level:
		_level.spawn_damage_number(global_position + Vector2(0, -10), damage, crit)


func _physics_process(delta: float) -> void:
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_attacking = maxf(0.0, _attacking - delta)
	_flash = maxf(0.0, _flash - delta)
	_sprite.modulate = Color(2.2, 0.7, 0.6) if _flash > 0.0 else Color.WHITE

	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length() > 0.1:
		aim = dir.normalized()
		if dir.x < -0.1:
			facing = -1
		elif dir.x > 0.1:
			facing = 1
	_sprite.flip_h = facing < 0

	_knockback = _knockback.move_toward(Vector2.ZERO, 320.0 * delta)
	velocity = dir * (stats.move_speed if stats else 80.0) + _knockback
	move_and_slide()

	if Input.is_action_pressed("attack") and _attack_cd <= 0.0:
		_do_attack()

	if _attacking > 0.0:
		_anim.play("attack")
	elif dir.length() > 0.1:
		_anim.play("walk")
	else:
		_anim.play("idle")


func _do_attack() -> void:
	_attack_cd = ATTACK_BASE_INTERVAL / maxf(0.35, stats.attack_speed)
	_attacking = 0.18
	_anim.restart("attack")
	_knockback = aim * 70.0
	if _level:
		_level.player_attack(global_position, aim, stats, ATTACK_RANGE, ATTACK_ARC_DOT)
		_level.spawn_effect("slash", global_position + aim * 12.0, aim.angle())
