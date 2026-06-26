class_name BoonScreen
extends Control
## Level-up overlay: pauses the game and offers a few boons as cards. Pick with
## the mouse or keys 1-3. Emits [signal chosen] and frees itself.

signal chosen(boon)

var _boons: Array = []
var _font: Font


func present(boons: Array) -> void:
	_boons = boons
	_font = ThemeDB.fallback_font
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.02, 0.015, 0.72)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)

	var title := Label.new()
	title.text = "LEVEL UP — CHOOSE A BOON"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Palette.GOLD)
	column.add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	for i in _boons.size():
		row.add_child(_make_card(i, _boons[i]))

	get_tree().paused = true


func _make_card(index: int, boon) -> Control:
	var card := Button.new()
	card.custom_minimum_size = Vector2(120, 96)
	card.text = "%d\n\n%s\n%s" % [index + 1, boon.title, boon.desc]
	card.add_theme_font_size_override("font_size", 9)
	card.add_theme_color_override("font_color", Palette.BONE_LIT)
	card.add_theme_color_override("font_hover_color", Palette.GOLD)
	card.add_theme_stylebox_override("normal", _box(Palette.STONE_DARK, Palette.STONE_LIT))
	card.add_theme_stylebox_override("hover", _box(Palette.STONE, Palette.GOLD))
	card.add_theme_stylebox_override("pressed", _box(Palette.STONE, Palette.GOLD))
	card.pressed.connect(func(): _pick(index))
	return card


func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(3)
	s.set_content_margin_all(6)
	return s


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var n: int = key.keycode - KEY_1
		if n >= 0 and n < _boons.size():
			_pick(n)
			get_viewport().set_input_as_handled()


func _pick(index: int) -> void:
	var boon = _boons[index]
	get_tree().paused = false
	chosen.emit(boon)
	queue_free()
