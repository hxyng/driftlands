class_name MainMenu
extends Control
## The hub between runs: shows meta progress, starts a descent, and houses the
## souls-spent upgrade shop and the daily reward. This is where the roguelite
## loop (die -> spend souls -> descend stronger) lives.

var _stats_label: Label
var _daily_button: Button
var _overlay: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.INK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	center.add_child(col)

	col.add_child(UiTheme.center_label("DRIFTLANDS", 30, Palette.GOLD))
	col.add_child(UiTheme.center_label("a descent into the ashen hollow", 9, Palette.STONE_LIT))
	col.add_child(UiTheme.spacer(8))

	_stats_label = UiTheme.center_label(_stats_text(), 10, Palette.BONE)
	col.add_child(_stats_label)
	col.add_child(UiTheme.spacer(8))

	var descend := UiTheme.make_button("DESCEND", 160, 30, 13)
	descend.pressed.connect(_descend)
	col.add_child(descend)

	var upgrades := UiTheme.make_button("UPGRADES", 160)
	upgrades.pressed.connect(_open_upgrades)
	col.add_child(upgrades)

	_daily_button = UiTheme.make_button(_daily_text(), 160)
	_daily_button.pressed.connect(_open_daily)
	col.add_child(_daily_button)

	col.add_child(UiTheme.spacer(8))
	col.add_child(UiTheme.center_label(
		"WASD move    J / click attack    reach the stairs to descend", 8, Palette.STONE_LIT))


func _stats_text() -> String:
	var m := Game.meta
	return "Souls  %d        Best Floor  %d        Runs  %d" % [m.souls, m.best_floor, m.total_runs]


func _daily_text() -> String:
	return "CLAIM DAILY REWARD" if Daily.can_claim(Game.meta) else "DAILY REWARD"


func _refresh() -> void:
	_stats_label.text = _stats_text()
	_daily_button.text = _daily_text()


func _descend() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# ---- Overlays --------------------------------------------------------------
func _make_overlay(title_text: String) -> VBoxContainer:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	var ov := Control.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(bg)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(cc)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(Palette.STONE_DARK, Palette.GOLD, 2))
	cc.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.custom_minimum_size = Vector2(300, 0)
	panel.add_child(col)

	col.add_child(UiTheme.center_label(title_text, 14, Palette.GOLD))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	col.add_child(content)

	var close := UiTheme.make_button("CLOSE", 110, 22)
	close.pressed.connect(_close_overlay)
	col.add_child(close)

	_overlay = ov
	add_child(ov)
	return content


func _close_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
	_refresh()


func _open_upgrades() -> void:
	var content := _make_overlay("UPGRADES — spend souls")
	content.add_child(UiTheme.center_label("Souls: %d" % Game.meta.souls, 11, Palette.GOLD))
	for u in Upgrades.CATALOG:
		content.add_child(_upgrade_row(u))


func _upgrade_row(u: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var lvl := Game.meta.upgrade_level(u["id"])
	var info := UiTheme.label("%s  (%d/%d)  %s" % [u["name"], lvl, u["max"], u["desc"]], 9, Palette.BONE)
	info.custom_minimum_size = Vector2(210, 0)
	row.add_child(info)
	var c := Upgrades.cost(u["id"], lvl)
	var btn := UiTheme.make_button("MAX" if c < 0 else "%d souls" % c, 80, 20, 9)
	btn.disabled = c < 0 or Game.meta.souls < c
	btn.pressed.connect(_buy.bind(u["id"]))
	row.add_child(btn)
	return row


func _buy(id: String) -> void:
	if Upgrades.purchase(Game.meta, id):
		Game.save_meta()
	_open_upgrades()  # rebuild (also resets _overlay)


func _open_daily() -> void:
	var content := _make_overlay("DAILY REWARD")
	content.add_child(UiTheme.center_label("Streak: %d days" % Game.meta.daily_streak, 11, Palette.GOLD))
	if Daily.can_claim(Game.meta):
		var claim := UiTheme.make_button("CLAIM", 120, 24)
		claim.pressed.connect(_claim_daily)
		content.add_child(claim)
	else:
		content.add_child(UiTheme.center_label("Claimed today — return tomorrow!", 9, Palette.BONE))


func _claim_daily() -> void:
	var r := Daily.claim(Game.meta)
	Game.save_meta()
	var content := _make_overlay("DAILY REWARD")
	content.add_child(UiTheme.center_label(
		"+%d souls!   Streak %d" % [int(r["souls"]), int(r["streak"])], 12, Palette.GOLD))
