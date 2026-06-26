class_name CaveGenerator
extends RefCounted
## Strategy interface for level generators.
##
## A generator mutates the supplied [Grid] in place using the injected RNG and
## [GenConfig]. Swap in any subclass (cellular automata, BSP, drunkard's walk,
## Wave Function Collapse, ...) without changing [World] or the view layer.

func generate(_grid: Grid, _rng: RandomNumberGenerator, _config: GenConfig) -> void:
	push_error("CaveGenerator.generate() is abstract — override it in a subclass.")
