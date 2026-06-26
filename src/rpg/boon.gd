class_name Boon
extends RefCounted
## An in-run level-up reward. On each level the run offers a few random boons;
## the chosen one mutates the run's stat block. Effects are [Callable]s so the
## data and the behaviour live together.

var id := ""
var title := ""
var desc := ""
var effect: Callable


static func _make(id: String, title: String, desc: String, effect: Callable) -> Boon:
	var b := Boon.new()
	b.id = id
	b.title = title
	b.desc = desc
	b.effect = effect
	return b


static func pool() -> Array:
	return [
		_make("might", "Might", "+15% Attack", func(s): s.attack *= 1.15),
		_make("vigor", "Vigor", "+25 Max HP", func(s): s.max_hp += 25.0),
		_make("swift", "Swift", "+8% Move Speed", func(s): s.move_speed *= 1.08),
		_make("edge", "Keen Edge", "+5% Crit Chance", func(s): s.crit_chance += 0.05),
		_make("frenzy", "Frenzy", "+12% Attack Speed", func(s): s.attack_speed += 0.12),
		_make("ward", "Ward", "+3 Defense", func(s): s.defense += 3.0),
		_make("reach", "Long Arm", "+12 Pickup Range", func(s): s.pickup_range += 12.0),
		_make("greed", "Greed", "+2 Luck", func(s): s.luck += 2.0),
	]


## Offers [param count] distinct random boons.
static func offer(rng: RandomNumberGenerator, count := 3) -> Array:
	var p := pool()
	# Fisher-Yates with the injected rng (deterministic, unlike Array.shuffle).
	for i in range(p.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = p[i]
		p[i] = p[j]
		p[j] = tmp
	return p.slice(0, mini(count, p.size()))


func apply(stats: Stats) -> void:
	if effect.is_valid():
		effect.call(stats)
