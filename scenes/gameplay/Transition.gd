extends CanvasLayer
class_name Transition

@onready var anim := $AnimationPlayer

func play_out():
	anim.play("fade_out")
	return await anim.animation_finished

func play_in():
	anim.play("fade_in")
	return await anim.animation_finished
