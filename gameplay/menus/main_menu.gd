extends CanvasLayer

@export var click_sfx: AudioStream = preload("res://assets/minigames/EmailTyper/keypress.mp3")
@export var slider_sfx: AudioStream = preload("res://assets/minigames/RoboRepair/Gear.mp3")

@onready var play_panel = $LevelSelect
@onready var play_easy = $LevelSelect/Easy
@onready var play_medi = $LevelSelect/Medium
@onready var play_hard = $LevelSelect/Hard
@onready var play_back = $LevelSelect/Quit

@onready var highscore_easy = $LevelSelect/HighscoreEasyLabel
@onready var highscore_medi = $LevelSelect/HighscoreMediLabel
@onready var highscore_hard = $LevelSelect/HighscoreHardLabel

@onready var settings_panel = $Settings
@onready var volume_slider = $Settings/HSlider
@onready var settings_back = $Settings/Back

@onready var play_button = $MainMenu/Play
@onready var settings_button = $MainMenu/Settings
@onready var quit_button = $MainMenu/Quit

var _last_slider_sfx_value := 0.0
const SLIDER_SFX_STEP := 15.0

func _ready():
	_update_highscores()
	_load_settings()

	play_easy.pressed.connect(func(): _on_button_click(); _start_game(1))
	play_medi.pressed.connect(func(): _on_button_click(); _start_game(2))
	play_hard.pressed.connect(func(): _on_button_click(); _start_game(3))

	play_button.pressed.connect(func(): _on_button_click(); _on_play_pressed())
	play_back.pressed.connect(func(): _on_button_click(); _on_play_back_pressed())
	
	settings_button.pressed.connect(func(): _on_button_click(); _on_settings_pressed())
	settings_back.pressed.connect(func(): _on_button_click(); _on_settings_back_pressed())
	quit_button.pressed.connect(func(): _on_button_click(); _on_quit_pressed())
	
	volume_slider.connect("value_changed", _on_volume_changed)


func _update_highscores():
	var save_manager = get_node_or_null("/root/Save")
	if save_manager:
		save_manager.load_score()

	highscore_easy.text = "%03d" % Settings.EASY_SCORE
	highscore_medi.text = "%03d" % Settings.MEDI_SCORE
	highscore_hard.text = "%03d" % Settings.HARD_SCORE

func _start_game(difficulty: int):
	Settings.CURRENT_DIFF = difficulty
	get_tree().change_scene_to_file("res://gameplay/coreGameplay/Main.tscn")

func _on_play_pressed():
	play_panel.visible = true

func _on_play_back_pressed():
	play_panel.visible = false

func _on_settings_pressed():
	settings_panel.visible = true

func _on_settings_back_pressed():
	settings_panel.visible = false
	_save_settings()

func _on_quit_pressed():
	get_tree().quit()

func _on_volume_changed(value):
	Settings.MUSIC_VOLUME_DB = clamp(value / 100.0, 0.0, 1.0)
	var db = lerp(-80.0, 0.0, Settings.MUSIC_VOLUME_DB)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	
	if abs(value - _last_slider_sfx_value) >= SLIDER_SFX_STEP:
		_play_one_shot_sfx(slider_sfx, 0.05)
		_last_slider_sfx_value = value


func _save_settings():
	var save_manager = get_node_or_null("/root/Save")
	if save_manager:
		save_manager.save_settings()


func _load_settings():
	var save_manager = get_node_or_null("/root/Save")
	if save_manager:
		save_manager.load_settings()

	volume_slider.value = Settings.MUSIC_VOLUME_DB * 100.0

	var db = lerp(-80.0, 0.0, Settings.MUSIC_VOLUME_DB)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)


func _play_one_shot_sfx(sfx: AudioStream, pitch_range: float = 0.1, start_time: float = 0.0):
	if not sfx:
		return
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = sfx
	
	var min_pitch = 1.0 - pitch_range
	var max_pitch = 1.0 + pitch_range
	player.pitch_scale = randf_range(min_pitch, max_pitch)
	
	player.finished.connect(player.queue_free)
	player.play(start_time)


func _on_button_click():
	_play_one_shot_sfx(click_sfx)
