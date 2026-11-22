extends CharacterBody2D
class_name NeonPlayer

signal health_changed(current_hp: int, max_hp: int)
signal fuel_changed(current_fuel: float, max_fuel: float)
signal ammo_changed(current_ammo: int, max_ammo: int, is_reloading: bool)
signal player_died

@export var speed: float = 300.0
@export var jetpack_power: float = 480.0
@export var gravity: float = 850.0
@export var max_health: int = 100
@export var max_fuel: float = 100.0
@export var fuel_burn_rate: float = 40.0
@export var fuel_recharge_rate: float = 28.0

@export var character_id: String = ""
@export var weapon_id: String = ""
@export var is_invulnerable: bool = false

var current_health: int
var current_fuel: float
var can_fire: bool = true
var is_flying: bool = false
var is_dead: bool = false
var aim_angle: float = 0.0

# Weapon Management
var weapon_data: Dictionary = {}
var current_ammo: int = 30
var max_ammo: int = 30
var is_reloading: bool = false
var fire_cooldown: float = 0.18
var reload_time: float = 1.4

# Joysticks assigned from HUD
var move_joystick: TouchJoystick = null
var aim_joystick: TouchJoystick = null

# Network peer ID (0 for single player offline)
var network_id: int = 0

@onready var body_sprite: Sprite2D = $BodySprite
@onready var gun_node: Node2D = $Gun
@onready var gun_sprite: Sprite2D = $Gun/GunSprite
@onready var muzzle_node: Marker2D = $Gun/Muzzle
@onready var thruster_particles: CPUParticles2D = $ThrusterParticles
@onready var overhead_node: Node2D = $Overhead
@onready var nametag_label: Label = $Overhead/NameTag
@onready var mini_hp_bar: ProgressBar = $Overhead/MiniHPBar
@onready var camera_node: Camera2D = $Camera2D

const BULLET_SCENE = preload("res://scenes/actors/Bullet.tscn")

func _ready() -> void:
	# 1. Determine Loadout
	var chosen_char := character_id.strip_edges()
	var chosen_gun := weapon_id.strip_edges()

	# In offline single player (network_id == 0) or if not explicitly provided:
	if network_id == 0 or chosen_char == "":
		chosen_char = GameState.selected_character
	if network_id == 0 or chosen_gun == "":
		chosen_gun = GameState.selected_weapon

	character_id = chosen_char
	weapon_id = chosen_gun

	var char_data: Dictionary = GameState.CHARACTERS.get(chosen_char, GameState.CHARACTERS["mark"])
	max_health = char_data.get("health", 100)
	speed = char_data.get("speed", 300.0)
	jetpack_power = char_data.get("jetpack_power", 480.0)
	max_fuel = char_data.get("fuel", 100.0)
	var fire_mod: float = char_data.get("fire_cooldown_mod", 1.0)

	var sprite_path: String = char_data.get("sprite", "res://assets/art/char_mark.svg")
	if body_sprite and ResourceLoader.exists(sprite_path):
		body_sprite.texture = load(sprite_path)

	load_weapon(chosen_gun, fire_mod)

	current_health = max_health
	current_fuel = max_fuel

	# 2. Setup Overhead Nametag & Mini HP Bar
	var char_name: String = char_data.get("name", "Mark")
	_setup_overhead(char_name)

	# 3. Setup HUD & Camera if this is the local controlled player
	var is_local := _is_local_player()
	if is_local:
		call_deferred("_connect_to_hud")
		if camera_node:
			camera_node.enabled = true
			camera_node.make_current()
			call_deferred("_setup_camera_bounds")
		# 1.5s Invulnerability shield on spawn
		set_invulnerable(1.5)

	health_changed.emit(current_health, max_health)
	fuel_changed.emit(current_fuel, max_fuel)
	ammo_changed.emit(current_ammo, max_ammo, false)

func _connect_to_hud() -> void:
	var tree := get_tree()
	if not tree or not tree.current_scene:
		return
	var hud = tree.current_scene.get_node_or_null("HUD")
	if hud and hud.has_method("setup_player"):
		hud.setup_player(self)

func _setup_camera_bounds() -> void:
	if not camera_node:
		return
	var tree := get_tree()
	if not tree or not tree.current_scene:
		return
	var scene = tree.current_scene
	var vp := get_viewport_rect().size
	if scene.has_method("get_map_bounds"):
		var b: Rect2 = scene.get_map_bounds()
		var target_w := maxf(b.size.x, vp.x)
		var target_h := maxf(b.size.y, vp.y)
		camera_node.limit_left = int(b.position.x)
		camera_node.limit_top = int(b.position.y)
		camera_node.limit_right = int(b.position.x + target_w)
		camera_node.limit_bottom = int(b.position.y + target_h)
	else:
		var target_w := maxf(1280.0, vp.x)
		var target_h := maxf(720.0, vp.y)
		camera_node.limit_left = 0
		camera_node.limit_top = 0
		camera_node.limit_right = int(target_w)
		camera_node.limit_bottom = int(target_h)

