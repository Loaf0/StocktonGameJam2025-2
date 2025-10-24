extends CanvasLayer

signal restart_requested
signal main_menu_requested

@onready var title_label = $Difficulty
@onready var high_score_label = $HighScore
@onready var score_label = $ScoreLabel
@onready var restart_button = $RestartButton
@onready var main_menu_button = $MainMenuButton

func _ready():
	restart_button.pressed.connect(func(): restart_requested.emit())
	main_menu_button.pressed.connect(func(): main_menu_requested.emit())

func show_game_over(final_score: int, difficulty: String):
	title_label.text = difficulty

	var high_score := 0
	match difficulty.to_lower():
		"easy":
			high_score = Settings.EASY_SCORE
		"medium":
			high_score = Settings.MEDI_SCORE
		"hard":
			high_score = Settings.HARD_SCORE

	high_score_label.text = "%03d" % high_score
	score_label.text = "%03d" % final_score
	visible = true
