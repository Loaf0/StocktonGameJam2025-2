extends Minigame

@onready var power_slider := $CanvasLayer/Control/Power
@onready var angle_slider := $CanvasLayer/Control/Angle
@onready var launch_button := $CanvasLayer/Control/Launch
@onready var projectile := $Game/Projectile
@onready var target := $Game/Target
@onready var arc_line := $Game/Estimation
@onready var timer := $Game/Timer
@onready var anim := $AnimationPlayer

var gravity := Vector2(0, 400)
var projectile_velocity := Vector2.ZERO
var launched := false
var target_hit := false

var power_range := Vector2(150, 400)
var angle_range := Vector2(15, 75)

func start():
	randomize()
	_reset_projectile()
	var dist_min = 500 + (difficulty * 100)
	var dist_max = 800 + (difficulty * 150)
	var height_min = 250 - (difficulty * 20)
	var height_max = 400 + (difficulty * 30)
	target.position = Vector2(randf_range(dist_min, dist_max), randf_range(height_min, height_max))
	gravity.y = 300 + randf_range(0, difficulty * 80)
	power_slider.value = randf_range(0, power_slider.max_value)
	angle_slider.value = randf_range(0, angle_slider.max_value)
	angle_slider.value_changed.connect(_update_arc)
	power_slider.value_changed.connect(_update_arc)
	launch_button.pressed.connect(_on_launch_pressed)
	_update_arc()

func _update_arc(_v = 0):
	var angle_deg = lerp(angle_range.x, angle_range.y, angle_slider.value / angle_slider.max_value)
	var power = lerp(power_range.x, power_range.y, power_slider.value / power_slider.max_value)
	var angle_rad = deg_to_rad(angle_deg)
	var v0 = Vector2(cos(angle_rad), -sin(angle_rad)) * power
	var points = []
	for t in range(0, 50):
		var time = t * 0.1
		var pos = Vector2(v0.x * time, v0.y * time + 0.5 * gravity.y * time * time)
		points.append(projectile.position + pos)
	arc_line.points = points

func _on_launch_pressed():
	if launched:
		return
	launched = true
	var angle_deg = lerp(angle_range.x, angle_range.y, angle_slider.value / angle_slider.max_value)
	var power = lerp(power_range.x, power_range.y, power_slider.value / power_slider.max_value)
	var angle_rad = deg_to_rad(angle_deg)
	projectile_velocity = Vector2(cos(angle_rad), -sin(angle_rad)) * power
	timer.start(5.0)
	arc_line.visible = false

func _process(delta):
	if launched:
		projectile.position += projectile_velocity * delta
		projectile_velocity += gravity * delta
		if projectile.position.y > 500:
			_finish(false)
		elif projectile.position.distance_to(target.position) < 30:
			_finish(true)

func _finish(success: bool):
	if target_hit or not launched:
		return
	target_hit = success
	launched = false
	if success:
		emit_signal("minigame_finished", true)
	else:
		emit_signal("minigame_finished", false)
	timer.stop()
	await _play_finish_animation(success)
	_reset_projectile()

func _reset_projectile():
	projectile.position = Vector2(150, 400)
	projectile_velocity = Vector2.ZERO
	launched = false
	target_hit = false
	arc_line.visible = true
	_update_arc()

func _on_time_up():
	_finish(false)

func _play_finish_animation(success: bool):
	if success:
		anim.play("Pass")
	else:
		anim.play("Fail")
	return await anim.animation_finished
