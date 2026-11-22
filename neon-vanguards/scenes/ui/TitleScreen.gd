extends Control

@onready var play_btn: Button = find_child("PlayButton", true, false)
@onready var quit_btn: Button = find_child("QuitButton", true, false)

func _ready() -> void:
	if DisplayServer.has_method("screen_set_orientation"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	AudioManager.play_music()
	play_btn.pressed.connect(_on_play_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/ModeSelect.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

