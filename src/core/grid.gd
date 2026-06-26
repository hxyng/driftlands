class_name Grid
extends RefCounted
## A dense 2D grid of byte cells with O(1) access and cheap duplication.
##
## The grid is intentionally value-agnostic: it stores integers and knows
## nothing about [Cell] semantics. Generation and analysis layers attach
## meaning. Storage is a flat [PackedByteArray] (row-major) so a 1000x1000
## grid is ~1 MB and duplication is a single memcpy.

const ORTHOGONAL: Array[Vector2i] = [
	Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP,
]
const MOORE: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]

var width: int
var height: int
var _cells: PackedByteArray


func _init(grid_width: int, grid_height: int, fill_value: int = 0) -> void:
	width = maxi(grid_width, 0)
	height = maxi(grid_height, 0)
	_cells = PackedByteArray()
	_cells.resize(width * height)
	if fill_value != 0:
		fill(fill_value)


func index(c: Vector2i) -> int:
	return c.y * width + c.x


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


func is_border(x: int, y: int) -> bool:
	return x == 0 or y == 0 or x == width - 1 or y == height - 1


func get_cell(x: int, y: int) -> int:
	return _cells[y * width + x]


func get_cellv(c: Vector2i) -> int:
	return _cells[c.y * width + c.x]


func set_cell(x: int, y: int, value: int) -> void:
	_cells[y * width + x] = value


func set_cellv(c: Vector2i, value: int) -> void:
	_cells[c.y * width + c.x] = value


func fill(value: int) -> void:
	_cells.fill(value)


func duplicate_grid() -> Grid:
	var copy := Grid.new(width, height)
	copy._cells = _cells.duplicate()
	return copy


## Counts neighbours equal to [param value]. Out-of-bounds neighbours are
## treated as [param out_of_bounds_value] — handy for cellular automata where
## the world edge should read as solid rock.
func count_value_neighbors(
	x: int, y: int, value: int, include_diagonals: bool, out_of_bounds_value: int
) -> int:
	var dirs := MOORE if include_diagonals else ORTHOGONAL
	var count := 0
	for d in dirs:
		var nx := x + d.x
		var ny := y + d.y
		if nx < 0 or ny < 0 or nx >= width or ny >= height:
			if out_of_bounds_value == value:
				count += 1
		elif _cells[ny * width + nx] == value:
			count += 1
	return count


func cells_with_value(value: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in height:
		for x in width:
			if _cells[y * width + x] == value:
				out.append(Vector2i(x, y))
	return out
