class_name DistanceField
extends RefCounted
## Breadth-first distance from a source over passable cells.
##
## One BFS yields two things at once: the shading gradient (how deep each cell
## is) and the most interesting goal (the farthest reachable cell). Distances
## are stored flat for O(1) lookup; unreached cells are -1.

var width: int
var height: int
var distances: PackedInt32Array
var max_distance: int = 1
var farthest: Vector2i


static func compute(grid: Grid, source: Vector2i, passable: int = Cell.FLOOR) -> DistanceField:
	var df := DistanceField.new()
	df.width = grid.width
	df.height = grid.height
	df.distances = PackedInt32Array()
	df.distances.resize(grid.width * grid.height)
	df.distances.fill(-1)
	df.farthest = source

	var frontier: Array[Vector2i] = [source]
	df.distances[grid.index(source)] = 0
	var head := 0
	var furthest := 0
	while head < frontier.size():
		var c: Vector2i = frontier[head]
		head += 1
		var cd := df.distances[grid.index(c)]
		if cd > furthest:
			furthest = cd
			df.farthest = c
		for d in Grid.ORTHOGONAL:
			var n: Vector2i = c + d
			if grid.in_bounds(n) and grid.get_cellv(n) == passable \
					and df.distances[grid.index(n)] == -1:
				df.distances[grid.index(n)] = cd + 1
				frontier.append(n)

	df.max_distance = maxi(furthest, 1)
	return df


func at(c: Vector2i) -> int:
	return distances[c.y * width + c.x]


## Returns reachability in [0, 1], or -1.0 if the cell was never reached.
func normalized(c: Vector2i) -> float:
	var d := at(c)
	return -1.0 if d < 0 else float(d) / float(max_distance)
