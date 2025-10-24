extends Minigame

@export var click_sfx: AudioStream = preload("res://assets/minigames/EmailTyper/keypress.mp3")
@export var slider_sfx: AudioStream = preload("res://assets/minigames/RoboRepair/Gear.mp3")

@onready var power_slider := $CanvasLayer/Control/Power
@onready var angle_slider := $CanvasLayer/Control/Angle
@onready var launch_button := $CanvasLayer/Control/Launch
@onready var projectile := $Game/Projectile
@onready var target := $Game/Target
@onready var arc_line := $Game/Estimation
@onready var timer := $MinigameTimer
@onready var anim := $AnimationPlayer

@onready var music_player = $AudioStreamPlayer2D
@onready var music = preload("res://assets/msfx/minigameMusic/gun head guy thing_2.wav")
@onready var fire_sfx = preload("res://assets/minigames/Catapult/cornguylaunch.mp3")

@onready var pivot = $Game/CatapultBase/Pivot
@onready var launch_pos = $Game/CatapultBase/Pivot/CornGunGuyHead/LaunchPosition

var gravity := Vector2(0, 200)
var projectile_velocity := Vector2.ZERO
var launched := false
var game_finished := false

var power_range := Vector2(50, 120)
var angle_range := Vector2(15, 75)
var bounds := Rect2(80, 30, 90, 70)
var collision_radius := 15

const FADE_TIME = 1.0

const SLIDER_SFX_STEP := 15.0

var last_power_sfx_value := 0.0
var last_angle_sfx_value := 0.0

func start():
	randomize()
	game_finished = false
	launched = false
	_reset_projectile()

	target.position = Vector2(
		randf_range(bounds.position.x, bounds.end.x),
		randf_range(bounds.position.y, bounds.end.y)
	)

	var scale_factor = clamp(1.0 - (difficulty * 0.1), 0.4, 1.0)
	target.scale = Vector2(scale_factor, scale_factor)

	collision_radius = 15 * scale_factor

	gravity.y = 60 + randf_range(0, difficulty * 10)

	power_slider.value = randf_range(0, power_slider.max_value)
	angle_slider.value = randf_range(0, angle_slider.max_value)

	if power_slider.is_connected("value_changed", _update_arc):
		power_slider.disconnect("value_changed", _update_arc)
	if angle_slider.is_connected("value_changed", _update_arc):
		angle_slider.disconnect("value_changed", _update_arc)
	if launch_button.is_connected("pressed", _on_launch_pressed):
		launch_button.disconnect("pressed", _on_launch_pressed)
	if timer.is_connected("time_up", _on_time_up):
		timer.disconnect("time_up", _on_time_up)

	power_slider.value_changed.connect(_update_arc)
	angle_slider.value_changed.connect(_update_arc)
	launch_button.pressed.connect(_on_launch_pressed)
	timer.time_up.connect(_on_time_up)

	_fade_in_music()
	_update_arc()
	timer.start()

func _update_arc(value = 0):
	if abs(value - last_angle_sfx_value) >= SLIDER_SFX_STEP:
		_play_one_shot_sfx(slider_sfx, 0.05)
		last_angle_sfx_value = value
	
	var angle_deg = lerp(angle_range.x, angle_range.y, angle_slider.value / angle_slider.max_value)
	var power = lerp(power_range.x, power_range.y, power_slider.value / power_slider.max_value)
	var angle_rad = deg_to_rad(angle_deg)

	pivot.rotation = -angle_rad

	var v0 = Vector2(cos(angle_rad), -sin(angle_rad)) * power
	var start_pos = launch_pos.global_position

	var points = []
	for t in range(0, 20):
		var time = t * 0.05
		var pos = start_pos + Vector2(v0.x * time, v0.y * time + 0.5 * gravity.y * time * time)
		points.append(pos)
	arc_line.points = points


func _on_launch_pressed():
	if launched or game_finished:
		return

	_play_one_shot_sfx(fire_sfx)
	_play_one_shot_sfx(click_sfx)
	timer.pause_timer()
	launched = true
	var angle_deg = lerp(angle_range.x, angle_range.y, angle_slider.value / angle_slider.max_value)
	var power = lerp(power_range.x, power_range.y, power_slider.value / power_slider.max_value)
	var angle_rad = deg_to_rad(angle_deg)
	projectile_velocity = Vector2(cos(angle_rad), -sin(angle_rad)) * power
	projectile.position = launch_pos.global_position
	arc_line.visible = false
	power_slider.editable = false
	angle_slider.editable = false
	launch_button.disabled = true

func _process(delta):
	if launched and !game_finished:
		projectile.position += projectile_velocity * delta
		projectile_velocity += gravity * delta
		if not game_finished and projectile.position.distance_to(target.position) < collision_radius:
			_mark_success()
		if projectile.position.y > 190 or projectile.position.x > 400 or projectile.position.x < -50:
			if not game_finished:
				_finish(false)
			else:
				_finish(true)

func _finish(success: bool):
	launched = true
	game_finished = true	
	$CanvasLayer/Control/Power.editable=false 
	$CanvasLayer/Control/Angle.editable=false
	timer.pause_timer()
	await _play_finish_animation(success)
	emit_signal("minigame_finished", success)

func _reset_projectile():
	projectile.position = Vector2(-25, -100)
	projectile_velocity = Vector2.ZERO
	launched = false
	game_finished = false
	arc_line.visible = true
	power_slider.editable = true
	angle_slider.editable = true
	launch_button.disabled = false
	_update_arc()

func _on_time_up():
	if game_finished:
		return
	_finish(false)

func _play_finish_animation(success: bool):
	if success:
		anim.play("Pass")
	else:
		anim.play("Fail")
	return await anim.animation_finished

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

func _mark_success():
	game_finished = true
	timer.pause_timer()
	_fade_out_music()
	_play_one_shot_sfx(click_sfx)
	if is_instance_valid(projectile):
		projectile.queue_free()
	_finish(true)
