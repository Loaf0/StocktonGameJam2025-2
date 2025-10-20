extends CanvasLayer
class_name GameTimer

signal time_up

@export var duration: float = 5.0
@export var auto_start: bool = true
@export var color_good: Color = Color.GREEN
@export var color_warn: Color = Color.YELLOW
@export var color_critical: Color = Color.RED

var running: bool = false
var elapsed: float = 0.0

@onready var bar: ProgressBar = $Control/ProgressBar

func _ready():
	bar.value = 100
	if auto_start:
		start()

func start(time_override: float = -1.0):
	if time_override > 0:
		duration = time_override
	elapsed = 0.0
	running = true
	bar.value = 100
	bar.visible = true

func stop():
	running = false

func reset():
	elapsed = 0.0
	bar.value = 100

func _process(delta: float):
	if not running:
		return

	elapsed += delta
	var ratio = clamp(elapsed / duration, 0.0, 1.0)
	bar.value = (1.0 - ratio) * 100.0

	var stylebox_fill = bar.get("theme_override_styles/fill")
	if stylebox_fill:
		if ratio < 0.5:
			stylebox_fill.bg_color = color_good
		elif ratio < 0.8:
			stylebox_fill.bg_color = color_warn
		else:
			stylebox_fill.bg_color = color_critical

	if elapsed >= duration:
		running = false
		bar.value = 0
		emit_signal("time_up")
