class_name Combat
extends RefCounted
## Stateless damage resolution. Defense uses diminishing returns so it never
## reaches full immunity, crits multiply, and a small variance roll keeps hits
## from feeling robotic. Returns the rolled damage and whether it crit.

const DEFENSE_SOFTCAP := 20.0
const VARIANCE := 0.1


static func resolve(attacker: Stats, defender: Stats, rng: RandomNumberGenerator,
		can_crit := true) -> Dictionary:
	var reduction := defender.defense / (defender.defense + DEFENSE_SOFTCAP)
	var dmg := attacker.attack * (1.0 - reduction)
	var crit := can_crit and rng.randf() < attacker.crit_chance
	if crit:
		dmg *= maxf(attacker.crit_mult, 1.0)
	dmg *= rng.randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)
	return {"damage": maxi(1, int(round(dmg))), "crit": crit}


## Average expected damage (no variance/crit) — handy for tooltips and tests.
static func expected(attacker: Stats, defender: Stats) -> float:
	var reduction := defender.defense / (defender.defense + DEFENSE_SOFTCAP)
	return maxf(1.0, attacker.attack * (1.0 - reduction))
