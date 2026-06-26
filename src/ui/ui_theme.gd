class_name UiTheme
extends RefCounted
## Shared widget styling so every menu reads as one cohesive, palette-driven UI
## (stone panels, bone text, gold focus) instead of the default grey theme.

static func panel_box(bg := Palette.STONE_DARK, border := Palette.STONE_LIT, bw := 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(3)
	s.set_content_margin_all(8)
	return s


static func style_button(btn: Button, font_size := 11) -> void:
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Palette.BONE_LIT)
	btn.add_theme_color_override("font_hover_color", Palette.GOLD)
	btn.add_theme_color_override("font_pressed_color", Palette.GOLD)
	btn.add_theme_color_override("font_focus_color", Palette.GOLD)
	btn.add_theme_color_override("font_disabled_color", Palette.STONE_LIT)
	btn.add_theme_stylebox_override("normal", panel_box(Palette.STONE_DARK, Palette.STONE_LIT))
	btn.add_theme_stylebox_override("hover", panel_box(Palette.STONE, Palette.GOLD))
	btn.add_theme_stylebox_override("pressed", panel_box(Palette.STONE, Palette.GOLD))
	btn.add_theme_stylebox_override("focus", panel_box(Palette.STONE, Palette.EMBER))
	btn.add_theme_stylebox_override("disabled", panel_box(Palette.STONE_DARK, Palette.STONE_DARK))


static func make_button(text: String, w := 150.0, h := 24.0, font_size := 11) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, h)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	style_button(b, font_size)
	return b


static func label(text: String, size := 11, color := Palette.BONE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func center_label(text: String, size := 11, color := Palette.BONE) -> Label:
	var l := label(text, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func spacer(h := 6.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
