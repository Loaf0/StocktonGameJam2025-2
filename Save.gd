extends Node

var save_file : ConfigFile = ConfigFile.new()
const SAVE_PATH : String = "user://save.cfg"

func save_all():
	save_settings()

func save_score():
	print(ProjectSettings.globalize_path("user://save.cfg"))
	save_file.set_value("SCORES", "EASY_SCORE", Settings.EASY_SCORE)
	save_file.set_value("SCORES", "MEDI_SCORE", Settings.MEDI_SCORE)
	save_file.set_value("SCORES", "HARD_SCORE", Settings.HARD_SCORE)
	
	save_file.save(SAVE_PATH)

func load_score():
	var err = save_file.load(SAVE_PATH)
	if err != OK:
		return
	
	Settings.EASY_SCORE = save_file.get_value("SCORES", "EASY_SCORE")
	Settings.MEDI_SCORE = save_file.get_value("SCORES", "MEDI_SCORE")
	Settings.HARD_SCORE = save_file.get_value("SCORES", "HARD_SCORE")

func save_settings():
	print(ProjectSettings.globalize_path("user://save.cfg"))
	save_file.set_value("Settings", "MUSIC_VOLUME_DB", Settings.MUSIC_VOLUME_DB)
	
	save_file.save(SAVE_PATH)

func load_settings():
	var err = save_file.load(SAVE_PATH)
	if err != OK:
		return
	
	Settings.MUSIC_VOLUME_DB = save_file.get_value("Settings", "MUSIC_VOLUME_DB", .75)
