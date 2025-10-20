extends CanvasLayer
class_name FlavorAnimation

@export var flavor_type : String = "Pass"
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var label : Label = $Label
@onready var health_display: Control = $HealthDisplay

func play(sucess : bool, health : int):
	flavor_type = "Pass" if sucess else "Fail"
	label.text = "Pass" if sucess else "Fail"
	_update_health(health)
	anim.play(flavor_type)
	return await anim.animation_finished

func _update_health(health: int) -> void:
	for i in health_display.get_children():
		i.visible = i.get_index() < health