func equip_weapon(new_weapon_id: String) -> void:
	weapon_id = new_weapon_id
	var char_data: Dictionary = GameState.CHARACTERS.get(character_id, GameState.CHARACTERS["mark"])
	var fire_mod: float = char_data.get("fire_cooldown_mod", 1.0)
	load_weapon(new_weapon_id, fire_mod)
	AudioManager.play_sfx("reload")

	if multiplayer.has_multiplayer_peer() and (GameState.mode == "online" or network_id > 0):
		sync_equip_weapon.rpc(new_weapon_id)

@rpc("any_peer", "call_remote", "reliable")
func sync_equip_weapon(new_weapon_id: String) -> void:
	weapon_id = new_weapon_id
	var char_data: Dictionary = GameState.CHARACTERS.get(character_id, GameState.CHARACTERS["mark"])
	var fire_mod: float = char_data.get("fire_cooldown_mod", 1.0)
	load_weapon(new_weapon_id, fire_mod)

func _is_local_player() -> bool:
	if network_id == 0:
		return true
	if multiplayer.has_multiplayer_peer() and network_id == multiplayer.get_unique_id():
		return true
	return false

func _setup_overhead(char_name: String) -> void:
	if not nametag_label:
		return

	if mini_hp_bar:
		mini_hp_bar.max_value = max_health
		mini_hp_bar.value = current_health

	var is_local := _is_local_player()
	if is_local:
		nametag_label.text = "YOU (%s)" % char_name
		nametag_label.modulate = Color(0.1, 0.9, 1.0) # Bright Cyan
	else:
		var role_tag := "TEACHER" if multiplayer.is_server() else "HOST / TEACHER"
		nametag_label.text = "%s (%s)" % [role_tag, char_name]
		nametag_label.modulate = Color(1.0, 0.45, 0.2) # Orange / Red

func load_weapon(weap_id: String, fire_mod: float = 1.0) -> void:
	weapon_data = GameState.get_weapon_data(weap_id)
	max_ammo = weapon_data.get("max_ammo", 30)
	current_ammo = max_ammo
	fire_cooldown = weapon_data.get("fire_rate", 0.18) * fire_mod
	reload_time = weapon_data.get("reload_time", 1.4)
	is_reloading = false

	var gun_tex_path: String = weapon_data.get("sprite", "res://assets/art/gun_rifle.svg")
	if gun_sprite and ResourceLoader.exists(gun_tex_path):
		gun_sprite.texture = load(gun_tex_path)

	ammo_changed.emit(current_ammo, max_ammo, false)

func set_invulnerable(duration: float = 1.5) -> void:
	is_invulnerable = true
	var tween := create_tween()
	var cycles := int(duration / 0.16)
	for i in range(cycles):
		tween.tween_property(self, "modulate:a", 0.4, 0.08)
		tween.tween_property(self, "modulate:a", 1.0, 0.08)

	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(func():
		is_invulnerable = false
		modulate.a = 1.0
	)

func _physics_process(delta: float) -> void:
	# Keep overhead HP bar synced
	if mini_hp_bar:
		mini_hp_bar.value = current_health

	# In multiplayer, only local player handles inputs
	if not _is_local_player():
		# Remote player is positioned by MultiplayerSynchronizer
		if gun_node:
			gun_node.rotation = aim_angle
			var facing_left := cos(aim_angle) < 0.0
			if body_sprite:
				body_sprite.flip_h = facing_left
			if gun_sprite:
				gun_sprite.flip_v = facing_left
		if thruster_particles:
			thruster_particles.emitting = is_flying
		move_and_slide()
		return

	# 1. Horizontal Movement
	var move_x := 0.0
	if move_joystick and move_joystick.output.length() > 0.15:
		move_x = move_joystick.output.x
	else:
		move_x = Input.get_axis("ui_left", "ui_right")

	velocity.x = move_x * speed

	# 2. Vertical Movement & Jetpack
	var wants_to_fly := false
	if move_joystick and move_joystick.output.y < -0.35:
		wants_to_fly = true
	elif Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_SPACE):
		wants_to_fly = true

	if wants_to_fly and current_fuel > 0.0:
		is_flying = true
		velocity.y = -jetpack_power
		current_fuel = max(0.0, current_fuel - fuel_burn_rate * delta)
		if thruster_particles:
			thruster_particles.emitting = true
	else:
		is_flying = false
		velocity.y += gravity * delta
		if thruster_particles:
			thruster_particles.emitting = false

		if is_on_floor() or not wants_to_fly:
			current_fuel = min(max_fuel, current_fuel + fuel_recharge_rate * delta)

	fuel_changed.emit(current_fuel, max_fuel)
	move_and_slide()

	# Manual reload input (R key)
	if Input.is_key_pressed(KEY_R) and current_ammo < max_ammo and not is_reloading:
		reload()

	# 3. Aiming & Shooting
	_process_aiming()

