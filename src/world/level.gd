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
var _ui_layer: CanvasLayer
var _rng := RandomNumberGenerator.new()
var _transitioning := false
var _boon_queue := 0
var _boon_active := false
var _pause_menu: PauseMenu
var _inv_screen: InventoryScreen
var _dead := false
var _boss: Enemy


func _ready() -> void:
	_rng.randomize()
	_generate()
	_render_floor()
	_build_wall_collision()
	_spawn_player()
	_spawn_enemies()
	_build_hud()


func _process(_delta: float) -> void:
	if _transitioning or _dead or player == null or dungeon == null:
		return
	if dungeon.world_to_cell(player.global_position) == dungeon.exit:
		_next_floor()


func _unhandled_input(event: InputEvent) -> void:
	if _dead or _boon_active:
		return
	if event.is_action_pressed("pause"):
		_open_pause()
	elif event.is_action_pressed("inventory"):
		_open_inventory()


func _open_inventory() -> void:
	if is_instance_valid(_inv_screen) or _ui_layer == null or player == null:
		return
	_inv_screen = InventoryScreen.new()
	_ui_layer.add_child(_inv_screen)
	_inv_screen.open(player)


func _open_pause() -> void:
	if is_instance_valid(_pause_menu) or _ui_layer == null:
		return
	_pause_menu = PauseMenu.new()
	_ui_layer.add_child(_pause_menu)
	_pause_menu.abandoned.connect(_abandon_run)
	_pause_menu.open()


func _abandon_run() -> void:
	_bank_run()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _bank_run() -> void:
	Game.meta.souls += player.run_souls
	Game.meta.best_floor = maxi(Game.meta.best_floor, floor_number)
	Game.meta.total_runs += 1
	Game.save_meta()


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
	if floor_number % 5 == 0:
		_spawn_boss()
		_spawn_minions(4)
		return
	_spawn_minions(6 + floor_number * 2)


func _spawn_minions(count: int) -> void:
	var roster := EnemyKinds.roster_for_floor(floor_number)
	for _i in count:
		var cell := dungeon.random_floor_far_from_spawn(_rng, 4)
		var e := Enemy.new()
		e.configure(roster[_rng.randi_range(0, roster.size() - 1)], floor_number, self)
		e.position = dungeon.cell_to_world_center(cell)
		e.died.connect(_on_enemy_died)
		add_child(e)
		enemies.append(e)


func _spawn_boss() -> void:
	var e := Enemy.new()
	e.configure("warden", floor_number, self)
	e.position = dungeon.cell_to_world_center(dungeon.random_floor_far_from_spawn(_rng, 10))
	e.died.connect(_on_enemy_died)
	e.died.connect(_on_boss_died)
	add_child(e)
	enemies.append(e)
	_boss = e
	if _hud:
		_hud.boss = e


func boss_shoot(origin: Vector2, target: Vector2) -> void:
	var base := target - origin
	if base.length() < 0.01:
		base = Vector2.RIGHT
	base = base.normalized()
	for a in [-0.28, 0.0, 0.28]:
		var pr := Projectile.new()
		add_child(pr)
		pr.global_position = origin
		pr.setup(self, base.rotated(a), int(8 + floor_number * 1.5), 84.0)
	_shaker.add(2.0)


func _next_floor() -> void:
	_transitioning = true
	floor_number += 1
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	_boss = null
	if _hud:
		_hud.boss = null
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
	_hud.boss = _boss
	layer.add_child(_hud)

	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 20
	add_child(_ui_layer)


func spawn_pickup(kind: int, pos: Vector2, payload) -> void:
	var p := Pickup.new()
	add_child(p)
	p.global_position = pos
	p.setup(self, kind, payload)


func toast(text: String, color: Color, pos: Vector2) -> void:
	var dn := DamageNumber.new()
	dn.setup_text(text, color)
	add_child(dn)
	dn.global_position = pos + Vector2(0, -14)


func _show_next_boon() -> void:
	if _boon_active or _boon_queue <= 0 or _ui_layer == null:
		return
	_boon_active = true
	_boon_queue -= 1
	var screen := BoonScreen.new()
	_ui_layer.add_child(screen)
	screen.chosen.connect(_on_boon_chosen)
	screen.present(Boon.offer(_rng, 3))


func _on_boon_chosen(boon) -> void:
	player.apply_boon(boon)
	_boon_active = false
	toast(boon.title + "!", Palette.GOLD, player.global_position)
	_show_next_boon()


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
	var pos := e.global_position
	spawn_pickup(Pickup.Kind.XP, pos, e.xp_reward)
	if _rng.randf() < 0.55:
		spawn_pickup(Pickup.Kind.SOUL, pos + Vector2(_rng.randf_range(-5, 5), 0), e.soul_reward)
	if _rng.randf() < 0.08:
		spawn_pickup(Pickup.Kind.HEAL, pos, 18)
	if _rng.randf() < e.loot_chance:
		spawn_pickup(Pickup.Kind.ITEM, pos, LootTable.roll(_rng, floor_number, player.stats.luck))


func _on_boss_died(e: Enemy) -> void:
	_boss = null
	if _hud:
		_hud.boss = null
	var pos := e.global_position
	spawn_pickup(Pickup.Kind.ITEM, pos, LootTable.roll(_rng, floor_number + 5, player.stats.luck + 12.0))
	spawn_pickup(Pickup.Kind.SOUL, pos, 40)
	for _i in 6:
		var off := Vector2(_rng.randf_range(-12, 12), _rng.randf_range(-12, 12))
		spawn_pickup(Pickup.Kind.XP, pos + off, 22)
	toast("WARDEN SLAIN", Palette.GOLD, pos + Vector2(0, -18))
	_shaker.add(6.0)


func _on_player_leveled(_level_num: int) -> void:
	if player.health:
		player.health.heal(player.health.max_hp * 0.25)
	_shaker.add(1.5)
	_boon_queue += 1
	_show_next_boon()


func _on_player_died() -> void:
	if _dead:
		return
	_dead = true
	_bank_run()
	_show_game_over()
	await get_tree().create_timer(2.6).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _show_game_over() -> void:
	if _ui_layer == null:
		return
	var over := Control.new()
	over.process_mode = Node.PROCESS_MODE_ALWAYS
	over.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.02, 0.02, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	over.add_child(bg)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	over.add_child(cc)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	cc.add_child(col)
	col.add_child(UiTheme.center_label("YOU DIED", 30, Palette.BLOOD))
	col.add_child(UiTheme.center_label(
		"Floor %d  -  %d souls banked" % [floor_number, player.run_souls], 11, Palette.BONE))
	_ui_layer.add_child(over)
