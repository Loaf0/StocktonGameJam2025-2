extends Minigame

@onready var slider_handles := [ 
	$CanvasLayer/ButtonContainer/AnimatableBody2D,
	$CanvasLayer/ButtonContainer2/AnimatableBody2D,
	$CanvasLayer/ButtonContainer3/AnimatableBody2D
]
@onready var buttons := [
	$CanvasLayer/ButtonContainer/Button,
	$CanvasLayer/ButtonContainer2/Button,
	$CanvasLayer/ButtonContainer3/Button
]
@onready var targets := [ 
	$CanvasLayer/ButtonContainer/Marker,
	$CanvasLayer/ButtonContainer2/Marker,
	$CanvasLayer/ButtonContainer3/Marker
]
@onready var lasers := [ 
	$CanvasLayer/LaserContainer/Sprite2D,
	$CanvasLayer/LaserContainer/Sprite2D2,
	$CanvasLayer/LaserContainer/Sprite2D3
]

@onready var music_player = $AudioStreamPlayer2D
@onready var music = preload("res://assets/msfx/minigameMusic/baking thing.wav")
@onready var laser_sfx = preload("res://assets/minigames/Oven/laser.mp3")
@onready var timer := $MinigameTimer
@onready var anim := $AnimationPlayer

@onready var container_width : float = $CanvasLayer/ButtonContainer.size.x

var times := [0.0, 1.5, 3.2]
var bounce_speed := [1.2, 1.0, .8]
var active := [true, true, true]
var perfect_ranges: Array = []

var difficulty_settings = {
	1: {"range_size": 0.3, "time_limit": 10.0, "speed": 1.0},
	2: {"range_size": 0.27, "time_limit": 7.5, "speed": 1.1},
	3: {"range_size": 0.25, "time_limit": 5.0, "speed": 1.3}
}

const FADE_TIME = 1.0


func start():
	randomize()
	var settings = difficulty_settings.get(difficulty, difficulty_settings[1])

	perfect_ranges.clear()
	for i in range(3):
		var start_loc = randf_range(0.05, 0.95 - settings["range_size"])
		var size = settings["range_size"]
		perfect_ranges.append(Vector2(start_loc, start_loc + size))
		bounce_speed[i] = speed * settings["speed"] + randf_range(-0.2, 0.2) 
	
	#music_player.pitch_scale = speed 
	_fade_in_music()
	
	await _setup_targets()
	_setup_buttons()
	timer.start(settings["time_limit"])
	timer.time_up.connect(_on_time_up)
	speed = 1 + ((speed - 1) / 3)


func _fade_in_music():
	music_player.stream = music
	music_player.volume_db = -80.0
	music_player.play()
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", Settings.MUSIC_VOLUME_DB, FADE_TIME)
	

func _fade_out_music():
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, FADE_TIME)
	await tween.finished
	music_player.stop()


func _setup_targets() -> void:
	await get_tree().process_frame
	for i in range(3):
		var target = targets[i]
		var r = perfect_ranges[i]
		var handle = slider_handles[i]

		target.anchor_left = r.x
		target.anchor_right = r.y
		target.anchor_top = 0
		target.anchor_bottom = 1
		target.offset_left = 0
		target.offset_right = 0
		target.offset_top = 0
		target.offset_bottom = 0

		handle.position.x = container_width * 0.5

func _setup_buttons():
	for i in range(3):
		buttons[i].pressed.connect(_on_button_pressed.bind(i))
		active[i] = true
		buttons[i].disabled = false

func _disable_all_buttons():
	for button in buttons:
		button.disabled = true
	for i in range(active.size()):
		active[i] = false

func _process(delta: float) -> void:
	for i in range(3):
		var handle = slider_handles[i]
		if active[i]:
			times[i] += delta * bounce_speed[i]
			var t := (sin(times[i]) * 0.5) + 0.5 
			handle.position.x = container_width * t

func _on_button_pressed(i: int):
	if not active[i]:
		return
	
	active[i] = false
	buttons[i].disabled = true
	lasers[i].visible = true
	
	_play_one_shot_sfx(laser_sfx, 0.03)
	
	var tween = create_tween()
	tween.tween_property(lasers[i], "modulate:a", 0.0, 0.75).set_delay(0.3)
	tween.finished.connect(func(): lasers[i].visible = false)
	
	var raycast = targets[i].get_node("RayCast2D")
	if not raycast.is_colliding():
		_disable_all_buttons()
		timer.stop()
		_fade_out_music()
		await _play_finish_animation(false)
		emit_signal("minigame_finished", false)
		return
		
	_check_end_condition()

func _check_end_condition():
	if active.count(true) == 0:
		timer.stop()
		var success = true
		for i in range(3):
			var raycast = targets[i].get_node("RayCast2D")
			if not raycast.is_colliding():
				success = false
		_fade_out_music()
		await _play_finish_animation(success)
		emit_signal("minigame_finished", success)

func _on_time_up():
	timer.stop()
	_disable_all_buttons()
	_fade_out_music()
	await _play_finish_animation(false)
	emit_signal("minigame_finished", false)

func _play_finish_animation(success: bool): 
	music_player.volume_db = Settings.MUSIC_VOLUME_DB 
	music_player.pitch_scale = 1.0 
	
	if success:
		anim.play("Pass")
	else:
		anim.play("Fail")
	return await anim.animation_finished
