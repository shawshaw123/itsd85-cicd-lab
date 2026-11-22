extends Node

const SAVE_PATH := "user://save.cfg"
const TOTAL_LEVELS := 5

const CHARACTERS: Dictionary = {
	"mark": {
		"id": "mark",
		"name": "Mark",
		"title": "All-Round Commando",
		"desc": "Balanced health, speed, and standard military combat kit.",
		"sprite": "res://assets/art/char_mark.svg",
		"health": 100,
		"speed": 300.0,
		"jetpack_power": 480.0,
		"fuel": 100.0,
		"fire_cooldown_mod": 1.0
	},
	"rene": {
		"id": "rene",
		"name": "Rene",
		"title": "Stealth Scout",
		"desc": "Agile tactical operative. High ground agility and rapid fuel recharge.",
		"sprite": "res://assets/art/char_rene.svg",
		"health": 80,
		"speed": 360.0,
		"jetpack_power": 520.0,
		"fuel": 90.0,
		"fire_cooldown_mod": 0.95
	},
	"lebron": {
		"id": "lebron",
		"name": "Lebron",
		"title": "Heavy Juggernaut",
		"desc": "Unstoppable 150 HP blast armor. Dominates the arena floor.",
		"sprite": "res://assets/art/char_lebron.svg",
		"health": 150,
		"speed": 240.0,
		"jetpack_power": 440.0,
		"fuel": 120.0,
		"fire_cooldown_mod": 1.15
	},
	"manny": {
		"id": "manny",
		"name": "Manny",
		"title": "The Champion / Rapid Striker",
		"desc": "Lightning-fast hand speed with 35% faster rapid trigger rate.",
		"sprite": "res://assets/art/char_manny.svg",
		"health": 90,
		"speed": 300.0,
		"jetpack_power": 490.0,
		"fuel": 100.0,
		"fire_cooldown_mod": 0.65
	},
	"ronaldo": {
		"id": "ronaldo",
		"name": "Ronaldo",
		"title": "Aerial Ace / Flying Superstar",
		"desc": "Incredible vertical jumping thrust with massive 150 jetpack fuel.",
		"sprite": "res://assets/art/char_ronaldo.svg",
		"health": 95,
		"speed": 310.0,
		"jetpack_power": 570.0,
		"fuel": 150.0,
		"fire_cooldown_mod": 1.0
	}
}

const WEAPONS: Dictionary = {
	"rifle": {
		"id": "rifle",
		"name": "Plasma Carbine",
		"desc": "Reliable fully-automatic assault rifle. High magazine and balanced damage.",
		"sprite": "res://assets/art/gun_rifle.svg",
		"damage": 22,
		"fire_rate": 0.16,
		"max_ammo": 30,
		"reload_time": 1.4,
		"bullet_speed": 850.0,
		"pellets": 1,
		"spread": 0.04,
		"explosive": false
	},
	"shotgun": {
		"id": "shotgun",
		"name": "Scatter Shotgun",
		"desc": "Fires a deadly spread of 5 plasma buckshots. Devastating in close-range flight.",
		"sprite": "res://assets/art/gun_shotgun.svg",
		"damage": 14,
		"fire_rate": 0.62,
		"max_ammo": 8,
		"reload_time": 2.0,
		"bullet_speed": 780.0,
		"pellets": 5,
		"spread": 0.22,
		"explosive": false
	},
	"sniper": {
		"id": "sniper",
		"name": "Laser Railgun",
		"desc": "High-velocity hyper-dense beam. Extreme precision and single-shot stopping power.",
		"sprite": "res://assets/art/gun_sniper.svg",
		"damage": 85,
		"fire_rate": 1.1,
		"max_ammo": 5,
		"reload_time": 2.4,
		"bullet_speed": 1600.0,
		"pellets": 1,
		"spread": 0.0,
		"explosive": false
	},
	"rocket": {
		"id": "rocket",
		"name": "Rocket Launcher",
		"desc": "Heavy explosive warhead. Catastrophic blast damage across floating platforms.",
		"sprite": "res://assets/art/gun_rocket.svg",
		"damage": 100,
		"fire_rate": 0.95,
		"max_ammo": 4,
		"reload_time": 2.6,
		"bullet_speed": 560.0,
		"pellets": 1,
		"spread": 0.0,
		"explosive": true
	}
}

const GAME_MODES: Dictionary = {
	"survival": {
		"id": "survival",
		"name": "Survival",
		"desc": "Clear escalating waves of rogue drones across the 5 planetary arenas."
	},
	"deathmatch": {
		"id": "deathmatch",
		"name": "Deathmatch (FFA)",
		"desc": "Real-time 1-on-1 deathmatch duel! First combatant to 5 frags wins."
	},
	"tdm": {
		"id": "tdm",
		"name": "Team Deathmatch",
		"desc": "Blue Team vs Red Team! Squad up and race to 10 frags."
	}
}

var selected_character: String = "mark"
var selected_weapon: String = "rifle"
var game_mode: String = "survival"
var current_multiplayer_map: String = "cyber"
var multiplayer_frag_limit: int = 5
var multiplayer_loadouts: Dictionary = {}

var unlocked_level: int = 1
var best_stars: Dictionary = {}
var current_level: int = 1
var mode: String = "offline" # "offline" or "online"
var last_result: Dictionary = {}
var sound_enabled: bool = true

func _ready() -> void:
	# Lock mobile screen to landscape orientation (SCREEN_SENSOR_LANDSCAPE = 4)
	if DisplayServer.has_method("screen_set_orientation"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	load_progress()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			var current_mode = DisplayServer.window_get_mode()
			if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func get_selected_character_data() -> Dictionary:
	return CHARACTERS.get(selected_character, CHARACTERS["mark"])

func get_selected_weapon_data() -> Dictionary:
	return WEAPONS.get(selected_weapon, WEAPONS["rifle"])

func get_weapon_data(weapon_id: String) -> Dictionary:
	return WEAPONS.get(weapon_id, WEAPONS["rifle"])

func is_unlocked(level: int) -> bool:
	return level <= unlocked_level

func complete_level(level: int, stars: int) -> void:
	best_stars[level] = max(stars, best_stars.get(level, 0))
	if level == unlocked_level and level < TOTAL_LEVELS:
		unlocked_level = level + 1
	save_progress()

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked_level", unlocked_level)
	cfg.set_value("progress", "best_stars", best_stars)
	cfg.set_value("progress", "selected_character", selected_character)
	cfg.set_value("progress", "selected_weapon", selected_weapon)
	cfg.set_value("settings", "game_mode", game_mode)
	cfg.set_value("settings", "sound_enabled", sound_enabled)
	cfg.save(SAVE_PATH)

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		unlocked_level = cfg.get_value("progress", "unlocked_level", 1)
		best_stars = cfg.get_value("progress", "best_stars", {})
		selected_character = cfg.get_value("progress", "selected_character", "mark")
		selected_weapon = cfg.get_value("progress", "selected_weapon", "rifle")
		game_mode = cfg.get_value("settings", "game_mode", "survival")
		sound_enabled = cfg.get_value("settings", "sound_enabled", true)

func reset_progress() -> void:
	unlocked_level = 1
	best_stars.clear()
	selected_character = "mark"
	selected_weapon = "rifle"
	save_progress()

func level_scene_path(level: int) -> String:
	return "res://scenes/levels/Level%02d.tscn" % level
