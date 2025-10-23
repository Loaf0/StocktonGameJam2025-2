extends Node

@onready var audio_player = $AudioStreamPlayer2D
@onready var transition_mfx = preload("res://assets/msfx/transitionTheme/intermission thing.wav")
@onready var pass_mfx = preload("res://assets/msfx/transitionTheme/pass thing.wav")
@onready var fail_mfx = preload("res://assets/msfx/transitionTheme/fail thing.wav")

@export var game_over_scene: PackedScene = preload("res://gameplay/menus/GameOverScreen.tscn")
var game_over_screen: CanvasLayer

@export_dir var minigames_dir: String = "res://gameplay/minigames/"
@export var transition_scene: PackedScene = preload("res://gameplay/transitions/JailTransition.tscn")
@export var flavor_scene: PackedScene = preload("res://gameplay/animations/TestAnimation.tscn")
@export var forced_first_minigame: PackedScene
@export var health: int = 3
@export var recent_queue_size: int = 3
@export var base_speed: float = 1.0
@export var base_difficulty: int = 1
@export var speed_increment: float = 0.1

var minigame_paths: Array = []
var recent_minigames: Array = []
var current_index := -1
var current_game: Node = null
var current_speed := base_speed
var current_difficulty := base_difficulty
var transition: Transition = null
var last_minigame_success: bool = true
var first_forced := true

var run_score: int = 0

func _ready():
	minigame_paths = _get_all_minigames(minigames_dir)
	print("Found %d minigames" % minigame_paths.size())
	transition = transition_scene.instantiate()
	add_child(transition)
	load_next_minigame()
	current_speed = base_speed
	current_difficulty = Settings.CURRENT_DIFF

func _get_all_minigames(path: String) -> Array:
	var result: Array = []
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path = path + "/" + file_name
			if dir.current_is_dir() and not file_name.begins_with("."):
				result += _get_all_minigames(full_path)
			elif file_name.ends_with(".tscn"):
				result.append(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
	return result

func load_next_minigame():
	if current_game:
		current_game.queue_free()
	if health <= 0:
		game_over()
		return
	await transition.play_out()
	
	if not first_forced:
		var flavor = flavor_scene.instantiate()
		add_child(flavor)
		#await flavor.play(last_minigame_success, health)
		flavor.play(last_minigame_success, health)
		await audio_player.finished
		audio_player.stream = transition_mfx
		audio_player.play()
		await get_tree().create_timer(transition_mfx.get_length() - 0.5).timeout
		flavor.queue_free()

	var scene: PackedScene
	if first_forced and forced_first_minigame:
		scene = forced_first_minigame
		first_forced = false
	else:
		var path = _choose_next_minigame()
		scene = load(path)
	if not scene:
		push_error("Failed to load minigame")
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
		recent_minigames.append(minigame_paths[current_index])
	if recent_minigames.size() > recent_queue_size:
		recent_minigames.pop_front()
	load_next_minigame()

func _choose_next_minigame() -> String:
	var available = minigame_paths.filter(func(path):
		return not recent_minigames.has(path)
	)
	var temp_queue = recent_minigames.duplicate()
	while available.is_empty() and temp_queue.size() > 0:
		temp_queue.pop_front()
		available = minigame_paths.filter(func(path):
			return not temp_queue.has(path)
	)
	if available.is_empty():
		recent_minigames.clear()
		available = minigame_paths.duplicate()
	if available.is_empty():
		return ""
	var choice = available[randi() % available.size()]
	current_index = minigame_paths.find(choice)
	return choice

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
	health = 3
	current_speed = base_speed
	current_difficulty = base_difficulty
	load_next_minigame()

func _on_main_menu_requested():
	get_tree().change_scene_to_file("res://gameplay/menus/MainMenu.tscn")
