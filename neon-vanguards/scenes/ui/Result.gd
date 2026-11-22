extends Control

@onready var banner_label: Label = $BannerLabel
@onready var stars_label: Label = $StarsLabel
@onready var score_label: Label = $ScoreLabel
@onready var retry_btn: Button = $ButtonsContainer/RetryButton
@onready var next_btn: Button = $ButtonsContainer/NextButton
@onready var menu_btn: Button = $ButtonsContainer/MenuButton

func _ready() -> void:
	if DisplayServer.has_method("screen_set_orientation"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)

	retry_btn.pressed.connect(_on_retry_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

	var res: Dictionary = GameState.last_result
	var won: bool = res.get("won", false)
	var stars: int = res.get("stars", 0)
	var score: int = res.get("score", 0)
	var level: int = res.get("level", GameState.current_level)

	if GameState.mode == "online":
		next_btn.visible = false
		retry_btn.text = "PLAY AGAIN (LOBBY)"
		menu_btn.text = "RETURN TO MENU"

		if won:
			banner_label.text = "🏆 VICTORY!"
			banner_label.modulate = Color(0.2, 1.0, 0.4)
			stars_label.text = "You won the multiplayer duel!"
			score_label.text = "Your Frags: %d" % score
		else:
			banner_label.text = "MATCH OVER"
			banner_label.modulate = Color(1.0, 0.4, 0.3)
			stars_label.text = "Opponent reached the frag goal first."
			score_label.text = "Your Frags: %d" % score
	else:
		if won:
			banner_label.text = "MISSION CLEARED!"
			banner_label.modulate = Color(0.2, 0.9, 0.4)
			var star_icons := ""
			for s in range(3):
				star_icons += "★ " if s < stars else "☆ "
			stars_label.text = star_icons
			score_label.text = "Score: %d" % score
			next_btn.disabled = (level >= GameState.TOTAL_LEVELS)
		else:
			banner_label.text = "MISSION FAILED"
			banner_label.modulate = Color(0.95, 0.25, 0.25)
			stars_label.text = "Try again to unlock the next level"
			score_label.text = "Score: %d" % score
			next_btn.disabled = true

func _on_retry_pressed() -> void:
	if GameState.mode == "online":
		Net.leave()
		get_tree().change_scene_to_file("res://scenes/ui/Lobby.tscn")
	else:
		get_tree().change_scene_to_file(GameState.level_scene_path(GameState.current_level))

func _on_next_pressed() -> void:
	if GameState.mode == "offline" and GameState.current_level < GameState.TOTAL_LEVELS:
		GameState.current_level += 1
		get_tree().change_scene_to_file(GameState.level_scene_path(GameState.current_level))

func _on_menu_pressed() -> void:
	if GameState.mode == "online":
		Net.leave()
		GameState.mode = "offline"
		get_tree().change_scene_to_file("res://scenes/ui/Lobby.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/LevelSelect.tscn")
