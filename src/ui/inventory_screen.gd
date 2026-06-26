class_name InventoryScreen
extends Control
## In-run inventory + equipment overlay (opened with I / Tab). Pauses the run,
## shows the five equip slots and the bag, the live stat totals, and lets the
## player swap any bag item into its slot. Closing recomputes nothing new -
## equips apply immediately so the player can re-plan mid-fight.

var _player: Player
var _content: HBoxContainer


func open(player: Player) -> void:
	_player = player
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.01, 0.72)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(Palette.STONE_DARK, Palette.STONE_LIT, 2))
	cc.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	root.custom_minimum_size = Vector2(404, 0)
	panel.add_child(root)

	root.add_child(UiTheme.center_label("INVENTORY", 16, Palette.GOLD))

	_content = HBoxContainer.new()
	_content.add_theme_constant_override("separation", 14)
	root.add_child(_content)

	root.add_child(UiTheme.spacer(2))
	var hint := UiTheme.center_label("Click a bag item to equip it.   [ I / Tab / Esc ]  close", 8, Palette.STONE_LIT)
	root.add_child(hint)

	_rebuild()
	get_tree().paused = true


func _rebuild() -> void:
	for child in _content.get_children():
		child.queue_free()
	_content.add_child(_build_equipped_column())
	_content.add_child(_vrule())
	_content.add_child(_build_bag_column())
	_content.add_child(_vrule())
	_content.add_child(_build_stats_column())


func _build_equipped_column() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	col.custom_minimum_size = Vector2(150, 0)
	col.add_child(UiTheme.label("EQUIPPED", 10, Palette.BONE_LIT))
	for slot in [Item.Slot.WEAPON, Item.Slot.ARMOR, Item.Slot.HELM, Item.Slot.RING, Item.Slot.BOOTS]:
		var item: Item = _player.equipment.get_item(slot)
		var slot_name := String(Item.SLOT_NAMES[slot]).to_upper()
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		if item == null:
			row.add_child(UiTheme.label("%s:  --" % slot_name, 9, Palette.STONE_LIT))
		else:
			row.add_child(UiTheme.label("%s:  %s" % [slot_name, item.display_name], 9, item.color()))
			row.add_child(UiTheme.label("    " + item.summary(), 8, Palette.BONE))
		col.add_child(row)
	return col


func _build_bag_column() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	col.custom_minimum_size = Vector2(150, 0)
	col.add_child(UiTheme.label("BAG  (%d)" % _player.inventory.size(), 10, Palette.BONE_LIT))

	if _player.inventory.size() == 0:
		col.add_child(UiTheme.label("(empty)", 9, Palette.STONE_LIT))
		return col

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(150, 132)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for item in _player.inventory.items.duplicate():
		var btn := Button.new()
		btn.text = "%s  %s" % [String(Item.SLOT_NAMES[item.slot]).left(3).to_upper(), item.display_name]
		btn.tooltip_text = item.summary()
		btn.custom_minimum_size = Vector2(146, 18)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UiTheme.style_button(btn, 8)
		btn.add_theme_color_override("font_color", item.color())
		btn.pressed.connect(_on_equip.bind(item))
		list.add_child(btn)
	return col


func _build_stats_column() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.custom_minimum_size = Vector2(86, 0)
	col.add_child(UiTheme.label("STATS", 10, Palette.BONE_LIT))
	var s := _player.stats
	_stat(col, "HP", "%d" % roundi(s.max_hp))
	_stat(col, "ATK", "%d" % roundi(s.attack))
	_stat(col, "DEF", "%d" % roundi(s.defense))
	_stat(col, "CRIT", "%d%%" % roundi(s.crit_chance * 100.0))
	_stat(col, "ASPD", "%.2f" % s.attack_speed)
	_stat(col, "SPD", "%d" % roundi(s.move_speed))
	_stat(col, "LUCK", "%d" % roundi(s.luck))
	return col


func _stat(col: Control, name_text: String, value: String) -> void:
	col.add_child(UiTheme.label("%-5s %s" % [name_text, value], 9, Palette.BONE))


func _vrule() -> Control:
	var r := ColorRect.new()
	r.color = Palette.STONE
	r.custom_minimum_size = Vector2(1, 0)
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return r


func _on_equip(item: Item) -> void:
	_player.equip_from_bag(item)
	_rebuild()


func _close() -> void:
	get_tree().paused = false
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") or event.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()
