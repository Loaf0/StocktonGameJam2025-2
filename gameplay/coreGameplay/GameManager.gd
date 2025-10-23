extends Node

@onready var audio_player = $AudioStreamPlayer2D
@onready var transition_mfx = preload("res://assets/msfx/transitionTheme/intermission thing.wav")
@onready var pass_mfx = preload("res://assets/msfx/transitionTheme/pass thing.wav")
@onready var fail_mfx = preload("res://assets/msfx/transitionTheme/fail thing.wav")

@export_dir var minigames_dir: String = "res://gameplay/minigames/"
@export var transition_scene: PackedScene = preload("res://gameplay/transitions/JailTransition.tscn")
@export var flavor_scene: PackedScene = preload("res://gameplay/animations/TestAnimation.tscn")
@export var forced_first_minigame: PackedScene
@export var health: int = 3
@export var recent_queue_size: int = 3
@export var base_speed: float = 1.0
@export var base_difficulty: int = 1
@export var speed_increment: float = 0.075

var minigame_paths: Array = []
var recent_minigames: Array = []
var current_index := -1
var current_game: Node = null
var current_speed := base_speed
var current_difficulty := base_difficulty
var transition: Transition = null
var last_minigame_success: bool = true
var first_forced := true
var loading_next := false

func _ready():
	minigame_paths = _get_all_minigames(minigames_dir)
	print("Found %d minigames" % minigame_paths.size())
	transition = transition_scene.instantiate()
	add_child(transition)
	load_next_minigame()

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
	if loading_next:
		print("⚠️ load_next_minigame called while already loading; ignoring.")
		return
	loading_next = true

	if current_game:
		if current_game.is_connected("minigame_finished", Callable(self, "_on_minigame_finished")):
			current_game.disconnect("minigame_finished", Callable(self, "_on_minigame_finished"))
		current_game.queue_free()
		current_game = null
		await get_tree().process_frame

	if health <= 0:
		game_over()
		loading_next = false
		return

	await transition.play_out()

	if not first_forced:
		var flavor = flavor_scene.instantiate()
		add_child(flavor)
		await flavor.play(last_minigame_success, health)
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
		loading_next = false
		return

	current_game = scene.instantiate()
	add_child(current_game)

	if not current_game.is_connected("minigame_finished", Callable(self, "_on_minigame_finished")):
		current_game.minigame_finished.connect(_on_minigame_finished)

	current_game.speed = current_speed
	current_game.difficulty = current_difficulty
	current_game.start()

	print("minigame:", scene.resource_path)
	await transition.play_in()

	loading_next = false

func _on_minigame_finished(success: bool):
	if loading_next:
		return

	audio_player.pitch_scale = current_speed
	last_minigame_success = success

	if success:
		audio_player.stream = pass_mfx
		current_speed += speed_increment
	else:
		audio_player.stream = fail_mfx
		health -= 1
		print("Health:", health)

	audio_player.play()

	if current_index >= 0:
		recent_minigames.append(minigame_paths[current_index])
	if recent_minigames.size() > recent_queue_size:
		recent_minigames.pop_front()

	await load_next_minigame()

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
