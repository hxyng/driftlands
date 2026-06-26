class_name TileRenderer
extends Node2D
## Draws a [Dungeon]'s tiles. Static (redraws only when the dungeon changes).
##
## Until the sprite atlas lands this paints with the palette directly: dithered
## stone floors with moss flecks and contact shadows, walls with a lit top edge
## and shaded base for a sense of height. Swappable for atlas tiles later.

var dungeon: Dungeon
var atlas: Texture2D            # optional; when set, tiles are blitted from it


func set_dungeon(d: Dungeon) -> void:
	dungeon = d
	queue_redraw()


func _draw() -> void:
	if dungeon == null:
		return
	var t := Dungeon.TILE
	draw_rect(Rect2(Vector2.ZERO, dungeon.pixel_size()), Palette.INK)
	for y in dungeon.height:
		for x in dungeon.width:
			var cell := Vector2i(x, y)
			var rect := Rect2(x * t, y * t, t, t)
			if dungeon.grid.get_cell(x, y) == Cell.WALL:
				_draw_wall(cell, rect, t)
			else:
				_draw_floor(cell, rect, t)
	_draw_exit(t)


func _draw_floor(cell: Vector2i, rect: Rect2, t: int) -> void:
	var h := (cell.x * 7 + cell.y * 13) % 9
	var base := Palette.STONE_DARK
	if h == 0:
		base = Palette.STONE_DARK.lerp(Palette.STONE, 0.6)
	elif h == 1:
		base = Palette.STONE_DARK.lerp(Palette.MOSS_DARK, 0.55)
	draw_rect(rect, base)
	if h == 4:  # sparse moss fleck
		draw_rect(Rect2(rect.position + Vector2(t * 0.3, t * 0.3), Vector2(t * 0.3, t * 0.3)),
				Palette.MOSS_DARK)
	if dungeon.is_wall(cell + Vector2i.UP):  # contact shadow under walls
		draw_rect(Rect2(rect.position, Vector2(t, 3)), Palette.INK.lerp(base, 0.35))


func _draw_wall(cell: Vector2i, rect: Rect2, t: int) -> void:
	draw_rect(rect, Palette.STONE)
	draw_rect(Rect2(rect.position, Vector2(t, 2)), Palette.STONE_LIT)
	draw_rect(Rect2(rect.position + Vector2(0, t - 2), Vector2(t, 2)), Palette.STONE_DARK)
	if dungeon.is_floor(cell + Vector2i.DOWN):  # face toward camera, lit a touch more
		draw_rect(Rect2(rect.position + Vector2(0, t - 5), Vector2(t, 3)), Palette.STONE_DARK)


func _draw_exit(t: int) -> void:
	var c := dungeon.cell_to_world_center(dungeon.exit)
	draw_circle(c, t * 0.42, Palette.GOLD)
	draw_circle(c, t * 0.24, Palette.INK)
	draw_circle(c, t * 0.10, Palette.GOLD)
