extends Node
class_name Minigame

signal minigame_finished(success: bool)

@export var speed : float = 1.0
@export var difficulty : int = 1

func start():
	pass

func finish(success: bool):
	emit_signal("minigame_finished", success)
