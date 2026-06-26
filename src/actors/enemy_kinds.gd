class_name EnemyKinds
extends RefCounted
## Data-driven monster roster. Base stats here are scaled by floor depth when an
## enemy is spawned, so the same kinds stay relevant deeper in.

const KINDS := {
	"slime": {
		"sprite": "slime", "anim": "move", "hp": 18.0, "attack": 6.0, "speed": 44.0,
		"contact_cd": 0.9, "xp": 6, "souls": 2, "radius": 5.0, "knock": 42.0, "loot": 0.10,
	},
	"bat": {
		"sprite": "bat", "anim": "fly", "hp": 10.0, "attack": 5.0, "speed": 72.0,
		"contact_cd": 0.7, "xp": 7, "souls": 2, "radius": 4.0, "knock": 30.0, "loot": 0.10,
	},
	"skeleton": {
		"sprite": "skeleton", "anim": "walk", "hp": 30.0, "attack": 10.0, "speed": 54.0,
		"contact_cd": 1.0, "xp": 12, "souls": 4, "radius": 5.0, "knock": 56.0, "loot": 0.16,
	},
	"warden": {
		"sprite": "boss", "anim": "idle", "hp": 220.0, "attack": 16.0, "speed": 30.0,
		"contact_cd": 1.1, "xp": 80, "souls": 30, "radius": 11.0, "knock": 80.0, "loot": 1.0,
	},
}


static func get_kind(name: String) -> Dictionary:
	return KINDS.get(name, KINDS["slime"])


## Which kinds can spawn on a given floor (variety grows with depth).
static func roster_for_floor(floor_num: int) -> Array:
	if floor_num <= 1:
		return ["slime"]
	if floor_num <= 3:
		return ["slime", "bat"]
	return ["slime", "bat", "skeleton"]
