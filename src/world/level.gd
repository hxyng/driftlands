class_name Level
extends Node2D
## Gameplay root: generate a floor, render it, build wall collision, and spawn
## the player with a follow camera. Enemies, loot, and the floor loop arrive in
## later milestones.

@export var floor_number := 1
@export var floor_width := 64
@export var floor_height := 40
@export var camera_zoom := 3.0

var dungeon: Dungeon
var player: Player

var _renderer: TileRenderer


func _ready() -> void:
	_generate()
	_render_floor()
	_build_wall_collision()
	_spawn_player()


func _generate() -> void:
	dungeon = Dungeon.new()
	var level_seed := int(Time.get_unix_time_from_system()) % 1000000
	dungeon.generate(floor_width, floor_height, level_seed)


func _render_floor() -> void:
	_renderer = TileRenderer.new()
	_renderer.set_dungeon(dungeon)
	add_child(_renderer)


## Greedy row-runs: each horizontal span of wall cells becomes one rectangle
## collider, so the whole floor collides with only a few dozen shapes.
func _build_wall_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "Walls"
	add_child(body)
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
			body.add_child(col)


func _spawn_player() -> void:
	player = Player.new()
	player.position = dungeon.cell_to_world_center(dungeon.spawn)
	add_child(player)

	var cam := Camera2D.new()
	cam.zoom = Vector2(camera_zoom, camera_zoom)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 9.0
	var t := Dungeon.TILE
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = dungeon.width * t
	cam.limit_bottom = dungeon.height * t
	player.add_child(cam)
	cam.make_current()
