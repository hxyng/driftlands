class_name Dungeon
extends RefCounted
## A single dungeon floor: a generated, guaranteed-connected cave plus the
## queries gameplay needs (wall tests, spawn/exit, world<->cell conversion).
##
## Reuses the DriftCaves pipeline — cellular automata, largest-region flood
## fill, BFS — but frames the result as a playable level: the spawn is near a
## corner and the exit (stairs) is the farthest reachable cell, so every floor
## is a real journey across the map.

const TILE := 16

var grid: Grid
var width: int
var height: int
var seed: int
var spawn: Vector2i
var exit: Vector2i
var floor_cells: Array[Vector2i] = []
var dist_from_spawn: DistanceField

var _generator := CellularAutomataGenerator.new()
var _pathfinder := AStarPathfinder.new()


func generate(w: int, h: int, level_seed: int, config: GenConfig = null) -> void:
	width = w
	height = h
	seed = level_seed
	var cfg := config if config != null else default_config()
	cfg.grid_size = Vector2i(w, h)

	var rng := RandomNumberGenerator.new()
	var min_cells := int(w * h * cfg.min_region_fraction)
	var s := level_seed
	for _attempt in cfg.max_attempts:
		rng.seed = s
		grid = Grid.new(w, h, Cell.WALL)
		_generator.generate(grid, rng, cfg)
		RegionExtractor.keep_largest(grid, Cell.FLOOR, Cell.WALL)
		floor_cells = grid.cells_with_value(Cell.FLOOR)
		if floor_cells.size() >= min_cells:
			break
		s = (s + 7919) % 1000000
	seed = s

	spawn = _floor_nearest_corner()
	dist_from_spawn = DistanceField.compute(grid, spawn, Cell.FLOOR)
	exit = dist_from_spawn.farthest


static func default_config() -> GenConfig:
	var cfg := GenConfig.new()
	cfg.fill_probability = 0.46
	cfg.smoothing_passes = 4
	cfg.birth_limit = 5
	cfg.survival_limit = 4
	cfg.min_region_fraction = 0.10
	cfg.max_attempts = 12
	return cfg


func is_wall(cell: Vector2i) -> bool:
	return not grid.in_bounds(cell) or grid.get_cellv(cell) == Cell.WALL


func is_floor(cell: Vector2i) -> bool:
	return grid.in_bounds(cell) and grid.get_cellv(cell) == Cell.FLOOR


func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / TILE)), int(floor(pos.y / TILE)))


func cell_to_world_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x + 0.5, cell.y + 0.5) * TILE


func pixel_size() -> Vector2:
	return Vector2(width, height) * TILE


## A* path of cells from one floor tile to another (empty if unreachable).
func path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	return _pathfinder.find_path(grid, from, to, Cell.FLOOR)


## A random floor cell at least `min_distance` cells (by path) from the spawn —
## used to place enemies and loot away from where the player appears.
func random_floor_far_from_spawn(rng: RandomNumberGenerator, min_distance: int) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for c in floor_cells:
		if dist_from_spawn.at(c) >= min_distance:
			candidates.append(c)
	if candidates.is_empty():
		candidates = floor_cells
	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _floor_nearest_corner() -> Vector2i:
	var best := floor_cells[0]
	var best_score := best.x + best.y
	for c in floor_cells:
		var score := c.x + c.y
		if score < best_score:
			best_score = score
			best = c
	return best