func _process_aiming() -> void:
	var aim_dir := Vector2.ZERO
	if aim_joystick and aim_joystick.output.length() > 0.2:
		aim_dir = aim_joystick.output
	else:
		var mouse_pos := get_global_mouse_position()
		aim_dir = (mouse_pos - global_position).normalized()

	if aim_dir.length() > 0.1:
		aim_angle = aim_dir.angle()
		if gun_node:
			gun_node.rotation = aim_angle

		var facing_left := cos(aim_angle) < 0.0
		if body_sprite:
			body_sprite.flip_h = facing_left
		if gun_sprite:
			gun_sprite.flip_v = facing_left
		if thruster_particles:
			thruster_particles.position.x = 16.0 if facing_left else -16.0

		var is_firing := false
		if aim_joystick and aim_joystick.output.length() > 0.4:
			is_firing = true
		elif not (move_joystick and move_joystick.is_active) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			is_firing = true

		if is_firing and can_fire and not is_reloading:
			if current_ammo > 0:
				_shoot(aim_dir.normalized())
			else:
				reload()

func _shoot(dir: Vector2) -> void:
	can_fire = false
	current_ammo -= 1
	ammo_changed.emit(current_ammo, max_ammo, false)

	# Play unique weapon gunshot sound
	AudioManager.play_gun_sfx(weapon_id)

	var spawn_pos: Vector2 = muzzle_node.global_position if muzzle_node else (global_position + dir * 24.0)
	var pellets: int = weapon_data.get("pellets", 1)
	var spread: float = weapon_data.get("spread", 0.0)

	for p in range(pellets):
		var shot_dir: Vector2 = dir
		if spread > 0.0:
			shot_dir = dir.rotated(randf_range(-spread, spread))

		_spawn_bullet(spawn_pos, shot_dir, network_id)

	# In multiplayer, sync firing across devices
	if multiplayer.has_multiplayer_peer() and (GameState.mode == "online" or network_id > 0):
		sync_fire.rpc(spawn_pos, dir, network_id)

	if current_ammo <= 0:
		reload()

	var timer := get_tree().create_timer(fire_cooldown)
	timer.timeout.connect(func(): can_fire = true)

func _spawn_bullet(pos: Vector2, dir: Vector2, shooter: int) -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = pos
	bullet.direction = dir
	bullet.rotation = dir.angle()
	bullet.speed = weapon_data.get("bullet_speed", 800.0)
	bullet.damage = weapon_data.get("damage", 25)
	bullet.is_explosive = weapon_data.get("explosive", false)
	bullet.weapon_type = weapon_data.get("id", "rifle")
	bullet.shooter_id = shooter
	bullet.shooter_node = self

	var arena = get_tree().current_scene
	if arena:
		arena.add_child(bullet)
	else:
		get_parent().add_child(bullet)

func reload() -> void:
	if is_reloading or current_ammo == max_ammo:
		return
	is_reloading = true
	ammo_changed.emit(current_ammo, max_ammo, true)
	AudioManager.play_sfx("reload")

	var timer := get_tree().create_timer(reload_time)
	timer.timeout.connect(func():
		current_ammo = max_ammo
		is_reloading = false
		ammo_changed.emit(current_ammo, max_ammo, false)
	)

func take_damage(amount: int, shooter_id: int = 0) -> void:
	if is_dead or is_invulnerable:
		return

	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if mini_hp_bar:
		mini_hp_bar.value = current_health

	AudioManager.play_sfx("hurt")

	if current_health <= 0:
		die(shooter_id)

func die(killer_id: int = 0) -> void:
	if is_dead:
		return
	is_dead = true
	player_died.emit()
	var tree := get_tree()
	if tree:
		var arena = tree.current_scene
		if arena:
			if multiplayer.has_multiplayer_peer():
				if multiplayer.is_server():
					if arena.has_method("register_player_death"):
						arena.register_player_death(network_id, killer_id)
				else:
					# Client ONLY reports death for their OWN character!
					if is_multiplayer_authority() and arena.has_method("report_death_to_server"):
						arena.report_death_to_server(network_id, killer_id)
			elif arena.has_method("register_player_death"):
				arena.register_player_death(network_id, killer_id)
	queue_free()

# ----------------- Multiplayer RPCs -----------------
@rpc("any_peer", "call_remote", "reliable")
func sync_fire(pos: Vector2, dir: Vector2, shooter_peer_id: int) -> void:
	AudioManager.play_gun_sfx(weapon_id)
	_spawn_bullet(pos, dir, shooter_peer_id)
