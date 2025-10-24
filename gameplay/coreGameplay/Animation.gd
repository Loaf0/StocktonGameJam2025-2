extends CanvasLayer
class_name FlavorAnimation

@export var flavor_type : String = "Pass"
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var label : Label = $Control/Label
@onready var health_display: Control = $Control/HealthDisplay

func _ready() -> void:
	$Control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func play(success: bool, health: int, speed : float = 1):
	flavor_type = "Pass" if success else "Fail"
	label.text = flavor_type
	anim.speed_scale = speed
	_update_health(health)
	anim.play(flavor_type)
	return anim.animation_finished

func _update_health(health: int) -> void:
	for i in health_display.get_children():
		i.visible = i.get_index() < health
