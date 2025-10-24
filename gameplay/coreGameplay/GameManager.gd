extends Node

@onready var audio_player = $AudioStreamPlayer2D
@onready var transition_mfx = preload("res://assets/msfx/transitionTheme/intermission thing.wav")
@onready var pass_mfx = preload("res://assets/msfx/transitionTheme/pass thing.wav")
@onready var fail_mfx = preload("res://assets/msfx/transitionTheme/fail thing.wav")

@export var game_over_scene: PackedScene = preload("res://gameplay/menus/GameOverScreen.tscn")
var game_over_screen: CanvasLayer

@export var transition_scene: PackedScene = preload("res://gameplay/transitions/JailTransition.tscn")
@export var flavor_scene: PackedScene = preload("res://gameplay/animations/TestAnimation.tscn")
@export var forced_first_minigame: PackedScene

@export var minigame_scenes: Array[PackedScene] = [
	preload("res://gameplay/minigames/Catapult.tscn"),
	preload("res://gameplay/minigames/EmailTyper.tscn"),
	preload("res://gameplay/minigames/GrassCutter.tscn"),
	preload("res://gameplay/minigames/Oven.tscn"),
	preload("res://gameplay/minigames/RoboRepair.tscn"),
	preload("res://gameplay/minigames/roomba.tscn"),
]

@export var health: int = 3
@export var recent_queue_size: int = 3
@export var base_speed: float = 1.0
@export var base_difficulty: int = 1
@export var speed_increment: float = 0.1

var recent_minigames: Array = []
var current_index := -1
var current_game: Node = null
var current_speed := base_speed
var current_difficulty := base_difficulty
var transition: Transition = null
var last_minigame_success: bool = true
var first_forced := true
var run_score: int = 0
var first_game = true


func _ready():
	first_game = true
	print("Loaded %d minigames (explicit reference)" % minigame_scenes.size())
	transition = transition_scene.instantiate()
	add_child(transition)
	load_next_minigame()
	current_speed = base_speed
	current_difficulty = Settings.CURRENT_DIFF


func load_next_minigame():
	if audio_player.playing:
		await audio_player.finished
	transition.play_out()
	await get_tree().create_timer(0.4).timeout
	if current_game:
		current_game.queue_free()
	if health <= 0:
		game_over()
		return

	
	
	if !first_game:
		var flavor = flavor_scene.instantiate()
		add_child(flavor)
		flavor.play(last_minigame_success, health)
		audio_player.stream = transition_mfx
		audio_player.play()
		await audio_player.finished
		flavor.queue_free()

	var scene: PackedScene
	if first_forced and forced_first_minigame:
		scene = forced_first_minigame
		first_forced = false
	else:
		scene = _choose_next_minigame()
	if not scene:
		push_error("Failed to load minigame (scene is null)")
		return

	current_game = scene.instantiate()
	add_child(current_game)
	current_game.minigame_finished.connect(_on_minigame_finished)
	current_game.speed = current_speed
	current_game.difficulty = current_difficulty
	current_game.start()
	print("Starting minigame: ", scene.resource_path)
	await transition.play_in()


func _on_minigame_finished(success: bool):
	first_game = false
	audio_player.pitch_scale = Settings.get_audio_speed_scale(current_speed)
	last_minigame_success = success
	if success:
		run_score += 1
		audio_player.stream = pass_mfx
		current_speed += speed_increment
	else:
		audio_player.stream = fail_mfx
		health -= 1
		print("Health : ", health)
	audio_player.play()
	if current_index >= 0:
		recent_minigames.append(current_index)
	if recent_minigames.size() > recent_queue_size:
		recent_minigames.pop_front()
	load_next_minigame()


func _choose_next_minigame() -> PackedScene:
	var available = []
	for i in range(minigame_scenes.size()):
		if not recent_minigames.has(i):
			available.append(i)
	var temp_queue = recent_minigames.duplicate()
	while available.is_empty() and temp_queue.size() > 0:
		temp_queue.pop_front()
		for i in range(minigame_scenes.size()):
			if not temp_queue.has(i):
				available.append(i)
	if available.is_empty():
		recent_minigames.clear()
		for i in range(minigame_scenes.size()):
			available.append(i)
	if available.is_empty():
		push_error("No available minigames to load!")
		return null
	var choice_index = available[randi() % available.size()]
	current_index = choice_index
	return minigame_scenes[choice_index]


func game_over():
	await transition.play_out()

	var difficulty_name := ""
	match current_difficulty:
		1:
			difficulty_name = "Easy"
			if run_score > Settings.EASY_SCORE:
				Settings.EASY_SCORE = run_score
		2:
			difficulty_name = "Medium"
			if run_score > Settings.MEDI_SCORE:
				Settings.MEDI_SCORE = run_score
		3:
			difficulty_name = "Hard"
			if run_score > Settings.HARD_SCORE:
				Settings.HARD_SCORE = run_score

	var save_manager = get_node_or_null("/root/Save")
	if save_manager:
		save_manager.save_score()

	game_over_screen = game_over_scene.instantiate()
	add_child(game_over_screen)
	game_over_screen.show_game_over(run_score, difficulty_name)

	game_over_screen.restart_requested.connect(_on_restart_requested)
	game_over_screen.main_menu_requested.connect(_on_main_menu_requested)

func _on_restart_requested():
	game_over_screen.queue_free()
	get_tree().change_scene_to_file("res://gameplay/coreGameplay/Main.tscn")

func _on_main_menu_requested():
	get_tree().change_scene_to_file("res://gameplay/menus/MainMenu.tscn")
