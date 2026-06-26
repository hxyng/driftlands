class_name Progression
extends RefCounted
## XP and leveling for a run. The curve is quadratic so early levels come fast
## and later ones demand real investment. Each level grants a skill point and
## fires [signal leveled_up] so the run can offer a boon choice.

signal leveled_up(level)

var level := 1
var xp := 0
var skill_points := 0


## XP required to advance FROM [param lvl] to lvl + 1.
static func xp_for_next(lvl: int) -> int:
	return 20 + (lvl - 1) * 18 + int(pow(maxi(lvl - 1, 0), 2)) * 4


func add_xp(amount: int) -> int:
	xp += maxi(amount, 0)
	var gained := 0
	while xp >= xp_for_next(level):
		xp -= xp_for_next(level)
		level += 1
		skill_points += 1
		gained += 1
		leveled_up.emit(level)
	return gained


func xp_progress() -> float:
	return clampf(float(xp) / float(xp_for_next(level)), 0.0, 1.0)
