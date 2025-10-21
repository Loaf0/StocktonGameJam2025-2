extends Minigame

@export var rotation_speed : float = 2.0
@export var target_angle : float = 0.0
@export var easy_threshold : float = 20.0
@export var medium_threshold : float = 10.0
@export var hard_threshold : float = 5.0
@export var angle_range : float = 50.0

var time_accum := 0.0
var playing : bool = false
var current_angle : float = 0.0

@onready var rotator := $CanvasLayer/Center/Rotator
@onready var target_marker := $CanvasLayer/Center/TargetMarker
@onready var left_threshold := $CanvasLayer/Center/LeftThreshold
@onready var right_threshold := $CanvasLayer/Center/RightThreshold

func start():
	target_marker.rotation_degrees = target_angle
	time_accum = randf() * PI * 2
	_update_threshold_lines()
	playing = true

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
	print("Pass" if success else "Fail", diff)
	_flash_threshold(success)
	await get_tree().create_timer(0.2).timeout
	# play win or loss anim and fade ui
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

func _flash_threshold(success: bool):
	var color = Color(0, 1, 0) if success else Color(1, 0, 0)
	left_threshold.get_child(0).color = color
	right_threshold.get_child(0).color = color
