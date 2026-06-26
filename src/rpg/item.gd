class_name Item
extends RefCounted
## An equippable item: a slot, a rarity, and a [Stats] block of modifiers it
## grants while equipped. Icons map onto the generated items atlas.

enum Slot { WEAPON, ARMOR, HELM, RING, BOOTS }

const SLOT_NAMES := {
	Slot.WEAPON: "weapon", Slot.ARMOR: "armor", Slot.HELM: "helm",
	Slot.RING: "ring", Slot.BOOTS: "boots",
}
const SLOT_ICON := {
	Slot.WEAPON: "sword", Slot.ARMOR: "shield", Slot.HELM: "helm",
	Slot.RING: "ring", Slot.BOOTS: "boots",
}

var id := ""
var display_name := ""
var slot: int = Slot.WEAPON
var rarity := "common"
var floor_found := 1
var mods: Stats


func icon_name() -> String:
	return SLOT_ICON.get(slot, "sword")


## A scalar "how good is this item" used for auto-equip comparisons.
func power() -> float:
	if mods == null:
		return 0.0
	return absf(mods.max_hp) + absf(mods.attack) * 5.0 + absf(mods.defense) * 4.0 \
		+ absf(mods.crit_chance) * 200.0 + absf(mods.attack_speed) * 120.0 \
		+ absf(mods.move_speed) + absf(mods.pickup_range) * 0.5 + absf(mods.luck) * 8.0


func color() -> Color:
	return Palette.rarity_color(rarity)


## A short, readable summary of the modifiers for tooltips.
func summary() -> String:
	if mods == null:
		return ""
	var parts: Array[String] = []
	if mods.attack != 0:
		parts.append("+%d ATK" % roundi(mods.attack))
	if mods.max_hp != 0:
		parts.append("+%d HP" % roundi(mods.max_hp))
	if mods.defense != 0:
		parts.append("+%d DEF" % roundi(mods.defense))
	if mods.crit_chance != 0:
		parts.append("+%d%% CRIT" % roundi(mods.crit_chance * 100.0))
	if mods.attack_speed != 0:
		parts.append("+%d%% ASPD" % roundi(mods.attack_speed * 100.0))
	if mods.move_speed != 0:
		parts.append("+%d SPD" % roundi(mods.move_speed))
	if mods.pickup_range != 0:
		parts.append("+%d PICKUP" % roundi(mods.pickup_range))
	if mods.luck != 0:
		parts.append("+%d LUCK" % roundi(mods.luck))
	return ", ".join(parts)
