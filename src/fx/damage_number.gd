class_name DamageNumber
extends Node2D
## A floating combat number that drifts up and fades. Crits are bigger and gold.

const LIFE := 0.7

var _text := ""
var _color := Color.WHITE
var _life := 0.0
var _font: Font
var _drift := Vector2(0, -20)


func setup(amount: int, crit := false) -> void:
	_text = str(amount)
	_color = Palette.GOLD if crit else Palette.BONE_LIT
	scale = Vector2(1.4, 1.4) if crit else Vector2.ONE
	_drift = Vector2(randf_range(-6, 6), -22)


## Generic floating label (item pickups, notifications).
func setup_text(text: String, color: Color) -> void:
	_text = text
	_color = color
	_drift = Vector2(0, -16)


func _ready() -> void:
	_font = ThemeDB.fallback_font
	z_index = 100


func _process(delta: float) -> void:
	_life += delta
	position += _drift * delta
	modulate.a = clampf(1.0 - _life / LIFE, 0.0, 1.0)
	queue_redraw()
	if _life >= LIFE:
		queue_free()


func _draw() -> void:
	var w := _font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	draw_string(_font, Vector2(-w * 0.5, 0), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
			Color(0, 0, 0, modulate.a))  # shadow
	draw_string(_font, Vector2(-w * 0.5, -1), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, _color)
