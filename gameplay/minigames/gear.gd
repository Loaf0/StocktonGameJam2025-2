extends Node2D

signal gear_rotated(gear_name: String, value: String)

@export var gear_name: String = "GearA"
@export var positions: Array[String] = ["1", "2", "3", "4", "5"]
@export var rotation_step_degrees: float = 360.0 / 5.0

var current_index: int = 0

func _ready():
	_update_rotation()
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("Click") and _is_hovering():
		print(gear_name + " was clicked, position " + positions[current_index])
		_on_clicked()

func _is_hovering() -> bool:
	var viewport_pos = get_viewport().get_mouse_position()
	var rect = Rect2(global_position - Vector2(32, 32), Vector2(64, 64))
	return rect.has_point(viewport_pos)

func _on_clicked():
	current_index = (current_index + 1) % positions.size()
	_update_rotation()
	emit_signal("gear_rotated", gear_name, positions[current_index])

func _update_rotation():
	rotation_degrees = current_index * rotation_step_degrees
