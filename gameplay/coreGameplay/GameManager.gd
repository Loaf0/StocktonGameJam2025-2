extends Node

@export_dir var minigames_dir: String = "res://gameplay/minigames/"
@export var transition_scene: PackedScene = preload("res://gameplay/transitions/JailTransition.tscn")
@export var flavor_scene: PackedScene = preload("res://gameplay/animations/TestAnimation.tscn")
@export var health: int = 3
@export var recent_queue_size: int = 3
@export var base_speed: float = 1.0
@export var base_difficulty: float = 1.0
@export var speed_increment: float = 0.1

var minigame_paths: Array = []
var recent_minigames: Array = []
var current_index := -1
var current_game: Node = null
var current_speed := base_speed
var current_difficulty := base_difficulty
var transition: Transition = null
var last_minigame_success: bool = true

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
	if current_game:
		current_game.queue_free()
	if health <= 0:
		game_over()
		return
	await transition.play_out()
	if current_index >= 0:
		var flavor = flavor_scene.instantiate()
		add_child(flavor)
		await flavor.play(last_minigame_success, health)
		flavor.queue_free()
	var scene_path = _choose_next_minigame()
	if not scene_path:
		push_error("No minigames")
		return
	var scene = load(scene_path)
	if not scene:
		push_error("Could not load scene: %s" % scene_path)
		load_next_minigame()
		return
	current_game = scene.instantiate()
	add_child(current_game)
	current_game.minigame_finished.connect(_on_minigame_finished)
	if "speed" in current_game:
		current_game.speed = current_speed
	if "difficulty" in current_game:
		current_game.difficulty = current_difficulty
	current_game.start()
	print("Starting : ", scene_path)
	await transition.play_in()

func _on_minigame_finished(success: bool):
	last_minigame_success = success
	if success:
		current_speed += speed_increment
	else:
		health -= 1
		print("Health : ", health)
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
