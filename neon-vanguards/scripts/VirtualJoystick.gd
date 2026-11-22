extends Control
class_name TouchJoystick

@export var clamp_radius: float = 64.0
@export var deadzone: float = 0.15

var output: Vector2 = Vector2.ZERO
var touch_index: int = -1
var base_pos: Vector2 = Vector2.ZERO
var handle_pos: Vector2 = Vector2.ZERO
var is_active: bool = false

var base_texture: Texture2D = preload("res://assets/art/joystick_base.svg")
var knob_texture: Texture2D = preload("res://assets/art/joystick_knob.svg")

func _ready() -> void:
	base_pos = size / 2.0
	handle_pos = base_pos

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		base_pos = size / 2.0
		if not is_active:
			handle_pos = base_pos
		queue_redraw()

func _draw() -> void:
	# Draw base circle texture
	if base_texture:
		var base_rect := Rect2(base_pos - Vector2(clamp_radius, clamp_radius) * 1.15, Vector2(clamp_radius, clamp_radius) * 2.3)
		draw_texture_rect(base_texture, base_rect, false)
	else:
		draw_circle(base_pos, clamp_radius, Color(0.1, 0.2, 0.4, 0.35))
		draw_arc(base_pos, clamp_radius, 0, TAU, 32, Color(0.3, 0.7, 1.0, 0.6), 3.0)

	# Draw knob texture
	var knob_radius := clamp_radius * 0.48
	if knob_texture:
		var knob_rect := Rect2(handle_pos - Vector2(knob_radius, knob_radius), Vector2(knob_radius, knob_radius) * 2.0)
		var knob_modulate := Color(1, 1, 1, 1.0) if is_active else Color(0.8, 0.9, 1.0, 0.7)
		draw_texture_rect(knob_texture, knob_rect, false, knob_modulate)
	else:
		var handle_color := Color(0.2, 0.9, 1.0, 0.85) if is_active else Color(0.7, 0.8, 0.9, 0.5)
		draw_circle(handle_pos, knob_radius, handle_color)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			is_active = true
			_update_handle(event.position)
		elif not event.pressed and event.index == touch_index:
			_reset_joystick()
	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			_update_handle(event.position)

func _update_handle(pos: Vector2) -> void:
	var diff := pos - base_pos
	var dist := diff.length()
	if dist > clamp_radius:
		diff = diff.normalized() * clamp_radius
	handle_pos = base_pos + diff

	var raw_output := diff / clamp_radius
	if raw_output.length() < deadzone:
		output = Vector2.ZERO
	else:
		output = raw_output
	queue_redraw()

func _reset_joystick() -> void:
	touch_index = -1
	is_active = false
	output = Vector2.ZERO
	handle_pos = base_pos
	queue_redraw()
