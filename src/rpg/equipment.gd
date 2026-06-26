class_name Equipment
extends RefCounted
## The five equip slots. [method total_mods] sums every equipped item's
## modifiers into one [Stats] the run adds onto its base.

var slots := {}   # Item.Slot (int) -> Item


## Equips [param item], returning whatever previously occupied its slot (or null).
func equip(item: Item) -> Item:
	var prev: Item = slots.get(item.slot, null)
	slots[item.slot] = item
	return prev


func unequip(slot: int) -> Item:
	var prev: Item = slots.get(slot, null)
	slots.erase(slot)
	return prev


func get_item(slot: int) -> Item:
	return slots.get(slot, null)


func total_mods() -> Stats:
	var s := Stats.new()
	for item in slots.values():
		if item != null and item.mods != null:
			s = s.add(item.mods)
	return s
