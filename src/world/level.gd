class_name Level
extends Node2D
## Gameplay orchestrator: generates floors, spawns the player and monsters,
## resolves combat, spawns FX, advances floors at the stairs, and banks souls on
## death. The hub every system plugs into.

@export var floor_width := 64
@export var floor_height := 40
@export var camera_zoom := 3.0

var floor_number := 1
var dungeon: Dungeon
var player: Player
var enemies: Array[Enemy] = []

var _renderer: TileRenderer
var _walls: StaticBody2D
var _camera: Camera2D
var _shaker: Shaker
var _hud: Hud
var _rng := RandomNumberGenerator.new()
var _transitioning := false


func _ready() -> void:
	_rng.randomize()
	_generate()
	_render_floor()
	_build_wall_collision()
	_spawn_player()
	_spawn_enemies()
	_build_hud()


func _process(_delta: float) -> void:
	if _transitioning or player == null or dungeon == null:
		return
	if dungeon.world_to_cell(player.global_position) == dungeon.exit:
		_next_floor()


# ---- Floor lifecycle -------------------------------------------------------
func _generate() -> void:
	dungeon = Dungeon.new()
	dungeon.generate(floor_width, floor_height, _rng.randi() % 1000000)


func _render_floor() -> void:
	_renderer = TileRenderer.new()
	_renderer.set_dungeon(dungeon)
	add_child(_renderer)


func _build_wall_collision() -> void:
	_walls = StaticBody2D.new()
	_walls.name = "Walls"
	add_child(_walls)
	var t := Dungeon.TILE
	for y in dungeon.height:
		var x := 0
		while x < dungeon.width:
			if dungeon.grid.get_cell(x, y) != Cell.WALL:
				x += 1
				continue
			var start := x
			while x < dungeon.width and dungeon.grid.get_cell(x, y) == Cell.WALL:
				x += 1
			var span := x - start
			var col := CollisionShape2D.new()
			var shape := RectangleShape2D.new()
			shape.size = Vector2(span * t, t)
			col.shape = shape
			col.position = Vector2((start + span * 0.5) * t, (y + 0.5) * t)
			_walls.add_child(col)


func _spawn_player() -> void:
	player = Player.new()
	player.setup_run(self)
	player.position = dungeon.cell_to_world_center(dungeon.spawn)
	add_child(player)
	player.progression.leveled_up.connect(_on_player_leveled)
	player.died.connect(_on_player_died)

	_camera = Camera2D.new()
	_camera.zoom = Vector2(camera_zoom, camera_zoom)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 9.0
	_apply_camera_limits()
	player.add_child(_camera)
	_camera.make_current()

	_shaker = Shaker.new()
	_shaker.camera = _camera
	add_child(_shaker)


func _apply_camera_limits() -> void:
	var t := Dungeon.TILE
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = dungeon.width * t
	_camera.limit_bottom = dungeon.height * t


func _spawn_enemies() -> void:
	var roster := EnemyKinds.roster_for_floor(floor_number)
	var count := 6 + floor_number * 2
	for _i in count:
		var cell := dungeon.random_floor_far_from_spawn(_rng, 4)
		var e := Enemy.new()
		e.configure(roster[_rng.randi_range(0, roster.size() - 1)], floor_number, self)
		e.position = dungeon.cell_to_world_center(cell)
		e.died.connect(_on_enemy_died)
		add_child(e)
		enemies.append(e)


func _next_floor() -> void:
	_transitioning = true
	floor_number += 1
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	if is_instance_valid(_renderer):
		_renderer.queue_free()
	if is_instance_valid(_walls):
		_walls.queue_free()

	_generate()
	_render_floor()
	_build_wall_collision()
	player.global_position = dungeon.cell_to_world_center(dungeon.spawn)
	_apply_camera_limits()
	_spawn_enemies()
	if _hud:
		_hud.floor_number = floor_number
	_shaker.add(3.0)
	_transitioning = false


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_hud = Hud.new()
	_hud.player = player
	_hud.floor_number = floor_number
	layer.add_child(_hud)


# ---- Combat API (called by actors) -----------------------------------------
func player_attack(origin: Vector2, aim: Vector2, attacker: Stats, attack_range: float, arc_dot: float) -> void:
	var hit := false
	for e in enemies.duplicate():
		if not is_instance_valid(e):
			continue
		var to: Vector2 = e.global_position - origin
		var d := to.length()
		if d <= attack_range and (d < 1.0 or aim.dot(to / d) >= arc_dot):
			var res := Combat.resolve(attacker, e.stats, _rng, true)
			e.receive_hit(res["damage"], res["crit"], origin)
			hit = true
	if hit:
		_shaker.add(2.0)


func enemy_hits_player(e: Enemy) -> void:
	if player == null:
		return
	var res := Combat.resolve(e.stats, player.stats, _rng, false)
	player.receive_hit(res["damage"], res["crit"], e.global_position)
	_shaker.add(3.0)


func spawn_damage_number(pos: Vector2, amount: int, crit: bool) -> void:
	var dn := DamageNumber.new()
	dn.setup(amount, crit)
	add_child(dn)
	dn.global_position = pos


func spawn_effect(sheet: String, pos: Vector2, rot := 0.0) -> void:
	var fx := Effect.new()
	add_child(fx)
	fx.global_position = pos
	fx.play(sheet, rot)


func shake(amount: float) -> void:
	if _shaker:
		_shaker.add(amount)


# ---- Reward / lifecycle hooks ----------------------------------------------
func _on_enemy_died(e: Enemy) -> void:
	enemies.erase(e)
	player.run_souls += e.soul_reward
	player.progression.add_xp(e.xp_reward)


func _on_player_leveled(_level_num: int) -> void:
	if player.health:
		player.health.heal(player.health.max_hp * 0.25)
	_shaker.add(1.5)


func _on_player_died() -> void:
	Game.meta.souls += player.run_souls
	Game.meta.best_floor = maxi(Game.meta.best_floor, floor_number)
	Game.meta.total_runs += 1
	Game.save_meta()
	await get_tree().create_timer(1.3).timeout
	get_tree().reload_current_scene()
