extends Node2D

signal gear_rotated(gear_name: String, value: String)

@export var gear_name: String = "GearA"
@export var positions: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8"]
@export var offset = 0

@onready var sprite = $Image

@onready var gear_sfx = preload("res://assets/minigames/RoboRepair/Gear.mp3")

var current_index: int = 0

func _ready():
	_update_rotation()
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("Click") and _is_hovering():
		#print(gear_name + " was clicked, position " + positions[current_index])
		_on_clicked()

func _is_hovering() -> bool:
	var viewport_pos = get_viewport().get_mouse_position()
	var rect = Rect2(global_position - Vector2(16, 16), Vector2(32, 32))
	return rect.has_point(viewport_pos)

func _on_clicked():
	_play_one_shot_sfx(gear_sfx)
	current_index = (current_index + 1) % positions.size()
	_update_rotation()
	emit_signal("gear_rotated", gear_name, positions[current_index])

func _update_rotation():
	sprite.frame = current_index + offset
	

func _play_one_shot_sfx(sfx: AudioStream, pitch_range : float = 0.1, start_time : float = 0.0):
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = sfx
	
	var min_pitch = 1.0 - pitch_range
	var max_pitch = 1.0 + pitch_range
	
	player.pitch_scale = randf_range(min_pitch, max_pitch)
	
	player.finished.connect(player.queue_free)
	player.play(start_time)
