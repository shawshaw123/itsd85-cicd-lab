extends Control

@onready var resume_btn: Button = $Panel/VBoxContainer/ResumeButton
@onready var restart_btn: Button = $Panel/VBoxContainer/RestartButton
@onready var sound_btn: Button = $Panel/VBoxContainer/SoundButton
@onready var quit_btn: Button = $Panel/VBoxContainer/QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	sound_btn.pressed.connect(_on_sound_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	_update_sound_button()

func open() -> void:
	get_tree().paused = true
	visible = true

func _on_resume_pressed() -> void:
	get_tree().paused = false
	visible = false

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_sound_pressed() -> void:
	GameState.sound_enabled = not GameState.sound_enabled
	GameState.save_progress()
	if GameState.sound_enabled:
		AudioManager.play_music()
	else:
		AudioManager.stop_music()
	_update_sound_button()

func _update_sound_button() -> void:
	sound_btn.text = "Sound: ON" if GameState.sound_enabled else "Sound: OFF"

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/LevelSelect.tscn")

