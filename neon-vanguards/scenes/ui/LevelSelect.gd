extends Control

const MAP_NAMES: Array = [
	"Jungle Outpost",
	"Cyber Rooftops",
	"Magma Caverns",
	"Orbital Station",
	"Desert Citadel"
]

@onready var grid: GridContainer = $Grid
@onready var back_btn: Button = $BackButton
@onready var loadout_btn: Button = $LoadoutButton

func _ready() -> void:
	if DisplayServer.has_method("screen_set_orientation"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	AudioManager.play_music()
	back_btn.pressed.connect(_on_back_pressed)
	if loadout_btn:
		loadout_btn.pressed.connect(_on_loadout_pressed)
		_update_loadout_button()
	_build_grid()

func _update_loadout_button() -> void:
	if not loadout_btn:
		return
	var c_data: Dictionary = GameState.get_selected_character_data()
	var w_data: Dictionary = GameState.get_selected_weapon_data()
	loadout_btn.text = "CURRENT LOADOUT: %s | %s  (CHANGE)" % [c_data.get("name", "Mark"), w_data.get("name", "Carbine")]

func _on_loadout_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/CharacterSelect.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()

func _build_grid() -> void:
	for child in grid.get_children():
		child.queue_free()

	for i in range(1, GameState.TOTAL_LEVELS + 1):
		var b := Button.new()
		b.custom_minimum_size = Vector2(200, 140)
		b.add_theme_font_size_override("font_size", 16)

		var map_name: String = MAP_NAMES[i - 1] if i - 1 < MAP_NAMES.size() else "Sector %d" % i
		if GameState.is_unlocked(i):
			var stars: int = GameState.best_stars.get(i, 0)
			var star_str := ""
			for s in range(3):
				star_str += "★" if s < stars else "☆"
			b.text = "Level %d\n%s\n%s (%d/3)" % [i, map_name, star_str, stars]
			b.pressed.connect(_on_level_pressed.bind(i))
		else:
			b.text = "Level %d\n%s\n🔒 LOCKED" % [i, map_name]
			b.disabled = true

		grid.add_child(b)

func _on_level_pressed(level: int) -> void:
	GameState.current_level = level
	get_tree().change_scene_to_file(GameState.level_scene_path(level))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/ModeSelect.tscn")
