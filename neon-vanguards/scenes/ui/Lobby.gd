extends Control

@onready var host_btn: Button = %HostButton
@onready var mode_option: OptionButton = %ModeOption
@onready var map_option: OptionButton = %MapOption
@onready var char_option: OptionButton = %CharOption
@onready var death_option: OptionButton = %DeathOption
@onready var ip_edit: LineEdit = %IPLineEdit
@onready var join_btn: Button = %JoinButton
@onready var status_label: Label = %StatusLabel
@onready var back_btn: Button = %BackButton
@onready var join_timer: Timer = %JoinTimer

const CHAR_KEYS: Array[String] = ["mark", "rene", "lebron", "manny", "luna"]
const DEATH_LIMITS: Array[int] = [3, 5, 7, 10, 15, 20]

var connected_loadouts: Dictionary = {}

func _ensure_nodes() -> void:
	if not host_btn:
		host_btn = find_child("HostButton", true, false)
	if not mode_option:
		mode_option = find_child("ModeOption", true, false)
	if not map_option:
		map_option = find_child("MapOption", true, false)
	if not char_option:
		char_option = find_child("CharOption", true, false)
	if not death_option:
		death_option = find_child("DeathOption", true, false)
	if not ip_edit:
		ip_edit = find_child("IPLineEdit", true, false)
	if not join_btn:
		join_btn = find_child("JoinButton", true, false)
	if not status_label:
		status_label = find_child("StatusLabel", true, false)
	if not back_btn:
		back_btn = find_child("BackButton", true, false)
	if not join_timer:
		join_timer = find_child("JoinTimer", true, false)

