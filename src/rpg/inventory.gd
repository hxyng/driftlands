class_name Inventory
extends RefCounted
## A simple bag of collected (unequipped) items plus carried gold.

var items: Array[Item] = []
var gold := 0


func add(item: Item) -> void:
	items.append(item)


func remove(item: Item) -> void:
	items.erase(item)


func size() -> int:
	return items.size()
