extends Area2D

@export var speed: float = 800.0
@export var damage: int = 25
@export var lifetime: float = 2.0
@export var is_explosive: bool = false
@export var blast_radius: float = 90.0

var direction: Vector2 = Vector2.RIGHT
var shooter_id: int = 0 # 0: local player, -1: bot, peer_id > 0: network peer
var shooter_node: Node2D = null
var weapon_type: String = "rifle"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _draw() -> void:
	if is_explosive:
		# Rocket projectile
		draw_rect(Rect2(-12, -5, 24, 10), Color(0.9, 0.25, 0.1), true)
		draw_circle(Vector2(12, 0), 5.0, Color(1, 0.85, 0.2))
		draw_circle(Vector2(-12, 0), 4.0, Color(1, 0.45, 0.1))
	elif weapon_type == "sniper":
		# High-energy railgun beam
		draw_line(Vector2(-28, 0), Vector2(28, 0), Color(0.1, 0.9, 1.0, 1.0), 5.0)
		draw_line(Vector2(-28, 0), Vector2(28, 0), Color(1, 1, 1, 1.0), 2.5)
	elif weapon_type == "shotgun":
		# Glowing buckshot pellet
		draw_circle(Vector2.ZERO, 4.0, Color(1, 0.8, 0.2))
		draw_circle(Vector2.ZERO, 2.5, Color(1, 1, 1))
	else:
		# Standard plasma laser bolt
		draw_line(Vector2(-14, 0), Vector2(14, 0), Color(0.2, 0.9, 1.0, 0.95), 6.0)
		draw_circle(Vector2(12, 0), 4.5, Color(1, 1, 1, 1.0))

func _on_body_entered(body: Node2D) -> void:
	# Avoid hitting shooter
	if body == shooter_node:
		return
	if body is NeonPlayer and body.network_id == shooter_id and shooter_id != 0:
		return
	if shooter_id == 0 and body is NeonPlayer and shooter_node == body:
		return
	if shooter_id == -1 and body is NeonEnemy:
		return

	if is_explosive:
		_explode()
	else:
		if body.has_method("take_damage"):
			body.take_damage(damage, shooter_id)
		queue_free()

func _explode() -> void:
	AudioManager.play_sfx("explosion")
	# Splash damage in blast radius
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = blast_radius
	query.shape = circle
	query.transform = global_transform
	query.collision_mask = 3

	var results := space_state.intersect_shape(query)
	for hit in results:
		var collider = hit.collider
		if collider and collider.has_method("take_damage"):
			var dist := global_position.distance_to(collider.global_position)
			var falloff := clampf(1.0 - (dist / blast_radius), 0.3, 1.0)
			var final_damage := int(damage * falloff)
			collider.take_damage(final_damage, shooter_id)

	queue_free()
