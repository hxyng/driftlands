class_name Level
extends Node2D
## Gameplay root (milestone 1: generate + show a floor).
##
## Generates a dungeon, renders it, and frames it with a fitted camera. Later
## milestones add the player, enemies, loot, and a follow camera — this is the
## skeleton everything hangs off.

const VIEW := Vector2(480, 270)

@export var floor_number := 1
@export var floor_width := 64
@export var floor_height := 40

var dungeon: Dungeon
var _renderer: TileRenderer
var _camera: Camera2D


func _ready() -> void:
	_generate()
	_build_view()


func _generate() -> void:
	dungeon = Dungeon.new()
	var level_seed := int(Time.get_unix_time_from_system()) % 1000000
	dungeon.generate(floor_width, floor_height, level_seed)


func _build_view() -> void:
	_renderer = TileRenderer.new()
	_renderer.set_dungeon(dungeon)
	add_child(_renderer)

	_camera = Camera2D.new()
	_camera.position = dungeon.pixel_size() * 0.5
	var fit := minf(VIEW.x / dungeon.pixel_size().x, VIEW.y / dungeon.pixel_size().y)
	_camera.zoom = Vector2(fit, fit) * 0.96
	add_child(_camera)
	_camera.make_current()
