class_name Upgrades
extends RefCounted
## Permanent meta-upgrades bought with souls between runs. Each line has a
## capped level and a geometric cost. [method apply_to] folds the purchased
## levels into a base stat block at the start of every run.

const CATALOG := [
	{"id": "vigor", "name": "Vigor", "desc": "+15 Max HP", "max": 10, "base_cost": 40, "growth": 1.5},
	{"id": "might", "name": "Might", "desc": "+2 Attack", "max": 10, "base_cost": 50, "growth": 1.5},
	{"id": "guard", "name": "Guard", "desc": "+1 Defense", "max": 8, "base_cost": 45, "growth": 1.55},
	{"id": "edge", "name": "Edge", "desc": "+2% Crit", "max": 8, "base_cost": 60, "growth": 1.6},
	{"id": "swift", "name": "Swift", "desc": "+4 Move Speed", "max": 6, "base_cost": 55, "growth": 1.5},
	{"id": "fortune", "name": "Fortune", "desc": "+1 Luck", "max": 6, "base_cost": 70, "growth": 1.7},
]


static func by_id(id: String) -> Dictionary:
	for u in CATALOG:
		if u["id"] == id:
			return u
	return {}


## Cost to buy the next level of [param id] given the current [param level].
## Returns -1 when maxed or unknown.
static func cost(id: String, level: int) -> int:
	var u := by_id(id)
	if u.is_empty() or level >= int(u["max"]):
		return -1
	return int(round(float(u["base_cost"]) * pow(float(u["growth"]), level)))


static func purchase(meta: MetaProgress, id: String) -> bool:
	var level := meta.upgrade_level(id)
	var c := cost(id, level)
	if c < 0 or meta.souls < c:
		return false
	meta.souls -= c
	meta.set_upgrade_level(id, level + 1)
	return true


## Returns base with every purchased upgrade applied (does not mutate base).
static func apply_to(base: Stats, meta: MetaProgress) -> Stats:
	var s := base.clone()
	s.max_hp += 15.0 * meta.upgrade_level("vigor")
	s.attack += 2.0 * meta.upgrade_level("might")
	s.defense += 1.0 * meta.upgrade_level("guard")
	s.crit_chance += 0.02 * meta.upgrade_level("edge")
	s.move_speed += 4.0 * meta.upgrade_level("swift")
	s.luck += 1.0 * meta.upgrade_level("fortune")
	return s
