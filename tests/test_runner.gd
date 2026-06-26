extends SceneTree
## Headless test suite for the RPG core (run via
## `godot --headless --script res://tests/test_runner.gd`). Exit code gates CI.
## Pure logic only — no nodes, no rendering.

var _passed := 0
var _failed := 0
var _failures: Array[String] = []


func _init() -> void:
	print("DriftLands core tests...")
	_test_stats()
	_test_combat()
	_test_progression()
	_test_loot()
	_test_equipment()
	_test_daily()
	_test_upgrades()
	_test_boons()
	_report()
	quit(1 if _failed > 0 else 0)


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		_failures.append(label)


func _report() -> void:
	for f in _failures:
		printerr("  FAIL  ", f)
	print("=== %d passed, %d failed ===" % [_passed, _failed])


func _mod_total(s: Stats) -> float:
	return absf(s.max_hp) + absf(s.attack) + absf(s.defense) + absf(s.crit_chance) * 100.0 \
		+ absf(s.attack_speed) * 50.0 + absf(s.move_speed) + absf(s.pickup_range) + absf(s.luck) * 5.0


func _test_stats() -> void:
	var a := Stats.make(100, 10, 2, 0.1, 1.5, 80, 1, 30, 0)
	var b := Stats.make(20, 5, 1, 0.05, 0, 0, 0.1, 0, 1)
	var c := a.add(b)
	_check(c.max_hp == 120 and c.attack == 15 and c.defense == 3, "stats add field-wise")
	_check(a.max_hp == 100 and a.attack == 10, "add does not mutate operands")
	var d := a.clone()
	d.attack = 99
	_check(a.attack == 10, "clone is independent")


func _test_combat() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var atk := Stats.make(0, 50, 0, 0, 1.5, 0, 0, 0, 0)
	var defn := Stats.make(0, 0, 20, 0, 0, 0, 0, 0, 0)
	_check(absf(Combat.expected(atk, defn) - 25.0) < 0.001, "defense softcap halves dmg at def=20")
	var r := Combat.resolve(atk, defn, rng, false)
	_check(r["damage"] >= 1, "damage is at least 1")
	_check(r["crit"] == false, "no crit at 0% chance")


func _test_progression() -> void:
	_check(Progression.xp_for_next(1) == 20, "first level needs 20 xp")
	var p := Progression.new()
	var gained := p.add_xp(20)
	_check(gained == 1 and p.level == 2 and p.skill_points == 1, "level up grants a skill point")
	var p2 := Progression.new()
	var g := p2.add_xp(10000)
	_check(p2.level > 5 and g == p2.level - 1, "big xp grants multiple levels")
	_check(p2.xp < Progression.xp_for_next(p2.level), "leftover xp stays below next threshold")


func _test_loot() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var low := LootTable.roll(rng, 1, 0)
	_check(low.mods != null, "rolled item has modifiers")
	_check(LootTable.RARITIES.has(low.rarity), "rarity is valid")
	var sum_low := 0.0
	var sum_high := 0.0
	for _i in 200:
		sum_low += _mod_total(LootTable.roll(rng, 1, 0).mods)
		sum_high += _mod_total(LootTable.roll(rng, 20, 3).mods)
	_check(sum_high > sum_low * 1.5, "deeper floors + luck yield stronger loot")


func _test_equipment() -> void:
	var eq := Equipment.new()
	var w := Item.new()
	w.slot = Item.Slot.WEAPON
	w.mods = Stats.make(0, 10, 0, 0, 0, 0, 0, 0, 0)
	var armor := Item.new()
	armor.slot = Item.Slot.ARMOR
	armor.mods = Stats.make(50, 0, 5, 0, 0, 0, 0, 0, 0)
	eq.equip(w)
	eq.equip(armor)
	var tm := eq.total_mods()
	_check(tm.attack == 10 and tm.max_hp == 50 and tm.defense == 5, "equipment sums modifiers")
	var w2 := Item.new()
	w2.slot = Item.Slot.WEAPON
	w2.mods = Stats.make(0, 20, 0, 0, 0, 0, 0, 0, 0)
	var prev := eq.equip(w2)
	_check(prev == w, "equipping a slot returns the replaced item")
	_check(eq.total_mods().attack == 20, "replacement updates the total")


func _test_daily() -> void:
	var m := MetaProgress.new()
	var r1 := Daily.claim(m, "2026-06-25")
	_check(r1["claimed"] and m.daily_streak == 1 and m.souls == 35, "first claim pays base + streak")
	_check(not Daily.claim(m, "2026-06-25")["claimed"], "cannot claim twice in one day")
	var r2 := Daily.claim(m, "2026-06-26")
	_check(r2["claimed"] and m.daily_streak == 2, "consecutive day grows the streak")
	var r3 := Daily.claim(m, "2026-06-29")
	_check(r3["claimed"] and m.daily_streak == 1, "a missed day resets the streak")


func _test_upgrades() -> void:
	_check(Upgrades.cost("might", 0) == 50, "first Might level costs 50")
	_check(Upgrades.cost("might", 1) == 75, "second Might level costs 75")
	var m := MetaProgress.new()
	m.souls = 1000
	var ok := Upgrades.purchase(m, "might")
	_check(ok and m.upgrade_level("might") == 1 and m.souls == 950, "purchase deducts souls")
	m.set_upgrade_level("might", 3)
	var applied := Upgrades.apply_to(Stats.player_base(), m)
	_check(applied.attack == Stats.player_base().attack + 6.0, "Might applies +2 attack per level")
	var poor := MetaProgress.new()
	poor.souls = 10
	_check(not Upgrades.purchase(poor, "might"), "cannot purchase without enough souls")


func _test_boons() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var offered := Boon.offer(rng, 3)
	_check(offered.size() == 3, "offers the requested number of boons")
	var ids := {}
	for b in offered:
		ids[b.id] = true
	_check(ids.size() == 3, "offered boons are distinct")
	var s := Stats.make(0, 100, 0, 0, 0, 0, 0, 0, 0)
	for b in Boon.pool():
		if b.id == "might":
			b.apply(s)
	_check(absf(s.attack - 115.0) < 0.001, "Might boon multiplies attack by 1.15")
