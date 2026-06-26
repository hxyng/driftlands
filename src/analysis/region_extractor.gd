class_name RegionExtractor
extends RefCounted
## Connectivity cleanup via flood fill.
##
## Finds every connected region of [param target] cells, keeps only the
## largest, and overwrites the rest with [param fill]. This guarantees the
## generated cave is a single reachable space — no orphan pockets the agent
## could never get to.

## Returns the size (in cells) of the region that was kept.
static func keep_largest(grid: Grid, target: int = Cell.FLOOR, fill: int = Cell.WALL) -> int:
	var visited := {}
	var best: Array[Vector2i] = []
	for y in grid.height:
		for x in grid.width:
			var c := Vector2i(x, y)
			if grid.get_cellv(c) == target and not visited.has(c):
				var region := _flood(grid, c, target, visited)
				if region.size() > best.size():
					best = region
	grid.fill(fill)
	for c in best:
		grid.set_cellv(c, target)
	return best.size()


static func _flood(
	grid: Grid, source: Vector2i, target: int, visited: Dictionary
) -> Array[Vector2i]:
	var region: Array[Vector2i] = []
	var stack: Array[Vector2i] = [source]
	visited[source] = true
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		region.append(c)
		for d in Grid.ORTHOGONAL:
			var n: Vector2i = c + d
			if grid.in_bounds(n) and grid.get_cellv(n) == target and not visited.has(n):
				visited[n] = true
				stack.append(n)
	return region
