class_name AStarPathfinder
extends RefCounted
## A* shortest path over a 4-connected [Grid], backed by a binary heap.
##
## The heuristic is injectable as a [Callable] (defaults to Manhattan, which is
## admissible for 4-directional movement). A closed set with lazy stale-entry
## skipping keeps the open list correct without an explicit decrease-key.

var heuristic: Callable


func _init(custom_heuristic: Callable = Callable()) -> void:
	heuristic = custom_heuristic if custom_heuristic.is_valid() else _manhattan


## Returns the cell path from [param from] to [param to] inclusive, or an empty
## array when no path exists (or either endpoint is not passable).
func find_path(grid: Grid, from: Vector2i, to: Vector2i, passable: int = Cell.FLOOR) -> Array[Vector2i]:
	var none: Array[Vector2i] = []
	if not grid.in_bounds(from) or not grid.in_bounds(to):
		return none
	if grid.get_cellv(from) != passable or grid.get_cellv(to) != passable:
		return none

	var came := {}
	var g := {from: 0.0}
	var closed := {}
	var open := PriorityQueue.new()
	open.push(from, heuristic.call(from, to))

	while not open.is_empty():
		var current: Vector2i = open.pop()
		if current == to:
			return _reconstruct(came, current)
		if closed.has(current):
			continue
		closed[current] = true
		var current_g: float = g[current]
		for d in Grid.ORTHOGONAL:
			var n: Vector2i = current + d
			if not grid.in_bounds(n) or grid.get_cellv(n) != passable or closed.has(n):
				continue
			var tentative := current_g + 1.0
			if tentative < float(g.get(n, INF)):
				came[n] = current
				g[n] = tentative
				open.push(n, tentative + heuristic.call(n, to))
	return none


func _reconstruct(came: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came.has(current):
		current = came[current]
		path.push_front(current)
	return path


func _manhattan(a: Vector2i, b: Vector2i) -> float:
	return float(abs(a.x - b.x) + abs(a.y - b.y))
