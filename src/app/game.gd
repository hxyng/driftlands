extends Node
## Global singleton (autoloaded as `Game`).
##
## Owns input binding and the persistent meta-progression that survives between
## runs (soul currency, permanent stat upgrades, daily unlocks). Per-run state
## lives in the gameplay scenes; this is the layer that outlives death.

signal meta_changed

const SAVE_PATH := "user://driftlands_save.json"

var meta := MetaProgress.new()


func _ready() -> void:
	_setup_input()
	load_meta()


# ---- Input -----------------------------------------------------------------
func _setup_input() -> void:
	_bind_keys("move_up", [KEY_W, KEY_UP])
	_bind_keys("move_down", [KEY_S, KEY_DOWN])
	_bind_keys("move_left", [KEY_A, KEY_LEFT])
	_bind_keys("move_right", [KEY_D, KEY_RIGHT])
	_bind_keys("attack", [KEY_J, KEY_SPACE])
	_bind_keys("dash", [KEY_K, KEY_SHIFT])
	_bind_keys("interact", [KEY_E])
	_bind_keys("inventory", [KEY_I, KEY_TAB])
	_bind_keys("upgrades", [KEY_U])
	_bind_keys("pause", [KEY_ESCAPE])
	_bind_keys("confirm", [KEY_ENTER, KEY_SPACE])
	_bind_mouse("attack", MOUSE_BUTTON_LEFT)


func _bind_keys(action: StringName, physical_keycodes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for kc in physical_keycodes:
		var ev := InputEventKey.new()
		ev.physical_keycode = kc
		InputMap.action_add_event(action, ev)


func _bind_mouse(action: StringName, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


# ---- Persistence -----------------------------------------------------------
func save_meta() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(meta.to_dict(), "\t"))
		f.close()
	meta_changed.emit()


func load_meta() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		meta.from_dict(data)
	meta_changed.emit()
