extends CanvasLayer

signal restart_requested
signal main_menu_requested

@onready var title_label = $TitleLabel
@onready var score_label = $ScoreLabel
@onready var restart_button = $RestartButton
@onready var main_menu_button = $MainMenuButton

func _ready():
	restart_button.pressed.connect(func(): restart_requested.emit())
	main_menu_button.pressed.connect(func(): main_menu_requested.emit())

func show_game_over(final_score: int, difficulty: String):
	title_label.text = "Game Over"
	score_label.text = str(final_score)
	visible = true
