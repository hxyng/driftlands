class_name Stats
extends RefCounted
## The full stat block shared by every combatant. Final stats are assembled
## additively: base + meta upgrades + equipment + in-run boons. Keeping it one
## flat, addable struct is what makes that composition trivial and testable.

var max_hp := 0.0
var attack := 0.0
var defense := 0.0
var crit_chance := 0.0   # 0..1
var crit_mult := 0.0     # damage multiplier on a crit
var move_speed := 0.0    # pixels / second
var attack_speed := 0.0  # attacks / second
var pickup_range := 0.0  # pixels
var luck := 0.0          # shifts loot rarity


static func make(hp: float, atk: float, df: float, cc: float, cm: float,
		ms: float, atkspd: float, pr: float, lk: float) -> Stats:
	var s := Stats.new()
	s.max_hp = hp
	s.attack = atk
	s.defense = df
	s.crit_chance = cc
	s.crit_mult = cm
	s.move_speed = ms
	s.attack_speed = atkspd
	s.pickup_range = pr
	s.luck = lk
	return s


static func player_base() -> Stats:
	return make(100.0, 12.0, 2.0, 0.08, 1.6, 80.0, 1.0, 30.0, 0.0)


func clone() -> Stats:
	return make(max_hp, attack, defense, crit_chance, crit_mult,
			move_speed, attack_speed, pickup_range, luck)


## Returns a new Stats that is the field-wise sum of self and [param o].
func add(o: Stats) -> Stats:
	var s := clone()
	s.max_hp += o.max_hp
	s.attack += o.attack
	s.defense += o.defense
	s.crit_chance += o.crit_chance
	s.crit_mult += o.crit_mult
	s.move_speed += o.move_speed
	s.attack_speed += o.attack_speed
	s.pickup_range += o.pickup_range
	s.luck += o.luck
	return s
