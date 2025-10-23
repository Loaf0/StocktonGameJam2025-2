extends Minigame

@export var emails := [
	"Hi anthony this minigame idea is almost working.",
	"This email minigame is really hard.",
	"Thanks for subscribing to kagurabachi weekly facts.",
	"Hi mom love gamejam guy"
]

@export var num_letters_to_type := 5

@onready var music_player = $AudioStreamPlayer2D
@onready var music = preload("res://assets/msfx/minigameMusic/email thing.wav")

@onready var key_press_sfx = preload("res://assets/minigames/EmailTyper/keypress.mp3")

@onready var label_email := $CanvasLayer/Label
@onready var grid := $CanvasLayer/GridContainer
@onready var timer := $MinigameTimer
@onready var anim := $AnimationPlayer

var playing := false

const CHAR_ATLAS_STRING = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const CHAR_WIDTH = 16.0
const CHAR_HEIGHT = 16.0

var target_text := ""
var typed_text := ""
var start_index := 0
var current_index := 0
var shuffled_keys: Array = []
var all_letters := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
var highlight_active := false

const FADE_TIME = 1.0

const KEY_SHADER = preload("res://assets/minigames/EmailTyper/EmailTyper.gdshader")

func start():
	playing = true
	num_letters_to_type = 4 + (2 * difficulty)
	label_email.bbcode_enabled = true
	randomize()
	var email : String = emails[randi() % emails.size()]
	target_text = email.strip_edges()
	start_index = max(target_text.length() - num_letters_to_type, 0)
	typed_text = target_text.substr(0, start_index)
	current_index = start_index
	highlight_active = false
	_update_label()
	_setup_keyboard()
	_setup_timer()
	_fade_in_music()

func _process(_delta):
	if not timer.running or highlight_active:
		return
	
	var halfway_point = timer.duration / 2.0
	
	if timer.elapsed >= halfway_point:
		highlight_active = true
		_update_keyboard_glow()

func _setup_keyboard():
	var buttons = grid.get_children()
	
	shuffled_keys = all_letters.split("")
	shuffled_keys.shuffle()
	
	for i in range(buttons.size()):
		var btn = buttons[i]
		var letter = shuffled_keys[i % shuffled_keys.size()]
		
		var btn_sprite = btn.get_node("Control/Sprite2D")
		
		if btn_sprite:
			var char_index = CHAR_ATLAS_STRING.find(letter)
			
			if char_index != -1:
				btn_sprite.region_enabled = true
				var x_offset = float(char_index) * CHAR_WIDTH
				btn_sprite.region_rect = Rect2(x_offset, 0, CHAR_WIDTH, CHAR_HEIGHT)
			
			var mat = ShaderMaterial.new()
			mat.shader = KEY_SHADER
			btn_sprite.material = mat
			
		btn.pressed.connect(_on_key_pressed.bind(letter))

	_update_keyboard_glow()

func _setup_timer():
	var base_time := 12.0
	var time_mod := 1.0
	match difficulty:
		1:
			time_mod = 1.0
		2:
			time_mod = 0.9
		3:
			time_mod = 0.8
	timer.start(base_time * time_mod)
	timer.time_up.connect(_on_time_up)

func _update_keyboard_glow():
	var untyped_section = target_text.substr(current_index).to_upper()
	var target_letters = {}
	
	for i in range(untyped_section.length()):
		var curr_char = untyped_section[i]
		if curr_char >= "A" and curr_char <= "Z":
			target_letters[curr_char] = true

	var highlight_color = Color.WHITE
	var default_color = Color.BLACK
	
	for btn in grid.get_children():
		var sprite = btn.get_node("Control/Sprite2D")
		
		if not sprite or not sprite.material is ShaderMaterial: continue
		
		var material = sprite.material as ShaderMaterial
		
		var region_x = sprite.region_rect.position.x
		var char_index = int(round(region_x / CHAR_WIDTH))
		
		if char_index < 0 or char_index >= CHAR_ATLAS_STRING.length():
			continue
			
		var letter = CHAR_ATLAS_STRING[char_index]
		
		var target_color = default_color
		if highlight_active and letter in target_letters:
			target_color = highlight_color
		
		material.set_shader_parameter("Color_Tint", target_color)

func _on_key_pressed(letter: String) -> void:
	if not playing:
		return
	if current_index >= target_text.length():
		return

	_play_one_shot_sfx(key_press_sfx, 0.02)

	while current_index < target_text.length():
		var c := target_text[current_index].to_upper()
		if c >= "A" and c <= "Z":
			break
		current_index += 1
		typed_text = target_text.substr(0, current_index)

	if current_index < target_text.length():
		var expected := target_text[current_index].to_upper()
		if letter == expected:
			current_index += 1
			typed_text = target_text.substr(0, current_index)
			while current_index < target_text.length() and not (target_text[current_index].to_upper() >= "A" and target_text[current_index].to_upper() <= "Z"):
				current_index += 1
				typed_text = target_text.substr(0, current_index)

	_update_label()

	if highlight_active:
		_update_keyboard_glow()

	if current_index >= target_text.length():
		timer.stop()
		await _fade_out_music()
		await _play_finish_animation(true)
		emit_signal("minigame_finished", true)


func _skip_non_letters():
	while current_index < target_text.length():
		var c := target_text[current_index].to_upper()
		if c >= "A" and c <= "Z":
			break
		current_index += 1

func _on_time_up() -> void:
	if not playing:
		return
	playing = false
	timer.stop()
	_fade_out_music()
	await _play_finish_animation(false)
	emit_signal("minigame_finished", false)

func _play_finish_animation(success: bool):
	if success:
		anim.play("Pass")
	else:
		anim.play("Fail")
	return await anim.animation_finished

func _update_label():
	var untyped = target_text.substr(current_index, target_text.length() - current_index)
	label_email.bbcode_text = typed_text + "[color=#6b6b6b]" + untyped + "[/color]_"

func _fade_in_music():
	music_player.stream = music
	music_player.volume_db = -80.0
	music_player.play()
	music_player.pitch_scale = Settings.get_audio_speed_scale(speed)
	
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", Settings.MUSIC_VOLUME_DB, FADE_TIME)
	
func _fade_out_music():
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, FADE_TIME)
	await tween.finished
	music_player.stop()
