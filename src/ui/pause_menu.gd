class_name PauseMenu
extends Control
## In-run pause overlay. Pauses the tree (it processes while paused) and offers
## resume or abandon. Abandon is reported via [signal abandoned] so the level
## can bank the run's souls first.

signal abandoned


func open() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 8)
	cc.add_child(col)

	col.add_child(UiTheme.center_label("PAUSED", 22, Palette.GOLD))
	var resume := UiTheme.make_button("RESUME", 150, 26)
	resume.pressed.connect(_resume)
	col.add_child(resume)
	var abandon := UiTheme.make_button("ABANDON RUN", 150, 24)
	abandon.pressed.connect(_abandon)
	col.add_child(abandon)

	get_tree().paused = true


func _resume() -> void:
	get_tree().paused = false
	queue_free()


func _abandon() -> void:
	get_tree().paused = false
	abandoned.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_resume()
		get_viewport().set_input_as_handled()
