class_name LootTable
extends RefCounted
## Generates equipment. Rarity is rolled from floor depth + luck; a stat budget
## (scaling with floor and rarity) is then distributed into slot-appropriate
## modifiers. Deeper floors and more luck mean better, rarer gear.

const RARITIES := ["common", "uncommon", "rare", "epic", "legendary"]
const RARITY_MULT := {
	"common": 1.0, "uncommon": 1.4, "rare": 1.9, "epic": 2.6, "legendary": 3.4,
}
const NAME_BASE := {
	Item.Slot.WEAPON: ["Dirk", "Blade", "Cleaver"],
	Item.Slot.ARMOR: ["Jerkin", "Mail", "Hauberk"],
	Item.Slot.HELM: ["Coif", "Casque", "Greathelm"],
	Item.Slot.RING: ["Band", "Loop", "Signet"],
	Item.Slot.BOOTS: ["Treads", "Greaves", "Sabatons"],
}
const NAME_PREFIX := {
	"common": "Worn", "uncommon": "Sturdy", "rare": "Runed",
	"epic": "Emberforged", "legendary": "Ashen",
}


static func roll_rarity(rng: RandomNumberGenerator, floor_num: int, luck: float) -> String:
	var t := rng.randf() + luck * 0.015 + floor_num * 0.012
	if t > 0.985:
		return "legendary"
	if t > 0.93:
		return "epic"
	if t > 0.80:
		return "rare"
	if t > 0.55:
		return "uncommon"
	return "common"


static func roll(rng: RandomNumberGenerator, floor_num: int, luck := 0.0) -> Item:
	var item := Item.new()
	item.slot = rng.randi_range(0, 4)
	item.rarity = roll_rarity(rng, floor_num, luck)
	item.floor_found = floor_num
	var budget := (4.0 + floor_num * 1.6) * float(RARITY_MULT[item.rarity])
	item.mods = _budget_to_mods(item.slot, budget, rng)
	item.display_name = "%s %s" % [NAME_PREFIX[item.rarity], _base_name(item.slot, rng)]
	item.id = "%s_%s_%d" % [item.rarity, Item.SLOT_NAMES[item.slot], rng.randi() % 100000]
	return item


static func _base_name(slot: int, rng: RandomNumberGenerator) -> String:
	var options: Array = NAME_BASE[slot]
	return options[rng.randi_range(0, options.size() - 1)]


static func _budget_to_mods(slot: int, budget: float, rng: RandomNumberGenerator) -> Stats:
	var s := Stats.new()
	match slot:
		Item.Slot.WEAPON:
			s.attack += budget * 0.9
			if rng.randf() < 0.5:
				s.crit_chance += 0.03 + budget * 0.002
		Item.Slot.ARMOR:
			s.max_hp += budget * 3.0
			s.defense += budget * 0.4
		Item.Slot.HELM:
			s.max_hp += budget * 2.0
			s.defense += budget * 0.25
			if rng.randf() < 0.4:
				s.attack += budget * 0.2
		Item.Slot.RING:
			match rng.randi_range(0, 2):
				0:
					s.crit_chance += 0.04 + budget * 0.003
				1:
					s.attack_speed += 0.08 + budget * 0.01
				_:
					s.luck += 1.0 + budget * 0.05
		Item.Slot.BOOTS:
			s.move_speed += budget * 1.6
			s.pickup_range += budget * 0.8
	return s
