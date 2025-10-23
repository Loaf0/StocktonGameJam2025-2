extends Minigame

@onready var roomba = $CanvasLayer/Roomba
@onready var trash_container = $CanvasLayer/TrashContainer
@onready var wave_container = $CanvasLayer/WaveContainer
@onready var timer: GameTimer = $MinigameTimer
@onready var anim = $AnimationPlayer

@onready var music_player = $AudioStreamPlayer2D
@onready var music = preload("res://assets/msfx/minigameMusic/roomba thing.wav")

@onready var roomba_sfx = preload("res://assets/minigames/Roomba/roomba.mp3")
@onready var ping_sfx = preload("res://assets/minigames/Roomba/ping.mp3")

@onready var extra_boundry1 = $CanvasLayer/TableWithCarpet/StaticBody2D2/CollisionShape2D
@onready var extra_boundry2 = $CanvasLayer/Lazyboy/StaticBody2D/CollisionShape2D


var difficulty_settings = {
	1: {"trash_count": 3, "time_limit": 10.0, "speed": 40.0},
	2: {"trash_count": 4, "time_limit": 9.0, "speed": 55.0},
	3: {"trash_count": 5, "time_limit": 8.0, "speed": 70.0}
}

var remaining_trash := 0
var roomba_target := Vector2.ZERO
var roomba_speed := 0.0
var base_speed := 40.0
var accelerating := false
var turning := false
var bounds := Rect2(30, 30, 140, 140)
var finished := false 

const FADE_TIME = 1.0
const PAUSE_AFTER_WALL = 0.1
const TURN_SPEED = 6.0
const TURN_DELAY = 0.2

var obstacles: Array = []

func start():
	randomize()
	finished = false
	var s = difficulty_settings.get(difficulty, difficulty_settings[1])

	base_speed = s["speed"]
	accelerating = false

	if timer.is_connected("time_up", _on_time_up):
		timer.disconnect("time_up", _on_time_up)
	timer.time_up.connect(_on_time_up)

	for child in trash_container.get_children():
		child.queue_free()

	obstacles = [
		_get_shape_rect(extra_boundry1),
		_get_shape_rect(extra_boundry2)
	]

	_spawn_trash(s["trash_count"])
	remaining_trash = s["trash_count"]

	timer.start(s["time_limit"])
	_fade_in_music()


func _spawn_trash(count: int):
	var attempts = 0
	while trash_container.get_child_count() < count and attempts < 500:
		attempts += 1
		var pos = Vector2(randf_range(bounds.position.x, bounds.end.x),
						  randf_range(bounds.position.y, bounds.end.y))
		var radius = 6.0
		var valid = true

		for rect in obstacles:
			if rect.has_point(pos):
				valid = false
				break

		if not valid:
			continue

		var t = Area2D.new()
		var sprite = Sprite2D.new()
		sprite.texture = preload("res://assets/minigames/Roomba/Trash.png")
		var shape = CollisionShape2D.new()
		shape.shape = CircleShape2D.new()
		shape.shape.radius = radius

		t.position = pos
		t.add_child(sprite)
		t.add_child(shape)
		t.body_entered.connect(_on_trash_collected.bind(t))
		trash_container.add_child(t)

func _input(event):
	if finished:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var target = event.position.clamp(bounds.position, bounds.end)
		_spawn_wave(target)
		roomba_target = target
		_redirect_to_target()

func _spawn_wave(pos: Vector2):
	_play_one_shot_sfx(ping_sfx, 0.03, 0.05)
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
		var old_pos = roomba.position
		var dir = (roomba_target - roomba.position).normalized()
		roomba.position += dir * roomba_speed * delta
		roomba_speed += 40 * delta

		var clamped = roomba.position.clamp(bounds.position, bounds.end)
		if clamped != roomba.position:
			roomba.position = clamped
			await _pause_after_collision()
			return

		for rect in obstacles:
			if rect.has_point(roomba.position):
				roomba.position = old_pos
				await _pause_after_collision()
				return

		if roomba.position.distance_to(roomba_target) < 4:
			accelerating = false


func _pause_after_collision():
	if finished:
		return
	accelerating = false
	roomba_speed = 0.0
	await get_tree().create_timer(PAUSE_AFTER_WALL).timeout
	if not finished and roomba_target != roomba.position:
		roomba_speed = base_speed
		accelerating = true

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
	

func _redirect_to_target():
	turning = false
	accelerating = false
	roomba_speed = 0.0

	var desired_angle = (roomba_target - roomba.position).angle()
	var angle_diff = angular_distance(roomba.rotation, desired_angle)
	var duration = abs(angle_diff) / TURN_SPEED

	var tween = create_tween()
	tween.tween_property(roomba, "rotation", roomba.rotation + angle_diff, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished

	await get_tree().create_timer(TURN_DELAY).timeout
	if not finished:
		roomba_speed = base_speed
		accelerating = true


func angular_distance(from: float, to: float) -> float:
	var diff = to - from
	while diff > PI:
		diff -= PI * 2
	while diff <= -PI:
		diff += PI * 2
	return diff

func _get_shape_rect(shape_node: CollisionShape2D) -> Rect2:
	if shape_node.shape is RectangleShape2D:
		var rect_shape: RectangleShape2D = shape_node.shape
		var pos = shape_node.global_position - rect_shape.extents
		return Rect2(pos, rect_shape.extents * 2)
	else:
		return Rect2()
