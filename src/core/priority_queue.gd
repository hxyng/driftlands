class_name PriorityQueue
extends RefCounted
## A binary min-heap priority queue (lowest priority pops first).
##
## Generic over the item type — each entry is a [priority, item] pair, ordered
## by priority. Push/pop are O(log n), which is what lets [AStarPathfinder]
## scale to large grids instead of the O(n) linear scan a naive open-list uses.

var _heap: Array = []


func is_empty() -> bool:
	return _heap.is_empty()


func size() -> int:
	return _heap.size()


func push(item: Variant, priority: float) -> void:
	_heap.append([priority, item])
	_sift_up(_heap.size() - 1)


## Removes and returns the item with the lowest priority. Caller must ensure
## the queue is non-empty.
func pop() -> Variant:
	var top: Array = _heap[0]
	var last: Array = _heap.pop_back()
	if not _heap.is_empty():
		_heap[0] = last
		_sift_down(0)
	return top[1]


func _sift_up(i: int) -> void:
	while i > 0:
		var parent := (i - 1) >> 1
		if _heap[i][0] < _heap[parent][0]:
			_swap(i, parent)
			i = parent
		else:
			return


func _sift_down(i: int) -> void:
	var n := _heap.size()
	while true:
		var smallest := i
		var left := 2 * i + 1
		var right := 2 * i + 2
		if left < n and _heap[left][0] < _heap[smallest][0]:
			smallest = left
		if right < n and _heap[right][0] < _heap[smallest][0]:
			smallest = right
		if smallest == i:
			return
		_swap(i, smallest)
		i = smallest


func _swap(a: int, b: int) -> void:
	var tmp: Array = _heap[a]
	_heap[a] = _heap[b]
	_heap[b] = tmp
