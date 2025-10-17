extends Minigame

@onready var win_button: Button = $Control/win
@onready var lose_button: Button = $Control/fail

func start():
	win_button.pressed.connect(_on_win_pressed)
	lose_button.pressed.connect(_on_lose_pressed)

func _on_win_pressed():
	finish(true)

func _on_lose_pressed():
	finish(false)
