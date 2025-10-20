extends Node2D

signal minigame_finished(success: bool)

@export var difficulty: int = 1

@onready var timer := $MinigameTimer
@onready var anim := $AnimationPlayer
@onready var label := $CanvasLayer/Label
@onready var gears := [$CanvasLayer/Container/Gear, $CanvasLayer/Container/Gear2]
@onready var sliders := [$CanvasLayer/Container/HSlider, $CanvasLayer/Container/HSlider2]
@onready var toggles := [
	$CanvasLayer/Container/Buttons/CheckButton,
	$CanvasLayer/Container/Buttons/CheckButton2,
	$CanvasLayer/Container/Buttons/CheckButton3
]
@onready var submit := $CanvasLayer/SubmitButton

var target_config := {}

var difficulty_settings = {
	1: {"time_limit": 20.0},
	2: {"time_limit": 15.0},
	3: {"time_limit": 10.0}
}

func start():
	randomize()
	var settings = difficulty_settings.get(difficulty, difficulty_settings[1])
	timer.start(settings["time_limit"])
	timer.time_up.connect(_on_time_up)
	_generate_target_config()
	_display_instructions()
	for gear in gears:
		if gear and gear.has_signal("gear_rotated"):
			gear.gear_rotated.connect(_on_gear_changed)
	for s in sliders:
		s.value_changed.connect(_on_slider_changed)
	for t in toggles:
		t.toggled.connect(_on_toggle_changed)
	submit.pressed.connect(_on_submit_pressed)

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
				target_config[c.id] = randi() % gears[c.index].positions.size()
			"slider":
				target_config[c.id] = randi_range(1, 5)
			"toggle":
				target_config[c.id] = bool(randi() % 2)

func _display_instructions():
	var text := "[b]Repair Instructions:[/b]\n"
	for key in target_config.keys():
		var value = target_config[key]
		match key:
			"A", "B":
				text += "- Set gear %s to position %s\n" % [key, str(int(value) + 1)]
			"slider1", "slider2":
				text += "- Adjust %s to %.1f\n" % [key, value]
			"toggle1", "toggle2", "toggle3":
				text += "- Switch %s %s\n" % [key, "ON" if value else "OFF"]
	label.bbcode_enabled = true
	label.bbcode_text = text

func _on_gear_changed(gear_name: String, pos: String):
	print("Gear %s set to %s" % [gear_name, pos])

func _on_slider_changed(_value):
	pass

func _on_toggle_changed(_value):
	pass

func _on_submit_pressed():
	if _check_success():
		timer.stop()
		await _play_finish_animation(true)
		emit_signal("minigame_finished", true)
	else:
		timer.stop()
		await _play_finish_animation(false)
		emit_signal("minigame_finished", false)

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
	await _play_finish_animation(false)
	emit_signal("minigame_finished", false)

func _play_finish_animation(success: bool):
	if success:
		anim.play("Pass")
	else:
		anim.play("Fail")
	return await anim.animation_finished
