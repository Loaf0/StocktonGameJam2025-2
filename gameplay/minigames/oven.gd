extends Minigame

@onready var bars := [
	$CanvasLayer/Control/ButtonContainer/Bar1,
	$CanvasLayer/Control/ButtonContainer2/Bar1,
	$CanvasLayer/Control/ButtonContainer3/Bar1
]
@onready var buttons := [
	$CanvasLayer/Control/ButtonContainer/Button,
	$CanvasLayer/Control/ButtonContainer2/Button,
	$CanvasLayer/Control/ButtonContainer3/Button
]
@onready var targets := [
	$CanvasLayer/Control/ButtonContainer/ColorRect,
	$CanvasLayer/Control/ButtonContainer2/ColorRect,
	$CanvasLayer/Control/ButtonContainer3/ColorRect
]

@onready var timer := $MinigameTimer
@onready var anim := $AnimationPlayer

var times := [0.0, 1.5, 3.2]
var bounce_speed := [1.2, 1.0, 1.5]
var active := [true, true, true]
var perfect_ranges: Array = []

var difficulty_settings = {
	1: {"range_size": 0.25, "time_limit": 10.0, "speed": 1.0},
	2: {"range_size": 0.18, "time_limit": 7.5, "speed": 1.2},
	3: {"range_size": 0.12, "time_limit": 5.0, "speed": 1.5}
}

func start():
	randomize()
	var settings = difficulty_settings.get(difficulty, difficulty_settings[1])

	perfect_ranges.clear()
	for i in range(3):
		var start_loc = randf_range(0.05, 0.95 - settings["range_size"])
		var size = settings["range_size"]
		perfect_ranges.append(Vector2(start_loc, start_loc + size))
		bounce_speed[i] = settings["speed"] + randf_range(-0.2, 0.2)
	
	print(settings)
	print("Difficulty : " + str(difficulty))
	
	await _setup_targets()
	_setup_buttons()
	timer.start(settings["time_limit"])
	timer.time_up.connect(_on_time_up)

func _setup_targets() -> void:
	await get_tree().process_frame
	for i in range(3):
		var target = targets[i]
		var r = perfect_ranges[i]

		target.anchor_left = r.x
		target.anchor_right = r.y
		target.anchor_top = 0
		target.anchor_bottom = 1

		target.offset_left = 0
		target.offset_right = 0
		target.offset_top = 0
		target.offset_bottom = 0

		target.color = Color(0.0, 1.0, 0.0, 0.25)

func _setup_buttons():
	for i in range(3):
		buttons[i].pressed.connect(_on_button_pressed.bind(i))
		active[i] = true
		buttons[i].disabled = false

func _process(delta: float) -> void:
	for i in range(3):
		if active[i]:
			times[i] += delta * bounce_speed[i]
			var t := (sin(times[i]) * 0.5) + 0.5
			bars[i].value = t
			_update_bar_color(i)

func _update_bar_color(i: int):
	var v = bars[i].value
	var r = perfect_ranges[i]
	if v >= r.x and v <= r.y:
		bars[i].modulate = Color(0.3, 1.0, 0.3)
	else:
		bars[i].modulate = Color(1.0, 0.5, 0.3)

func _on_button_pressed(i: int):
	if not active[i]:
		return
	active[i] = false
	buttons[i].disabled = true

	var v = bars[i].value
	var r = perfect_ranges[i]

	if v < r.x or v > r.y:
		timer.stop()
		await _play_finish_animation(false)
		emit_signal("minigame_finished", false)
		return

	_check_end_condition()

func _check_end_condition():
	if active.count(true) == 0:
		timer.stop()
		var success = true
		for i in range(3):
			var v = bars[i].value
			var r = perfect_ranges[i]
			if v < r.x or v > r.y:
				success = false
		await _play_finish_animation(success)
		emit_signal("minigame_finished", success)

func _on_time_up():
	await _play_finish_animation(false)
	emit_signal("minigame_finished", false)

func _play_finish_animation(success: bool):
	if success:
		anim.play("Pass")
	else:
		anim.play("Fail")
	return await anim.animation_finished
