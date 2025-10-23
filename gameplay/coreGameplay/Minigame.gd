extends Node
class_name Minigame

signal minigame_finished(success: bool)

@export var speed : float = 1.0
@export var difficulty : int = 1

func start():
	pass

func finish(success: bool):
	emit_signal("minigame_finished", success)

func _play_one_shot_sfx(sfx: AudioStream, pitch_range : float = 0.1, start_time : float = 0.0):
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = sfx
	
	var min_pitch = 1.0 - pitch_range
	var max_pitch = 1.0 + pitch_range
	
	player.pitch_scale = randf_range(min_pitch, max_pitch)
	
	player.finished.connect(player.queue_free)
	player.play(start_time)
