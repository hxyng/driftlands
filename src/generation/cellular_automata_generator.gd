class_name CellularAutomataGenerator
extends CaveGenerator
## Generates organic caverns via cellular automata.
##
## Step 1 seeds the grid with random walls. Step 2 repeatedly applies the
## birth/survival rule from [GenConfig], double-buffering through a snapshot so
## every cell in a pass sees the previous pass's state. Borders stay solid.

func generate(grid: Grid, rng: RandomNumberGenerator, config: GenConfig) -> void:
	_random_fill(grid, rng, config)
	for _i in config.smoothing_passes:
		_smooth(grid, config)


func _random_fill(grid: Grid, rng: RandomNumberGenerator, config: GenConfig) -> void:
	for y in grid.height:
		for x in grid.width:
			if grid.is_border(x, y):
				grid.set_cell(x, y, Cell.WALL)
			else:
				var roll := rng.randf() < config.fill_probability
				grid.set_cell(x, y, Cell.WALL if roll else Cell.FLOOR)


func _smooth(grid: Grid, config: GenConfig) -> void:
	var snapshot := grid.duplicate_grid()
	for y in grid.height:
		for x in grid.width:
			if grid.is_border(x, y):
				grid.set_cell(x, y, Cell.WALL)
				continue
			var walls := snapshot.count_value_neighbors(x, y, Cell.WALL, true, Cell.WALL)
			if walls >= config.birth_limit:
				grid.set_cell(x, y, Cell.WALL)
			elif walls < config.survival_limit:
				grid.set_cell(x, y, Cell.FLOOR)
			# Otherwise the cell keeps its previous state (already in `grid`).
