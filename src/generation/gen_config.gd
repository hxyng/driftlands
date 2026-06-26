class_name GenConfig
extends Resource
## All generation + simulation tunables in one inspector-editable resource.
##
## Nothing in the pipeline hard-codes these values — swap a different
## [GenConfig] (a .tres in the inspector, or built in code) to retune the whole
## experience without touching a line of logic. The cellular-automata rule
## itself (birth/survival thresholds) is data here, not baked into the code.

@export var grid_size := Vector2i(96, 54)

@export_group("Cellular Automata")
## Probability a non-border cell starts as wall before smoothing.
@export_range(0.0, 1.0, 0.01) var fill_probability := 0.46
## Number of smoothing passes applied after the random fill.
@export_range(0, 12) var smoothing_passes := 5
## A cell becomes wall when it has at least this many wall neighbours.
@export_range(1, 8) var birth_limit := 5
## A cell becomes floor when it has fewer than this many wall neighbours.
@export_range(1, 8) var survival_limit := 4

@export_group("Connectivity")
## Reject (and reroll) caves whose largest connected region is smaller than
## this fraction of the grid, up to [member max_attempts] tries.
@export_range(0.0, 1.0, 0.01) var min_region_fraction := 0.06
@export_range(1, 32) var max_attempts := 8

@export_group("Agent")
## Agent travel speed, in grid cells per second.
@export var agent_speed := 16.0

@export_group("Seeding")
## When true the app picks a fresh random seed on first generation; otherwise
## it uses [member seed] for reproducible output.
@export var random_seed := true
@export var seed := 0


func clone() -> GenConfig:
	return duplicate(true) as GenConfig
