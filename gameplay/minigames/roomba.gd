extends Minigame

@onready var roomba = $CanvasLayer/Roomba
@onready var trash_container = $CanvasLayer/TrashContainer
@onready var wave_container = $CanvasLayer/WaveContainer
@onready var timer: GameTimer = $MinigameTimer
@onready var anim = $AnimationPlayer

@onready var music_player = $AudioStreamPlayer2D
@onready var music = preload("res://assets/msfx/minigameMusic/roomba thing.wav")

@onready var roomba_sfx = preload("res://assets/minigames/Roomba/roomba.mp3")

var difficulty_settings = {
	1: {"trash_count": 3, "time_limit": 10.0, "speed": 40.0},
	2: {"trash_count": 4, "time_limit": 8.0, "speed": 55.0},
	3: {"trash_count": 5, "time_limit": 6.0, "speed": 70.0}
}

var remaining_trash := 0
var roomba_target := Vector2.ZERO
var roomba_speed := 0.0
var base_speed := 40.0
var accelerating := false
var bounds := Rect2(0, 0, 200, 200)
var finished := false  # prevent double finish calls

const FADE_TIME = 1.0


func start():
	randomize()
	finished = false
	var s = difficulty_settings.get(difficulty, difficulty_settings[1])

	base_speed = s["speed"]
	accelerating = false

	# Disconnect timer signal if already connected
	if timer.is_connected("time_up", _on_time_up):
		timer.disconnect("time_up", _on_time_up)
	timer.time_up.connect(_on_time_up)

	# Clean up any leftover trash from last round
	for child in trash_container.get_children():
		child.queue_free()

	_spawn_trash(s["trash_count"])
	remaining_trash = s["trash_count"]

	timer.start(s["time_limit"])
	_fade_in_music()


func _spawn_trash(count: int):
	for i in range(count):
		var t = Area2D.new()
		var sprite = Sprite2D.new()
		sprite.texture = preload("res://icon.svg")
		sprite.scale = Vector2(0.15, 0.15)
		var shape = CollisionShape2D.new()
		shape.shape = CircleShape2D.new()
		shape.shape.radius = 6

		t.position = Vector2(randf_range(20, 180), randf_range(20, 180))
		t.add_child(sprite)
		t.add_child(shape)

		# Disconnect any old signal bindings before connecting
		if t.is_connected("body_entered", _on_trash_collected):
			t.disconnect("body_entered", _on_trash_collected)
		t.body_entered.connect(_on_trash_collected.bind(t))

		trash_container.add_child(t)


func _input(event):
	if finished:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_spawn_wave(event.position)
		roomba_target = event.position.clamp(bounds.position, bounds.end)
		roomba_speed = base_speed
		accelerating = true


func _spawn_wave(pos: Vector2):
	var wave = Node2D.new()
	var circle = ColorRect.new()
	circle.size = Vector2(200, 200)
	circle.position = pos - circle.size * 0.5

	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/minigames/Roomba/roomba.gdshader")
	mat.set_shader_parameter("center", Vector2(0.5, 0.5))
	mat.set_shader_parameter("radius", 0.01)
	mat.set_shader_parameter("edge_width", 0.02)
	mat.set_shader_parameter("color", Color(0.4, 0.8, 1.0, 0.5))

	circle.material = mat
	wave.add_child(circle)
	wave.position = Vector2.ZERO
	wave_container.add_child(wave)

	var tween = create_tween()
	tween.tween_property(mat, "shader_parameter/radius", 0.1, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "shader_parameter/color:a", 0.0, 0.2)
	tween.finished.connect(func(): wave.queue_free())


func _process(delta):
	if accelerating:
		var dir = (roomba_target - roomba.position).normalized()
		roomba.position += dir * roomba_speed * delta
		roomba_speed += 40 * delta
		if roomba.position.distance_to(roomba_target) < 4:
			accelerating = false
		roomba.position = roomba.position.clamp(bounds.position, bounds.end)


func _on_trash_collected(body: Node2D, trash: Area2D):
	if finished:
		return
	if body == roomba:
		_play_one_shot_sfx(roomba_sfx, 0.03, 0.25)
		trash.queue_free()
		remaining_trash -= 1

		if remaining_trash <= 0 and not finished:
			finished = true
			timer.stop()
			accelerating = false
			await _fade_out_music()
			await _play_finish_animation(true)
			emit_signal("minigame_finished", true)


func _on_time_up():
	if finished:
		return
	finished = true
	accelerating = false
	timer.stop()
	await _fade_out_music()
	await _play_finish_animation(false)
	emit_signal("minigame_finished", false)


func _play_finish_animation(success: bool):
	if success:
		anim.play("Pass")
	else:
		anim.play("Fail")
	return await anim.animation_finished


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
