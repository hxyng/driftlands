class_name Health
extends Node
## Hit points for any combatant. Emits [signal damaged] (with crit flag and the
## world position) and [signal died]. Supports brief invulnerability windows so
## the player isn't shredded by overlapping contacts.

signal damaged(amount, crit, pos)
signal healed(amount)
signal died

var max_hp := 10.0
var hp := 10.0
var invuln := 0.0


func setup(maximum: float) -> void:
	max_hp = maximum
	hp = maximum


func take_damage(amount: int, crit := false, pos := Vector2.ZERO) -> void:
	if hp <= 0.0 or invuln > 0.0:
		return
	hp -= amount
	damaged.emit(amount, crit, pos)
	if hp <= 0.0:
		hp = 0.0
		died.emit()


func heal(amount: float) -> void:
	if hp <= 0.0:
		return
	hp = minf(max_hp, hp + amount)
	healed.emit(amount)


func ratio() -> float:
	return clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)


func is_alive() -> bool:
	return hp > 0.0


func _process(delta: float) -> void:
	if invuln > 0.0:
		invuln -= delta
