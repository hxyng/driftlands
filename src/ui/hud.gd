class_name Hud
extends Control
## Minimal in-run HUD: health and XP bars plus level / floor / souls. Lives in a
## CanvasLayer (screen space). A richer UI pass lands in the UI milestone.

var player: Player
var floor_number := 1

var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if player == null or player.health == null or player.stats == null:
		return
	var bar_w := 92.0
	_bar(Vector2(6, 6), bar_w, 8, player.health.ratio(), Palette.BLOOD, Palette.STONE_DARK)
	_label(Vector2(8, 12), "%d / %d" % [roundi(player.health.hp), roundi(player.health.max_hp)], 7, Palette.BONE_LIT)
	_bar(Vector2(6, 17), bar_w, 4, player.progression.xp_progress(), Palette.GOLD, Palette.STONE_DARK)
	_label(Vector2(6, 33),
		"LV %d    FLOOR %d    SOULS %d" % [player.progression.level, floor_number, player.run_souls],
		8, Palette.BONE)


func _bar(pos: Vector2, w: float, h: float, ratio: float, fill: Color, bg: Color) -> void:
	draw_rect(Rect2(pos - Vector2.ONE, Vector2(w + 2, h + 2)), Palette.INK)
	draw_rect(Rect2(pos, Vector2(w, h)), bg)
	draw_rect(Rect2(pos, Vector2(w * clampf(ratio, 0, 1), h)), fill)


func _label(pos: Vector2, text: String, size: int, color: Color) -> void:
	draw_string(_font, pos + Vector2.ONE, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.7))
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
