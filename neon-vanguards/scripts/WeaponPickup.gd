extends Area2D
class_name WeaponPickup

@export var weapon_type: String = "shotgun"

var base_y: float = 0.0
var time_passed: float = 0.0
var is_available: bool = true

@onready var gun_sprite: Sprite2D = $GunSprite
@onready var label: Label = $Label
@onready var col_shape: CollisionShape2D = $CollisionShape2D

const WEAPON_NAMES: Dictionary = {
	"shotgun": "SCATTER SHOTGUN",
	"sniper": "LASER RAILGUN",
	"rocket": "ROCKET LAUNCHER",
	"rifle": "PLASMA CARBINE"
}

const WEAPON_TEXTURES: Dictionary = {
	"shotgun": "res://assets/art/gun_shotgun.svg",
	"sniper": "res://assets/art/gun_sniper.svg",
	"rocket": "res://assets/art/gun_rocket.svg",
	"rifle": "res://assets/art/gun_rifle.svg"
}

func _ready() -> void:
	base_y = position.y
	_update_visuals()
	body_entered.connect(_on_body_entered)

func set_weapon(type: String) -> void:
	weapon_type = type
	_update_visuals()

func _update_visuals() -> void:
	if label:
		label.text = WEAPON_NAMES.get(weapon_type, "WEAPON")
	if gun_sprite:
		var tex_path: String = WEAPON_TEXTURES.get(weapon_type, "res://assets/art/gun_shotgun.svg")
		if ResourceLoader.exists(tex_path):
			gun_sprite.texture = load(tex_path)

func _process(delta: float) -> void:
	if not is_available:
		return
	time_passed += delta
	position.y = base_y + sin(time_passed * 3.5) * 6.0
	queue_redraw()

func _draw() -> void:
	if not is_available:
		return
	# Glowing pedestal beacon
	var glow_color := Color(0.2, 0.85, 1.0, 0.35)
	if weapon_type == "shotgun":
		glow_color = Color(1.0, 0.7, 0.2, 0.35)
	elif weapon_type == "sniper":
		glow_color = Color(0.1, 0.9, 1.0, 0.35)
	elif weapon_type == "rocket":
		glow_color = Color(1.0, 0.25, 0.15, 0.35)

	draw_circle(Vector2(0, 18), 24.0, glow_color)
	draw_line(Vector2(0, 18), Vector2(0, -18), glow_color, 2.0)

func _on_body_entered(body: Node2D) -> void:
	if not is_available:
		return

	if body is NeonPlayer:
		is_available = false
		body.equip_weapon(weapon_type)
		AudioManager.play_sfx("pickup")

		var tree := get_tree()
		if tree and tree.current_scene:
			var hud = tree.current_scene.get_node_or_null("HUD")
			var weap_name: String = WEAPON_NAMES.get(weapon_type, "WEAPON")
			if hud and hud.has_method("show_banner"):
				if body._is_local_player():
					hud.show_banner("⭐ EQUIPPED %s!" % weap_name, Color(0.2, 1.0, 0.4), 2.5)
				else:
					hud.show_banner("OPPONENT EQUIPPED %s!" % weap_name, Color(1.0, 0.5, 0.2), 2.5)

		queue_free()
