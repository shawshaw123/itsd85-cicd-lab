extends Area2D

@export var heal_amount: int = 35
@export var respawn_time: float = 12.0

var is_available: bool = true
var base_y: float = 0.0
var time_passed: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not is_available:
		return
	time_passed += delta * 3.0
	position.y = base_y + sin(time_passed) * 5.0
	queue_redraw()

func _draw() -> void:
	if not is_available:
		return
	# Medkit / Nano-Stim Pill icon
	draw_circle(Vector2.ZERO, 18.0, Color(0.1, 0.8, 0.4, 0.35))
	draw_rect(Rect2(-12, -12, 24, 24), Color(0.95, 0.95, 1.0), true)
	# Red Cross
	draw_rect(Rect2(-8, -3, 16, 6), Color(0.9, 0.2, 0.2), true)
	draw_rect(Rect2(-3, -8, 6, 16), Color(0.9, 0.2, 0.2), true)

func _on_body_entered(body: Node2D) -> void:
	if not is_available:
		return
	if body is NeonPlayer:
		if body.current_health < body.max_health:
			body.current_health = min(body.max_health, body.current_health + heal_amount)
			body.health_changed.emit(body.current_health, body.max_health)
			_consume()

func _consume() -> void:
	AudioManager.play_sfx("pickup")
	is_available = false
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	queue_redraw()
	var timer := get_tree().create_timer(respawn_time)
	timer.timeout.connect(_respawn)

func _respawn() -> void:
	is_available = true
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	queue_redraw()
