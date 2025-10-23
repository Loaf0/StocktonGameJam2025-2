extends Minigame

@export var rotation_speed : float = 2.0
@export var target_angle : float = 0.0
@export var easy_threshold : float = 15.0
@export var medium_threshold : float = 10.0
@export var hard_threshold : float = 10.0
@export var angle_range : float = 50.0

var time_accum := 0.0
var playing : bool = false
var current_angle : float = 0.0

@onready var rotator := $CanvasLayer/Center/Rotator
@onready var target_marker := $CanvasLayer/Center/TargetMarker
@onready var left_threshold := $CanvasLayer/Center/LeftThreshold
@onready var right_threshold := $CanvasLayer/Center/RightThreshold
@onready var anim := $AnimationPlayer
@onready var music_player = $AudioStreamPlayer2D
@onready var music = preload("res://assets/msfx/minigameMusic/lawnmower thing.wav")
@onready var sword_sfx = preload("res://assets/minigames/GrassCutter/SwordCutter.mp3")

const FADE_TIME = 1.0

func start():
	print(speed)
	print(difficulty)
	target_marker.rotation_degrees = target_angle
	time_accum = randf() * PI * 2
	_fade_in_music()
	_update_threshold_lines()
	playing = true
	if difficulty <= 1:
		rotation_speed = 1.5
	elif difficulty <= 2:
		rotation_speed = 2.0
	else:
		rotation_speed = 2.5

func _process(delta):
	if not playing:
		return

	time_accum += delta * rotation_speed * speed
	var phase := sin(time_accum)
	current_angle = angle_range * sign(phase) * abs(phase)
	rotator.rotation_degrees = current_angle

func _input(event):
	if not playing:
		return
	if event.is_action_pressed("Click"):
		_check_success()

func _check_success():
	var diff = abs(current_angle - target_angle)
	var threshold = _get_threshold()
	var success = diff <= threshold
	playing = false
	_flash_threshold(success)
	_fade_out_music()
	await get_tree().create_timer(0.2).timeout
	anim.play("Pass" if success else "Fail")
	await anim.animation_finished
	emit_signal("minigame_finished", success)

func _get_threshold() -> float:
	if difficulty <= 1:
		return easy_threshold
	elif difficulty <= 2:
		return medium_threshold
	else:
		return hard_threshold

func _update_threshold_lines():
	var threshold = _get_threshold()
	left_threshold.rotation_degrees = target_angle - threshold
	right_threshold.rotation_degrees = target_angle + threshold

func play_slash_sfx():
	_play_one_shot_sfx(sword_sfx)

func _flash_threshold(success: bool):
	var color = Color(0, 1, 0) if success else Color(1, 0, 0)
	left_threshold.get_child(0).color = color
	right_threshold.get_child(0).color = color

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
