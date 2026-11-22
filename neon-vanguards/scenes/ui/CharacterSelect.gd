extends Control

enum Tab { OPERATOR, WEAPON }
var current_tab: Tab = Tab.OPERATOR

@onready var tab_ops_btn: Button = $TopTabs/OperatorTab
@onready var tab_wep_btn: Button = $TopTabs/WeaponTab
@onready var preview_texture: TextureRect = $Panel/PreviewTexture
@onready var name_label: Label = $Panel/NameLabel
@onready var title_label: Label = $Panel/TitleLabel
@onready var desc_label: Label = $Panel/DescLabel

@onready var stat1_header: Label = $Panel/StatsGrid/Stat1Header
@onready var stat1_val: Label = $Panel/StatsGrid/Stat1Value
@onready var stat2_header: Label = $Panel/StatsGrid/Stat2Header
@onready var stat2_val: Label = $Panel/StatsGrid/Stat2Value
@onready var stat3_header: Label = $Panel/StatsGrid/Stat3Header
@onready var stat3_val: Label = $Panel/StatsGrid/Stat3Value
@onready var stat4_header: Label = $Panel/StatsGrid/Stat4Header
@onready var stat4_val: Label = $Panel/StatsGrid/Stat4Value

@onready var prev_btn: Button = $PrevButton
@onready var next_btn: Button = $NextButton
@onready var select_btn: Button = $SelectButton
@onready var back_btn: Button = $BackButton
@onready var deploy_btn: Button = $DeployButton

var char_keys: Array = ["mark", "rene", "lebron", "manny", "ronaldo"]
var wep_keys: Array = ["rifle", "shotgun", "sniper", "rocket"]

var char_index: int = 0
var wep_index: int = 0

func _ready() -> void:
	if DisplayServer.has_method("screen_set_orientation"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	AudioManager.play_music()
	tab_ops_btn.pressed.connect(func(): _switch_tab(Tab.OPERATOR))
	tab_wep_btn.pressed.connect(func(): _switch_tab(Tab.WEAPON))
	prev_btn.pressed.connect(_on_prev_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	select_btn.pressed.connect(_on_select_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	if deploy_btn:
		deploy_btn.pressed.connect(_on_deploy_pressed)

	char_index = max(0, char_keys.find(GameState.selected_character))
	wep_index = max(0, wep_keys.find(GameState.selected_weapon))

	_switch_tab(Tab.OPERATOR)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()

func _switch_tab(new_tab: Tab) -> void:
	current_tab = new_tab
	if current_tab == Tab.OPERATOR:
		tab_ops_btn.modulate = Color(0.3, 0.9, 1.0)
		tab_wep_btn.modulate = Color(0.7, 0.7, 0.7)
		_display_character()
	else:
		tab_ops_btn.modulate = Color(0.7, 0.7, 0.7)
		tab_wep_btn.modulate = Color(0.3, 0.9, 1.0)
		_display_weapon()

func _display_character() -> void:
	var char_id: String = char_keys[char_index]
	var data: Dictionary = GameState.CHARACTERS[char_id]

	name_label.text = data["name"]
	title_label.text = data["title"]
	desc_label.text = data["desc"]
	preview_texture.texture = load(data["sprite"])

	stat1_header.text = "HEALTH:"
	stat1_val.text = "%d HP" % data["health"]
	stat2_header.text = "AGILITY:"
	stat2_val.text = "%d" % int(data["speed"])
	stat3_header.text = "JETPACK:"
	stat3_val.text = "%d FUEL" % int(data["fuel"])
	stat4_header.text = "TRIGGER:"

	var mod: float = data.get("fire_cooldown_mod", 1.0)
	if mod <= 0.7:
		stat4_val.text = "RAPID (+35%)"
	elif mod < 1.0:
		stat4_val.text = "FAST"
	elif mod == 1.0:
		stat4_val.text = "NORMAL"
	else:
		stat4_val.text = "HEAVY"

	if char_id == GameState.selected_character:
		select_btn.text = "✓ OPERATOR SELECTED"
		select_btn.modulate = Color(0.3, 1.0, 0.4)
	else:
		select_btn.text = "EQUIP OPERATOR"
		select_btn.modulate = Color(1.0, 1.0, 1.0)

func _display_weapon() -> void:
	var wep_id: String = wep_keys[wep_index]
	var data: Dictionary = GameState.WEAPONS[wep_id]

	name_label.text = data["name"]
	title_label.text = "PRIMARY WEAPON"
	desc_label.text = data["desc"]
	preview_texture.texture = load(data["sprite"])

	stat1_header.text = "DAMAGE:"
	var pellets: int = data.get("pellets", 1)
	if pellets > 1:
		stat1_val.text = "%d x %d" % [data["damage"], pellets]
	else:
		stat1_val.text = "%d" % data["damage"]

	stat2_header.text = "AMMO:"
	stat2_val.text = "%d ROUNDS" % data["max_ammo"]
	stat3_header.text = "RELOAD:"
	stat3_val.text = "%.1fs" % data["reload_time"]
	stat4_header.text = "FIRE RATE:"
	stat4_val.text = "%.2fs" % data["fire_rate"]

	if wep_id == GameState.selected_weapon:
		select_btn.text = "✓ WEAPON EQUIPPED"
		select_btn.modulate = Color(0.3, 1.0, 0.4)
	else:
		select_btn.text = "EQUIP WEAPON"
		select_btn.modulate = Color(1.0, 1.0, 1.0)

func _on_prev_pressed() -> void:
	if current_tab == Tab.OPERATOR:
		char_index = (char_index - 1 + char_keys.size()) % char_keys.size()
		GameState.selected_character = char_keys[char_index]
		GameState.save_progress()
		_display_character()
	else:
		wep_index = (wep_index - 1 + wep_keys.size()) % wep_keys.size()
		GameState.selected_weapon = wep_keys[wep_index]
		GameState.save_progress()
		_display_weapon()

func _on_next_pressed() -> void:
	if current_tab == Tab.OPERATOR:
		char_index = (char_index + 1) % char_keys.size()
		GameState.selected_character = char_keys[char_index]
		GameState.save_progress()
		_display_character()
	else:
		wep_index = (wep_index + 1) % wep_keys.size()
		GameState.selected_weapon = wep_keys[wep_index]
		GameState.save_progress()
		_display_weapon()

func _on_select_pressed() -> void:
	if current_tab == Tab.OPERATOR:
		GameState.selected_character = char_keys[char_index]
		GameState.save_progress()
		_display_character()
	else:
		GameState.selected_weapon = wep_keys[wep_index]
		GameState.save_progress()
		_display_weapon()

func _on_back_pressed() -> void:
	# Ensure the viewed operator and weapon are saved
	if current_tab == Tab.OPERATOR:
		GameState.selected_character = char_keys[char_index]
	else:
		GameState.selected_weapon = wep_keys[wep_index]
	GameState.save_progress()
	get_tree().change_scene_to_file("res://scenes/ui/ModeSelect.tscn")

func _on_deploy_pressed() -> void:
	# Save selected operator and weapon and proceed to missions
	if current_tab == Tab.OPERATOR:
		GameState.selected_character = char_keys[char_index]
	else:
		GameState.selected_weapon = wep_keys[wep_index]
	GameState.save_progress()
	get_tree().change_scene_to_file("res://scenes/ui/LevelSelect.tscn")
