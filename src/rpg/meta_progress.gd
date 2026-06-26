class_name MetaProgress
extends RefCounted
## Persistent meta-progression that survives death (roguelite loop).
##
## Souls are the permanent currency spent on [member upgrades]; daily claims
## track a streak by calendar date. Serialised to JSON by the [code]Game[/code]
## singleton.

var souls := 0                 # permanent currency
var best_floor := 0
var total_runs := 0
var upgrades := {}             # upgrade_id (String) -> level (int)
var daily_last_claim := ""     # "YYYY-MM-DD" of last daily reward claimed
var daily_streak := 0
var unlocked := []             # Array[String] of unlocked content ids


func upgrade_level(id: String) -> int:
	return int(upgrades.get(id, 0))


func set_upgrade_level(id: String, level: int) -> void:
	upgrades[id] = maxi(level, 0)


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


func unlock(id: String) -> void:
	if not unlocked.has(id):
		unlocked.append(id)


func to_dict() -> Dictionary:
	return {
		"souls": souls,
		"best_floor": best_floor,
		"total_runs": total_runs,
		"upgrades": upgrades,
		"daily_last_claim": daily_last_claim,
		"daily_streak": daily_streak,
		"unlocked": unlocked,
	}


func from_dict(d: Dictionary) -> void:
	souls = int(d.get("souls", 0))
	best_floor = int(d.get("best_floor", 0))
	total_runs = int(d.get("total_runs", 0))
	upgrades = d.get("upgrades", {})
	daily_last_claim = str(d.get("daily_last_claim", ""))
	daily_streak = int(d.get("daily_streak", 0))
	unlocked = d.get("unlocked", [])
