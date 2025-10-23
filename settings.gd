extends Node

var MUSIC_VOLUME_DB : float = 1
var SOUND_EFFECTS_VOLUME_DB : float = 1

var CURRENT_DIFF : int = 1

var EASY_SCORE : int = 0
var MEDI_SCORE : int = 0
var HARD_SCORE : int = 0

func get_audio_speed_scale(current_speed):
	return clampf(1.0 + (current_speed - 1.0) / 8, 1, 1.5) 
