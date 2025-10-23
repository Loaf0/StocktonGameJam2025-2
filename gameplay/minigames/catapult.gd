extends Minigame

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

var gravity := Vector2(0, 200)
var projectile_velocity := Vector2.ZERO
var launched := false
var game_finished := false

var power_range := Vector2(50, 120)
var angle_range := Vector2(15, 75)
var collision_radius := 20

const FADE_TIME = 1.0


func start():
	randomize()
	game_finished = false
	launched = false
	_reset_projectile()

	# random target placement
	var dist_min = 100 + difficulty * 5
	var dist_max = 180 + difficulty * 10
	var height_min = 20
	var height_max = 150
	target.position = Vector2(randf_range(dist_min, dist_max), randf_range(height_min, height_max))

	gravity.y = 60 + randf_range(0, difficulty * 10)

	# random starting sliders
	power_slider.value = randf_range(0, power_slider.max_value)
	angle_slider.value = randf_range(0, angle_slider.max_value)

	# disconnect any old signals before reconnecting
	if power_slider.is_connected("value_changed", _update_arc):
		power_slider.disconnect("value_changed", _update_arc)
	if angle_slider.is_connected("value_changed", _update_arc):
		angle_slider.disconnect("value_changed", _update_arc)
	if launch_button.is_connected("pressed", _on_launch_pressed):
		launch_button.disconnect("pressed", _on_launch_pressed)
	if timer.is_connected("time_up", _on_time_up):
		timer.disconnect("time_up", _on_time_up)

	# reconnect signals cleanly
	power_slider.value_changed.connect(_update_arc)
	angle_slider.value_changed.connect(_update_arc)
	launch_button.pressed.connect(_on_launch_pressed)
	timer.time_up.connect(_on_time_up)

	# start music and timer
	_fade_in_music()
	_update_arc()
	timer.start()


func _update_arc(_v = 0):
	var angle_deg = lerp(angle_range.x, angle_range.y, angle_slider.value / angle_slider.max_value)
	var power = lerp(power_range.x, power_range.y, power_slider.value / power_slider.max_value)
	var angle_rad = deg_to_rad(angle_deg)
	var v0 = Vector2(cos(angle_rad), -sin(angle_rad)) * power

	var points = []
	for t in range(0, 20):
		var time = t * 0.05
		var pos = Vector2(v0.x * time, v0.y * time + 0.5 * gravity.y * time * time)
		points.append(projectile.position + pos)
	arc_line.points = points


func _on_launch_pressed():
	if launched or game_finished:
		return

	_play_one_shot_sfx(fire_sfx)
	timer.pause_timer()

	launched = true
	var angle_deg = lerp(angle_range.x, angle_range.y, angle_slider.value / angle_slider.max_value)
	var power = lerp(power_range.x, power_range.y, power_slider.value / power_slider.max_value)
	var angle_rad = deg_to_rad(angle_deg)
	projectile_velocity = Vector2(cos(angle_rad), -sin(angle_rad)) * power

	arc_line.visible = false
	power_slider.editable = false
	angle_slider.editable = false
	launch_button.disabled = true


func _process(delta):
	if launched and not game_finished:
		projectile.position += projectile_velocity * delta
		projectile_velocity += gravity * delta

		if projectile.position.y > 190:
			_finish(false)
		elif projectile.position.distance_to(target.position) < collision_radius:
			_finish(true)


func _finish(success: bool):
	if game_finished:
		return

	game_finished = true
	launched = false

	timer.pause_timer()
	await _fade_out_music()
	await _play_finish_animation(success)

	emit_signal("minigame_finished", success)
	_reset_projectile()


func _reset_projectile():
	projectile.position = Vector2(25, 100)
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
