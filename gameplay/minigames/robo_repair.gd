extends Minigame

@onready var timer := $MinigameTimer
@onready var anim := $AnimationPlayer
@onready var label := $CanvasLayer/Label
@onready var gears := [$CanvasLayer/Container/Gear, $CanvasLayer/Container/Gear2]
@onready var sliders := [$CanvasLayer/Container/HSlider, $CanvasLayer/Container/HSlider2]
@onready var toggles := [
	$CanvasLayer/Container/Control/CheckButton,
	$CanvasLayer/Container/Control/CheckButton2,
	$CanvasLayer/Container/Control/CheckButton3
]
@onready var submit := $CanvasLayer/SubmitButton

var target_config := {}
var finished := false

var difficulty_settings = {
	1: {"time_limit": 20.0},
	2: {"time_limit": 15.0},
	3: {"time_limit": 10.0}
}

# Compass direction mapping for gear indices
const COMPASS_DIRECTIONS = [
	"E", "SE", "S", "SW", "W", "NW", "N", "NE"
]

func start():
	randomize()
	var settings = difficulty_settings.get(difficulty, difficulty_settings[1])

	# Disconnect signals first to avoid stacking from restarts
	if timer.is_connected("time_up", _on_time_up):
		timer.disconnect("time_up", _on_time_up)
	timer.time_up.connect(_on_time_up)

	for gear in gears:
		if gear and gear.has_signal("gear_rotated"):
			if gear.is_connected("gear_rotated", _on_gear_changed):
				gear.disconnect("gear_rotated", _on_gear_changed)
			gear.gear_rotated.connect(_on_gear_changed)

	for s in sliders:
		s.min_value = 0
		s.max_value = 6
		if s.is_connected("value_changed", _on_slider_changed):
			s.disconnect("value_changed", _on_slider_changed)
		s.value_changed.connect(_on_slider_changed)

	for t in toggles:
		if t.is_connected("toggled", _on_toggle_changed):
			t.disconnect("toggled", _on_toggle_changed)
		t.toggled.connect(_on_toggle_changed)

	if submit.is_connected("pressed", _on_submit_pressed):
		submit.disconnect("pressed", _on_submit_pressed)
	submit.pressed.connect(_on_submit_pressed)

	timer.start(settings["time_limit"])
	_randomize_start_state()
	_generate_target_config()
	_display_instructions()


func _randomize_start_state():
	for gear in gears:
		if gear and "positions" in gear:
			var start_index = randi() % gear.positions.size()
			if "set_position_index" in gear:
				gear.set_position_index(start_index)
			elif "current_index" in gear:
				gear.current_index = start_index
				if "_update_rotation" in gear:
					gear._update_rotation()
	for s in sliders:
		s.value = randf_range(s.min_value, s.max_value)
	for t in toggles:
		t.button_pressed = bool(randi() % 2)


func _generate_target_config():
	target_config.clear()
	var possible_components := [
		{"id": "A", "type": "gear", "index": 0},
		{"id": "B", "type": "gear", "index": 1},
		{"id": "slider1", "type": "slider", "index": 0},
		{"id": "slider2", "type": "slider", "index": 1},
		{"id": "toggle1", "type": "toggle", "index": 0},
		{"id": "toggle2", "type": "toggle", "index": 1},
		{"id": "toggle3", "type": "toggle", "index": 2}
	]
	var num_instructions := 2 + difficulty
	possible_components.shuffle()

	for i in range(num_instructions):
		var c = possible_components[i]
		match c.type:
			"gear":
				target_config[c.id] = randi() % COMPASS_DIRECTIONS.size()
			"slider":
				target_config[c.id] = randf_range(0, 6)
			"toggle":
				target_config[c.id] = bool(randi() % 2)


func _display_instructions():
	var text := ""
	for key in target_config.keys():
		var value = target_config[key]
		match key:
			"A", "B":
				var direction = COMPASS_DIRECTIONS[value % COMPASS_DIRECTIONS.size()]
				text += "- Rotate gear %s to face %s\n" % [key, direction]
			"slider1", "slider2":
				text += "- Adjust %s to %.1f\n" % [key, value]
			"toggle1", "toggle2", "toggle3":
				text += "- Switch %s %s\n" % [key, "ON" if value else "OFF"]
	label.bbcode_enabled = true
	label.bbcode_text = text

func _on_gear_changed(gear_name: String, pos: String):
	print("Gear %s set to %s" % [gear_name, pos])

func _on_slider_changed(_value): pass
func _on_toggle_changed(_value): pass

func _on_submit_pressed():
	if finished: return
	finished = true

	timer.stop()
	var success = _check_success()
	await _play_finish_animation(success)
	emit_signal("minigame_finished", success)

func _check_success() -> bool:
	for key in target_config.keys():
		match key:
			"A":
				if gears[0].current_index != target_config["A"]:
					return false
			"B":
				if gears.size() > 1 and gears[1].current_index != target_config["B"]:
					return false
			"slider1":
				if abs(sliders[0].value - target_config["slider1"]) > 0.1:
					return false
			"slider2":
				if sliders.size() > 1 and abs(sliders[1].value - target_config["slider2"]) > 0.1:
					return false
			"toggle1":
				if toggles[0].button_pressed != target_config["toggle1"]:
					return false
			"toggle2":
				if toggles.size() > 1 and toggles[1].button_pressed != target_config["toggle2"]:
					return false
			"toggle3":
				if toggles.size() > 2 and toggles[2].button_pressed != target_config["toggle3"]:
					return false
	return true

func _on_time_up():
	if finished: return
	finished = true

	await _play_finish_animation(false)
	emit_signal("minigame_finished", false)

func _play_finish_animation(success: bool):
	if success:
		anim.play("Pass")
	else:
		anim.play("Fail")
	return await anim.animation_finished
