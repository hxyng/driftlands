class_name TileRenderer
extends Node2D
## Draws a [Dungeon]'s tiles from the generated atlas (assets/sprites/tiles.png).
## Static — redraws only when the dungeon changes. Floor variant is chosen by a
## stable per-cell hash; walls get a contact shadow on the floor below them.

const FLOOR_VARIANTS := 4
const IDX_WALL := 4
const IDX_STAIRS := 6

var dungeon: Dungeon
var _atlas: Texture2D


func set_dungeon(d: Dungeon) -> void:
	dungeon = d
	_atlas = SpriteDB.texture("tiles")
	queue_redraw()


func _draw() -> void:
	if dungeon == null or _atlas == null:
		return
	var t := Dungeon.TILE
	draw_rect(Rect2(Vector2.ZERO, dungeon.pixel_size()), Palette.INK)
	for y in dungeon.height:
		for x in dungeon.width:
			var cell := Vector2i(x, y)
			if dungeon.grid.get_cell(x, y) == Cell.WALL:
				_tile(x, y, IDX_WALL, t)
			else:
				_tile(x, y, (x * 7 + y * 13) % FLOOR_VARIANTS, t)
				if dungeon.is_wall(cell + Vector2i.UP):
					draw_rect(Rect2(x * t, y * t, t, 3), Color(0, 0, 0, 0.28))
	_tile(dungeon.exit.x, dungeon.exit.y, IDX_STAIRS, t)


func _tile(cx: int, cy: int, index: int, t: int) -> void:
	draw_texture_rect_region(_atlas, Rect2(cx * t, cy * t, t, t), Rect2(index * 16, 0, 16, 16))
