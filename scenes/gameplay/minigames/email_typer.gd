extends Node2D

signal minigame_finished(success: bool)

@export var emails := [
	"Hi anthony this minigame idea is almost working.",
	"This email minigame is really hard.",
	"Thanks for subscribing to kagurabachi weekly facts.",
	"Hi mom love gamejam guy"
]

@export var num_letters_to_type := 5

@onready var label_email := $CanvasLayer/Label
@onready var grid := $CanvasLayer/GridContainer
@onready var timer := $MinigameTimer
@onready var anim := $AnimationPlayer

var target_text := ""
var typed_text := ""
var start_index := 0
var difficulty := 1
var speed := 1.0
var current_index := 0
var shuffled_keys: Array = []
var all_letters := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

func start():
	num_letters_to_type = 5 + 2 * difficulty
	label_email.bbcode_enabled = true
	randomize()
	var email : String = emails[randi() % emails.size()]
	target_text = email.strip_edges()
	start_index = max(target_text.length() - num_letters_to_type, 0)
	typed_text = target_text.substr(0, start_index)
	current_index = start_index
	_update_label()
	_setup_keyboard()
	_setup_timer()

func _setup_keyboard():
	for child in grid.get_children():
		child.queue_free()
	
	shuffled_keys = all_letters.split("")
	shuffled_keys.shuffle()
	
	for letter in shuffled_keys:
		var btn := Button.new()
		btn.text = letter
		btn.pressed.connect(_on_key_pressed.bind(letter))
		grid.add_child(btn)

func _setup_timer():
	var base_time := 15.0
	var time_mod := 1.0
	match difficulty:
		1:
			time_mod = 1.0
		2:
			time_mod = 0.9
		3:
			time_mod = 0.8
	timer.start(base_time * time_mod)
	timer.time_up.connect(_on_time_up)

func _on_key_pressed(letter: String) -> void:
	if current_index >= target_text.length():
		return

	_skip_non_letters()
	if current_index >= target_text.length():
		timer.stop()
		await _play_finish_animation(true)
		emit_signal("minigame_finished", true)
		return

	var expected := target_text[current_index].to_upper()
	if letter == expected:
		current_index += 1
		typed_text = target_text.substr(0, current_index)
	else:
		typed_text += "[X]"

	_update_label()
	_skip_non_letters()

	if current_index >= target_text.length():
		timer.stop()
		await _play_finish_animation(true)
		emit_signal("minigame_finished", true)

func _skip_non_letters():
	while current_index < target_text.length():
		var c := target_text[current_index].to_upper()
		if c >= "A" and c <= "Z":
			break
		current_index += 1

func _on_time_up() -> void:
	timer.stop()
	await _play_finish_animation(false)
	emit_signal("minigame_finished", false)

func _play_finish_animation(success: bool):
	if success:
		anim.play("Pass")
	else:
		anim.play("Fail")
	return await anim.animation_finished

func _update_label():
	var untyped = target_text.substr(current_index, target_text.length() - current_index)
	label_email.bbcode_text = typed_text + "[color=gray]" + untyped + "[/color]_"