func _ready() -> void:
	_ensure_nodes()
	if DisplayServer.has_method("screen_set_orientation"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	AudioManager.play_music()

	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	join_timer.timeout.connect(_on_join_timeout)

	Net.match_ready.connect(_on_match_ready)
	Net.net_error.connect(_on_net_error)

	mode_option.clear()
	mode_option.add_item("Mode: 1v1 Deathmatch (Duel)")
	mode_option.add_item("Mode: Team Deathmatch (TDM)")
	mode_option.add_item("Mode: Survival (Co-Op Drones)")

	map_option.clear()
	map_option.add_item("Map 1: Cyber Rooftops (Neon)")
	map_option.add_item("Map 2: Jungle Outpost (Canopy)")
	map_option.add_item("Map 3: Magma Caverns (Volcano)")
	map_option.add_item("Map 4: Orbital Station (Space)")
	map_option.add_item("Map 5: Desert Citadel (Dunes)")

	char_option.clear()
	char_option.add_item("Mark (Commando - Balanced)")
	char_option.add_item("Rene (Scout - High Agility)")
	char_option.add_item("Lebron (Juggernaut - 150 HP)")
	char_option.add_item("Manny (Champion - Rapid Fire)")
	char_option.add_item("Luna (Tactician - High Fuel)")

	var current_char_idx := CHAR_KEYS.find(GameState.selected_character)
	if current_char_idx >= 0:
		char_option.selected = current_char_idx
	else:
		char_option.selected = 0

	death_option.clear()
	death_option.add_item("Winner: First to 3 Deaths / Frags")
	death_option.add_item("Winner: First to 5 Deaths / Frags (Standard)")
	death_option.add_item("Winner: First to 7 Deaths / Frags")
	death_option.add_item("Winner: First to 10 Deaths / Frags (Pro)")
	death_option.add_item("Winner: First to 15 Deaths / Frags (Endurance)")
	death_option.add_item("Winner: First to 20 Deaths / Frags (Deathmatch)")
	death_option.selected = 1 # 5 frags standard

	var local_ip := Net.my_ip()
	ip_edit.text = local_ip
	status_label.text = "HOST a match or enter Host IP to JOIN.\nBoth phones must be on the SAME Wi-Fi network."

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()

func _apply_selected_character() -> String:
	var c_idx := clampi(char_option.selected, 0, CHAR_KEYS.size() - 1)
	var chosen_char := CHAR_KEYS[c_idx]
	GameState.selected_character = chosen_char
	return chosen_char

func _on_host_pressed() -> void:
	host_btn.disabled = true
	join_btn.disabled = true
	Net.host_game()

	var my_char := _apply_selected_character()

	# Register host's own loadout
	connected_loadouts[1] = {
		"char": my_char,
		"weapon": "rifle"
	}

	var my_ip := Net.my_ip()
	status_label.text = "HOSTING MATCH!\nTEACHER / OPPONENT: ENTER THIS IP ON THEIR PHONE:\n>>> %s <<<\nWaiting for connection on Wi-Fi..." % my_ip
	status_label.modulate = Color(0.2, 0.9, 1.0)

func _on_join_pressed() -> void:
	var ip := ip_edit.text.strip_edges()
	if ip == "":
		status_label.text = "Please enter the Host's IP address."
		status_label.modulate = Color(1.0, 0.3, 0.3)
		return

	_apply_selected_character()
	host_btn.disabled = true
	join_btn.disabled = true
	status_label.text = "Connecting to %s...\n(Make sure Host has tapped 'HOST MATCH')" % ip
	status_label.modulate = Color(1.0, 0.9, 0.3)
	join_timer.start(7.0)
	Net.join_game(ip)

func _on_join_timeout() -> void:
	if not multiplayer.has_multiplayer_peer() or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		Net.leave()
		_on_net_error("Cannot reach host. Check that both devices are on the same Wi-Fi and host IP is correct.")

func _on_net_error(msg: String) -> void:
	join_timer.stop()
	host_btn.disabled = false
	join_btn.disabled = false
	status_label.text = msg
	status_label.modulate = Color(1.0, 0.3, 0.3)

func _on_match_ready() -> void:
	join_timer.stop()
	status_label.text = "CONNECTED! Exchanging loadouts & launching arena..."
	status_label.modulate = Color(0.3, 1.0, 0.4)

	# Client submits loadout to host
	if not multiplayer.is_server():
		submit_loadout.rpc_id(1, GameState.selected_character, "rifle")

	# Host gives 0.5s for loadout exchange then starts
	if multiplayer.is_server():
		var timer := get_tree().create_timer(0.5)
		timer.timeout.connect(func():
			var chosen_mode := "deathmatch"
			if mode_option.selected == 1:
				chosen_mode = "tdm"
			elif mode_option.selected == 2:
				chosen_mode = "survival"

			var map_keys := ["cyber", "jungle", "volcano", "space", "desert"]
			var chosen_map: String = map_keys[clampi(map_option.selected, 0, map_keys.size() - 1)]

			var chosen_limit: int = DEATH_LIMITS[clampi(death_option.selected, 0, DEATH_LIMITS.size() - 1)]

			start_match.rpc(chosen_mode, chosen_map, chosen_limit, randi(), connected_loadouts)
		)

@rpc("any_peer", "call_local", "reliable")
func submit_loadout(char_id: String, weap_id: String) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()
	connected_loadouts[sender_id] = {
		"char": char_id,
		"weapon": weap_id
	}

@rpc("authority", "call_local", "reliable")
func start_match(chosen_mode: String, chosen_map: String, chosen_limit: int, seed_value: int, loadouts: Dictionary) -> void:
	seed(seed_value)
	GameState.mode = "online"
	GameState.game_mode = chosen_mode
	GameState.current_multiplayer_map = chosen_map
	GameState.multiplayer_frag_limit = chosen_limit
	GameState.multiplayer_loadouts = loadouts
	get_tree().change_scene_to_file("res://scenes/levels/MultiplayerArena.tscn")

func _on_back_pressed() -> void:
	join_timer.stop()
	Net.leave()
	GameState.mode = "offline"
	get_tree().change_scene_to_file("res://scenes/ui/ModeSelect.tscn")
