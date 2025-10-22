extends Node

var MUSIC_VOLUME_DB : float = 1
var SOUND_EFFECTS_VOLUME_DB : float = 1

func get_audio_speed_scale(current_speed):
	return 1.0 + (current_speed - 1.0) / 4
