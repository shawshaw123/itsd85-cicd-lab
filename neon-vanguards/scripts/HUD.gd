extends CanvasLayer

@onready var goal_label: Label = $TopBar/GoalLabel
@onready var timer_label: Label = $TopBar/TimerLabel
@onready var score_label: Label = $TopBar/ScoreLabel
@onready var hp_bar: ProgressBar = $PlayerStats/HealthBar
@onready var fuel_bar: ProgressBar = $PlayerStats/FuelBar
@onready var ammo_btn: Button = $PlayerStats/AmmoButton
@onready var pause_btn: Button = $TopBar/PauseButton
@onready var banner_label: Label = $BannerLabel
@onready var pause_menu: Control = $PauseMenu
@onready var move_joystick: TouchJoystick = $Controls/MoveJoystick
@onready var aim_joystick: TouchJoystick = $Controls/AimJoystick

var bound_player: NeonPlayer = null
var banner_tween: Tween = null

func _ensure_nodes() -> void:
	if not hp_bar:
		hp_bar = get_node_or_null("PlayerStats/HealthBar")
	if not fuel_bar:
		fuel_bar = get_node_or_null("PlayerStats/FuelBar")
	if not ammo_btn:
		ammo_btn = get_node_or_null("PlayerStats/AmmoButton")
	if not goal_label:
		goal_label = get_node_or_null("TopBar/GoalLabel")
	if not timer_label:
		timer_label = get_node_or_null("TopBar/TimerLabel")
	if not score_label:
		score_label = get_node_or_null("TopBar/ScoreLabel")
	if not pause_btn:
		pause_btn = get_node_or_null("TopBar/PauseButton")
	if not banner_label:
		banner_label = get_node_or_null("BannerLabel")
	if not pause_menu:
		pause_menu = get_node_or_null("PauseMenu")
	if not move_joystick:
		move_joystick = get_node_or_null("Controls/MoveJoystick")
	if not aim_joystick:
		aim_joystick = get_node_or_null("Controls/AimJoystick")

func _ready() -> void:
	_ensure_nodes()
	if pause_btn and not pause_btn.pressed.is_connected(_on_pause_pressed):
		pause_btn.pressed.connect(_on_pause_pressed)
	if ammo_btn and not ammo_btn.pressed.is_connected(_on_ammo_pressed):
		ammo_btn.pressed.connect(_on_ammo_pressed)
	if pause_menu:
		pause_menu.visible = false
	if banner_label:
		banner_label.text = ""

	# Check for single-player static instance
	var player: NeonPlayer = get_tree().get_first_node_in_group("player") as NeonPlayer
	if player:
		setup_player(player)

func setup_player(player: NeonPlayer) -> void:
	if not player or not is_instance_valid(player):
		return
	_ensure_nodes()
	bound_player = player
	if move_joystick:
		player.move_joystick = move_joystick
	if aim_joystick:
		player.aim_joystick = aim_joystick

	if not player.health_changed.is_connected(_on_health_changed):
		player.health_changed.connect(_on_health_changed)
	if not player.fuel_changed.is_connected(_on_fuel_changed):
		player.fuel_changed.connect(_on_fuel_changed)
	if not player.ammo_changed.is_connected(_on_ammo_changed):
		player.ammo_changed.connect(_on_ammo_changed)
	if not player.player_died.is_connected(_on_player_died):
		player.player_died.connect(_on_player_died)

	if hp_bar:
		hp_bar.max_value = player.max_health
		hp_bar.value = player.current_health
	if fuel_bar:
		fuel_bar.max_value = player.max_fuel
		fuel_bar.value = player.current_fuel
	_on_ammo_changed(player.current_ammo, player.max_ammo, player.is_reloading)

func show_banner(text: String, col: Color = Color.WHITE, duration: float = 2.5) -> void:
	if not banner_label:
		return
	if banner_tween and banner_tween.is_valid():
		banner_tween.kill()

	banner_label.text = text
	banner_label.modulate = col
	banner_label.modulate.a = 1.0

	banner_tween = create_tween()
	banner_tween.tween_interval(duration)
	banner_tween.tween_property(banner_label, "modulate:a", 0.0, 0.5)

func set_goal(text: String) -> void:
	if goal_label:
		goal_label.text = text

func update_status(time_left: float, score: int, target: int) -> void:
	if timer_label:
		timer_label.text = "%ds" % max(0, ceili(time_left))
	if score_label:
		score_label.text = "Score: %d/%d" % [score, target]

func update_multiplayer_scoreboard(time_left: float, my_score: int, opponent_score: int, target: int, opponent_title: String = "TEACHER") -> void:
	if timer_label:
		timer_label.text = "%ds" % max(0, ceili(time_left))
	if score_label:
		score_label.text = "YOU: %d | %s: %d  (Goal: %d)" % [my_score, opponent_title, opponent_score, target]

func _on_pause_pressed() -> void:
	if pause_menu.has_method("open"):
		pause_menu.open()
	else:
		get_tree().paused = true
		pause_menu.visible = true

func _on_ammo_pressed() -> void:
	if bound_player and is_instance_valid(bound_player) and bound_player.has_method("reload"):
		bound_player.reload()
	else:
		var p: NeonPlayer = get_tree().get_first_node_in_group("player") as NeonPlayer
		if p and p.has_method("reload"):
			p.reload()

func _on_health_changed(hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp

func _on_fuel_changed(fuel: float, max_fuel: float) -> void:
	fuel_bar.max_value = max_fuel
	fuel_bar.value = fuel

func _on_ammo_changed(current: int, max_a: int, is_reloading: bool) -> void:
	if not ammo_btn:
		return
	if is_reloading:
		ammo_btn.text = "RELOADING..."
		ammo_btn.modulate = Color(1.0, 0.65, 0.2)
	else:
		ammo_btn.text = "AMMO: %d / %d (RELOAD)" % [current, max_a]
		ammo_btn.modulate = Color(1.0, 1.0, 1.0)

func _on_player_died() -> void:
	var level = get_parent()
	if level and level.has_method("end_level"):
		level.end_level(false)
