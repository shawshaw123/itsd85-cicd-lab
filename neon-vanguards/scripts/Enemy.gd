extends CharacterBody2D
class_name NeonEnemy

@export var max_health: int = 50
@export var speed: float = 160.0
@export var fire_interval: float = 2.0
@export var is_boss: bool = false

var current_health: int
var is_dead: bool = false
var player_target: Node2D = null
var fire_timer: float = 0.0

@onready var body_sprite: Sprite2D = $BodySprite
@onready var gun_node: Node2D = $Gun
@onready var gun_sprite: Sprite2D = $Gun/GunSprite
@onready var muzzle_node: Marker2D = $Gun/Muzzle
@onready var hp_bar: ProgressBar = $HPBar

const BULLET_SCENE = preload("res://scenes/actors/Bullet.tscn")

func _ready() -> void:
	current_health = max_health
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = current_health

	# If this enemy is the boss, scale up!
	if is_boss:
		scale = Vector2(1.4, 1.4)
		if body_sprite:
			body_sprite.modulate = Color(1.2, 0.8, 1.2)

	# Dynamically scale difficulty based on GameState.current_level (Page 14-15)
	var lvl: int = GameState.current_level
	speed += (lvl - 1) * 20.0
	fire_interval = max(0.9, fire_interval - (lvl - 1) * 0.25)
	fire_timer = randf_range(0.5, fire_interval)

func _physics_process(delta: float) -> void:
	if not player_target:
		player_target = get_tree().get_first_node_in_group("player")

	if player_target and is_instance_valid(player_target):
		var to_player := player_target.global_position - global_position
		var dist := to_player.length()

		# Hover & Maintain tactical distance
		if dist > 260.0:
			velocity = to_player.normalized() * speed
		elif dist < 160.0:
			velocity = -to_player.normalized() * (speed * 0.7)
		else:
			# Strafe perpendicular
			velocity = Vector2(-to_player.y, to_player.x).normalized() * (speed * 0.5)

		move_and_slide()

		# Rotate gun towards player
		var aim_angle := to_player.angle()
		if gun_node:
			gun_node.rotation = aim_angle

		var facing_left := cos(aim_angle) < 0.0
		if body_sprite:
			body_sprite.flip_h = facing_left
		if gun_sprite:
			gun_sprite.flip_v = facing_left

		# Shoot timer
		fire_timer -= delta
		if fire_timer <= 0.0:
			fire_timer = fire_interval
			_shoot(to_player.normalized())
	else:
		velocity = Vector2.ZERO

func _shoot(dir: Vector2) -> void:
	AudioManager.play_sfx("gun_rifle", 0.85)
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = muzzle_node.global_position if muzzle_node else (global_position + dir * 24.0)
	bullet.direction = dir
	bullet.rotation = dir.angle()
	bullet.shooter_id = -1
	bullet.shooter_node = self
	bullet.modulate = Color(1.0, 0.2, 0.3)
	get_parent().add_child(bullet)

func take_damage(amount: int, shooter_id: int = 0) -> void:
	if is_dead:
		return
	current_health = max(0, current_health - amount)
	if hp_bar:
		hp_bar.value = current_health
	if current_health <= 0:
		is_dead = true
		die(shooter_id)

func die(killer_id: int = 0) -> void:
	is_dead = true
	AudioManager.play_sfx("explosion", 1.3)
	var tree := get_tree()
	if tree:
		var level = tree.current_scene
		if level and level.has_method("add_score"):
			level.add_score(1)
		elif level and level.has_method("register_player_death"):
			level.register_player_death(-1, killer_id)
	queue_free()
