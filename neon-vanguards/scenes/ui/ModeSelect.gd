extends Control

@onready var offline_btn: Button = find_child("OfflineButton", true, false)
@onready var online_btn: Button = find_child("OnlineButton", true, false)
@onready var char_btn: Button = find_child("CharButton", true, false)
@onready var back_btn: Button = find_child("BackButton", true, false)

func _ready() -> void:
	if DisplayServer.has_method("screen_set_orientation"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	AudioManager.play_music()
	offline_btn.pressed.connect(_on_offline_pressed)
	online_btn.pressed.connect(_on_online_pressed)
	char_btn.pressed.connect(_on_char_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	_update_char_button()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()

func _update_char_button() -> void:
	var c_data: Dictionary = GameState.get_selected_character_data()
	var w_data: Dictionary = GameState.get_selected_weapon_data()
	char_btn.text = "ARMORY: %s | %s (Customize)" % [c_data.get("name", "Mark"), w_data.get("name", "Rifle")]

func _on_offline_pressed() -> void:
	GameState.mode = "offline"
	get_tree().change_scene_to_file("res://scenes/ui/CharacterSelect.tscn")

func _on_online_pressed() -> void:
	GameState.mode = "online"
	get_tree().change_scene_to_file("res://scenes/ui/Lobby.tscn")

func _on_char_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/CharacterSelect.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
