extends Node2D

@export var frag_limit: int = 5
@export var match_duration: float = 180.0 # 3 minutes

var scores: Dictionary = {} # peer_id -> frags
var respawning_peers: Dictionary = {} # peer_id -> bool
var match_time_left: float
var is_game_over: bool = false

# 30-second power weapon spawn timer
var weapon_spawn_timer: float = 30.0
const WEAPON_SPAWN_INTERVAL: float = 30.0
const RANDOM_WEAPONS: Array[String] = ["shotgun", "sniper", "rocket"]

var weapon_spawn_points: Array[Vector2] = [
	Vector2(1280, 580), # Central combat platform
	Vector2(600, 520),  # West mid platform
	Vector2(1960, 520), # East mid platform
	Vector2(1280, 280)  # High center skyway
]

@onready var players_container: Node2D = $Players
@onready var hud: CanvasLayer = $HUD
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var pickups_container: Node2D = $Pickups

const PLAYER_SCENE = preload("res://scenes/actors/Player.tscn")
const ENEMY_SCENE = preload("res://scenes/actors/Enemy.tscn")
const WEAPON_PICKUP_SCENE = preload("res://scenes/actors/WeaponPickup.tscn")

# 12 diverse tactical spawn points across the 2560 x 1200 arena
var spawn_positions: Array[Vector2] = [
	Vector2(350, 270),   # High West skyway
	Vector2(1280, 270),  # High Center platform
	Vector2(2210, 270),  # High East skyway
	Vector2(600, 510),   # Mid West balcony
	Vector2(1280, 570),  # Center combat platform
	Vector2(1960, 510),  # Mid East balcony
	Vector2(450, 870),   # Lower West platform
	Vector2(950, 770),   # Lower West-mid deck
	Vector2(1610, 770),  # Lower East-mid deck
	Vector2(2110, 870),  # Lower East platform
	Vector2(300, 1040),  # Ground West flank
	Vector2(2260, 1040)  # Ground East flank
]

const MAP_THEMES: Dictionary = {
	"cyber": {
		"title": "// CYBER ARENA SECTOR 07 - EXPANDED BATTLEGROUND //",
		"bg": "res://assets/art/bg_cybercity.svg",
		"particle_col": Color(0.2, 0.85, 1.0, 0.6),
		"floor_trim": Color(0.98, 0.2, 0.7, 1.0),
		"accent_trim": Color(0.12, 0.85, 1.0, 0.8),
		"plat_trim": Color(0.98, 0.25, 0.75, 1.0)
	},
	"jungle": {
		"title": "// JUNGLE OUTPOST - ANCIENT CANOPY RUINS //",
		"bg": "res://assets/art/bg_jungle.svg",
		"particle_col": Color(0.3, 0.95, 0.4, 0.6),
		"floor_trim": Color(0.2, 0.8, 0.3, 1.0),
		"accent_trim": Color(0.8, 0.95, 0.3, 0.8),
		"plat_trim": Color(0.3, 0.95, 0.5, 1.0)
	},
	"volcano": {
		"title": "// MAGMA CAVERNS - CORE GEOTHERMAL FACILITY //",
		"bg": "res://assets/art/bg_volcano.svg",
		"particle_col": Color(1.0, 0.45, 0.1, 0.7),
		"floor_trim": Color(1.0, 0.25, 0.05, 1.0),
		"accent_trim": Color(1.0, 0.7, 0.15, 0.8),
		"plat_trim": Color(1.0, 0.4, 0.1, 1.0)
	},
	"space": {
		"title": "// ORBITAL STATION TITAN - ZERO GRAVITY DOCK //",
		"bg": "res://assets/art/bg_space.svg",
		"particle_col": Color(0.7, 0.8, 1.0, 0.6),
		"floor_trim": Color(0.3, 0.6, 1.0, 1.0),
		"accent_trim": Color(0.6, 0.4, 1.0, 0.8),
		"plat_trim": Color(0.4, 0.7, 1.0, 1.0)
	},
	"desert": {
		"title": "// DESERT CITADEL - ANCIENT SOLAR FORTRESS //",
		"bg": "res://assets/art/bg_desert.svg",
		"particle_col": Color(0.95, 0.75, 0.3, 0.6),
		"floor_trim": Color(0.9, 0.65, 0.2, 1.0),
		"accent_trim": Color(1.0, 0.85, 0.4, 0.8),
		"plat_trim": Color(0.95, 0.75, 0.3, 1.0)
	}
}

func apply_map_theme(map_key: String) -> void:
	var theme: Dictionary = MAP_THEMES.get(map_key, MAP_THEMES["cyber"])
	var bg_rect = get_node_or_null("Background") as TextureRect
	if bg_rect and ResourceLoader.exists(theme.bg):
		bg_rect.texture = load(theme.bg)

	var particles = get_node_or_null("AmbientParticles") as CPUParticles2D
	if particles:
		particles.color = theme.particle_col

	var floor_trim = get_node_or_null("Bounds/NeonFloorTrim") as ColorRect
	if floor_trim:
		floor_trim.color = theme.floor_trim
	var ceil_trim = get_node_or_null("Bounds/CeilingTrim") as ColorRect
	if ceil_trim:
		ceil_trim.color = theme.accent_trim
	var left_trim = get_node_or_null("Bounds/LeftTrim") as ColorRect
	if left_trim:
		left_trim.color = theme.floor_trim
	var right_trim = get_node_or_null("Bounds/RightTrim") as ColorRect
	if right_trim:
		right_trim.color = theme.floor_trim

	var sign_label = get_node_or_null("ArenaSignCenter") as Label
	if sign_label:
		sign_label.text = theme.title
		sign_label.modulate = theme.accent_trim

	# Tint platforms
	for child in get_children():
		if child.name.begins_with("Platform"):
			var top_trim = child.get_node_or_null("NeonTrimTop") as ColorRect
			if top_trim:
				top_trim.color = theme.plat_trim
			var btm_trim = child.get_node_or_null("NeonTrimBottom") as ColorRect
			if btm_trim:
				btm_trim.color = theme.plat_trim
			var core = child.get_node_or_null("CenterCore") as ColorRect
			if core:
				core.color = theme.accent_trim

func get_map_bounds() -> Rect2:
	return Rect2(0, 0, 2560, 1200)

func _enter_tree() -> void:
	var sp := get_node_or_null("MultiplayerSpawner") as MultiplayerSpawner
	if sp:
		sp.spawn_function = _custom_spawn_player

func _ready() -> void:
	randomize()
	if DisplayServer.has_method("screen_set_orientation"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)

	if GameState.multiplayer_frag_limit > 0:
		frag_limit = GameState.multiplayer_frag_limit

	apply_map_theme(GameState.current_multiplayer_map)
	AudioManager.play_music()
	match_time_left = match_duration
	weapon_spawn_timer = WEAPON_SPAWN_INTERVAL
	spawner.spawn_function = _custom_spawn_player

	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

		# Spawn host player with standard Plasma Carbine (rifle)
		_spawn_player_for_peer(multiplayer.get_unique_id(), 0)

		# Spawn any already connected peers
		var peer_ids := multiplayer.get_peers()
		for i in range(peer_ids.size()):
			_spawn_player_for_peer(peer_ids[i], i + 1)

		if GameState.game_mode == "survival":
			_spawn_bot_waves()
	else:
		multiplayer.server_disconnected.connect(_on_server_disconnected)

	_update_scoreboard_text()
	if hud and hud.has_method("show_banner"):
		var map_theme_info: Dictionary = MAP_THEMES.get(GameState.current_multiplayer_map, MAP_THEMES["cyber"])
		var map_title: String = map_theme_info.get("title", "ARENA")
		hud.show_banner("%s\nMATCH START! FIRST TO %d FRAGS WINS!" % [map_title, frag_limit], Color(0.2, 1.0, 0.4), 3.5)

func _process(delta: float) -> void:
	if is_game_over:
		return

	match_time_left -= delta
	_update_hud_display()

	if multiplayer.is_server():
		# 30-second weapon drop cycle
		weapon_spawn_timer -= delta
		if weapon_spawn_timer <= 0.0:
			weapon_spawn_timer = WEAPON_SPAWN_INTERVAL
			_spawn_random_weapon()

		if match_time_left <= 0.0:
			_evaluate_time_over()

func _spawn_random_weapon() -> void:
	var chosen_weap: String = RANDOM_WEAPONS[randi() % RANDOM_WEAPONS.size()]
	var chosen_pos: Vector2 = weapon_spawn_points[randi() % weapon_spawn_points.size()]
	spawn_weapon_rpc.rpc(chosen_weap, chosen_pos)

@rpc("authority", "call_local", "reliable")
func spawn_weapon_rpc(weap_type: String, pos: Vector2) -> void:
	var pickup = WEAPON_PICKUP_SCENE.instantiate() as WeaponPickup
	pickup.global_position = pos
	pickup.set_weapon(weap_type)

	if not pickups_container:
		pickups_container = get_node_or_null("Pickups")

	if pickups_container:
		pickups_container.add_child(pickup)
	else:
		add_child(pickup)

	var w_name: String = WeaponPickup.WEAPON_NAMES.get(weap_type, "POWER WEAPON")
	if hud and hud.has_method("show_banner"):
		hud.show_banner("⭐ %s DROPPED IN THE ARENA!" % w_name, Color(1.0, 0.85, 0.2), 3.0)
	AudioManager.play_sfx("pickup")

func _update_hud_display() -> void:
	if not hud:
		return

	var my_id := multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 0
	var my_frags: int = scores.get(my_id, 0)

	var opponent_frags: int = 0
	var opponent_name := "TEACHER" if multiplayer.is_server() else "HOST"
	for pid in scores:
		if pid != my_id:
			opponent_frags = scores[pid]
			break

	if hud.has_method("update_multiplayer_scoreboard"):
		hud.update_multiplayer_scoreboard(match_time_left, my_frags, opponent_frags, frag_limit, opponent_name)
	elif hud.has_method("update_status"):
		hud.update_status(match_time_left, my_frags, frag_limit)

func _custom_spawn_player(data: Dictionary) -> Node:
	var peer_id: int = data.get("peer_id", 1)
	var spawn_pos: Vector2 = data.get("pos", Vector2(350, 1040))
	var char_id: String = data.get("char_id", "mark")
	# In multiplayer, always begin with Plasma Carbine (rifle)
	var weap_id: String = data.get("weapon_id", "rifle")

	# Clean up any lingering node with this name to avoid Godot auto-renaming (@Player_1@2)
	if players_container:
		var existing = players_container.get_node_or_null("Player_%d" % peer_id)
		if existing and is_instance_valid(existing):
			existing.name = "Stale_%d" % randi()
			existing.queue_free()

	var player = PLAYER_SCENE.instantiate() as NeonPlayer
	player.name = "Player_%d" % peer_id
	player.network_id = peer_id
	player.character_id = char_id
	player.weapon_id = weap_id
	player.global_position = spawn_pos
	player.set_multiplayer_authority(peer_id)

	var sync_node = player.get_node_or_null("MultiplayerSynchronizer")
	if sync_node:
		sync_node.set_multiplayer_authority(peer_id)

	return player

func _spawn_player_for_peer(peer_id: int, spawn_idx: int) -> void:
	if not multiplayer.is_server():
		return
	if players_container and players_container.has_node("Player_%d" % peer_id):
		return
	if not scores.has(peer_id):
		scores[peer_id] = 0

	var spawn_pos := spawn_positions[spawn_idx % spawn_positions.size()]
	var loadout: Dictionary = GameState.multiplayer_loadouts.get(peer_id, {})
	var c_id: String = loadout.get("char", "mark")
	# Standard start weapon: Plasma Carbine (rifle)
	var w_id: String = "rifle"

	spawner.spawn({
		"peer_id": peer_id,
		"pos": spawn_pos,
		"char_id": c_id,
		"weapon_id": w_id
	})

func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_spawn_player_for_peer(peer_id, 1)

func _on_peer_disconnected(peer_id: int) -> void:
	_handle_disconnect("Opponent disconnected.")

func _on_server_disconnected() -> void:
	_handle_disconnect("The host left the match.")

func _handle_disconnect(msg: String) -> void:
	if is_game_over:
		return
	is_game_over = true
	if hud and hud.has_method("show_banner"):
		hud.show_banner("%s Returning to Lobby in 3s..." % msg, Color(1.0, 0.4, 0.3), 3.0)

	var timer := get_tree().create_timer(3.0)
	timer.timeout.connect(func():
		Net.leave()
		GameState.mode = "offline"
		var tree := get_tree()
		if tree:
			tree.call_deferred("change_scene_to_file", "res://scenes/ui/Lobby.tscn")
	)

func _spawn_bot_waves() -> void:
	var bot1 = ENEMY_SCENE.instantiate()
	bot1.global_position = Vector2(1280, 500)
	$Enemies.add_child(bot1)

func report_death_to_server(victim_peer_id: int, killer_id: int) -> void:
	if not multiplayer.is_server() and multiplayer.has_multiplayer_peer():
		notify_server_death.rpc_id(1, victim_peer_id, killer_id)

@rpc("any_peer", "call_local", "reliable")
func notify_server_death(victim_peer_id: int, killer_id: int) -> void:
	if multiplayer.is_server():
		register_player_death(victim_peer_id, killer_id)

func register_player_death(victim_peer_id: int, killer_id: int) -> void:
	if not multiplayer.is_server() or is_game_over:
		return

	# Only human players (positive peer ID) respawn via player spawner
	if victim_peer_id <= 0:
		return

	# Prevent duplicate death events for the same peer during their respawn delay
	if respawning_peers.get(victim_peer_id, false):
		return
	respawning_peers[victim_peer_id] = true

	var award_peer := killer_id
	if award_peer == 0 or award_peer == victim_peer_id:
		for pid in scores:
			if pid != victim_peer_id:
				award_peer = pid
				break

	if award_peer > 0:
		scores[award_peer] = scores.get(award_peer, 0) + 1

	sync_scores.rpc(scores)
	broadcast_kill_banner.rpc(award_peer, victim_peer_id)

	# Check win condition
	for pid in scores:
		if scores[pid] >= frag_limit:
			announce_winner.rpc(pid)
			return

	# Schedule respawn after 2.5 seconds (spawns with standard Plasma Carbine)
	var timer := get_tree().create_timer(2.5)
	timer.timeout.connect(func():
		respawning_peers[victim_peer_id] = false
		if is_game_over:
			return

		# Clean up any lingering node for this peer before spawning
		if players_container:
			var old_node = players_container.get_node_or_null("Player_%d" % victim_peer_id)
			if old_node and is_instance_valid(old_node):
				old_node.name = "OldDead_%d" % randi()
				old_node.queue_free()

		# Choose a dynamic, unpredictable random spawn point away from opponent
		var new_pos := _get_random_respawn_position()
		var loadout: Dictionary = GameState.multiplayer_loadouts.get(victim_peer_id, {})
		spawner.spawn({
			"peer_id": victim_peer_id,
			"pos": new_pos,
			"char_id": loadout.get("char", "mark"),
			"weapon_id": "rifle"
		})
	)

func _get_random_respawn_position() -> Vector2:
	# 1. Locate any alive opponents currently on the field
	var opponent_positions: Array[Vector2] = []
	if players_container:
		for child in players_container.get_children():
			if child is NeonPlayer and not child.is_dead and not child.name.begins_with("Old") and not child.name.begins_with("Stale"):
				opponent_positions.append(child.global_position)

	# 2. Filter candidate spawn points that are safely away from opponent (at least 550 px)
	var safe_candidates: Array[Vector2] = []
	for pos in spawn_positions:
		var is_safe := true
		for opp_pos in opponent_positions:
			if pos.distance_to(opp_pos) < 550.0:
				is_safe = false
				break
		if is_safe:
			safe_candidates.append(pos)

	# 3. Pick a random candidate from the safe list
	if not safe_candidates.is_empty():
		return safe_candidates[randi() % safe_candidates.size()]

	# Fallback: pick any random spawn point across all 12 positions
	return spawn_positions[randi() % spawn_positions.size()]

@rpc("authority", "call_local", "reliable")
func broadcast_kill_banner(killer_id: int, victim_id: int) -> void:
	if not hud or not hud.has_method("show_banner"):
		return

	var my_id := multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 0
	if killer_id == my_id:
		hud.show_banner("YOU ELIMINATED OPPONENT! (+1 FRAG)", Color(0.2, 1.0, 0.4), 2.2)
	elif victim_id == my_id:
		hud.show_banner("YOU WERE ELIMINATED! RESPAWNING...", Color(1.0, 0.35, 0.25), 2.2)
	else:
		hud.show_banner("FRAG RECORDED!", Color(0.9, 0.8, 0.2), 2.0)

@rpc("authority", "call_local", "reliable")
func sync_scores(updated_scores: Dictionary) -> void:
	scores = updated_scores
	_update_hud_display()

func _update_scoreboard_text() -> void:
	if hud and hud.goal_label:
		if GameState.game_mode == "deathmatch":
			hud.set_goal("1v1 DUEL: First to %d Deaths / Frags Wins!" % frag_limit)
		elif GameState.game_mode == "tdm":
			hud.set_goal("TEAM DEATHMATCH: Blue vs Red (Goal: %d Frags)" % frag_limit)
		else:
			hud.set_goal("SURVIVAL: Eliminate all hostiles! (Target: %d)" % frag_limit)

@rpc("authority", "call_local", "reliable")
func announce_winner(winner_id: int) -> void:
	is_game_over = true
	var my_id := multiplayer.get_unique_id()
	var i_won: bool = (winner_id == my_id)

	if hud and hud.has_method("show_banner"):
		var end_msg := "VICTORY! YOU WON THE MATCH!" if i_won else "MATCH OVER! OPPONENT WINS!"
		var end_col := Color(0.2, 1.0, 0.4) if i_won else Color(1.0, 0.3, 0.3)
		hud.show_banner(end_msg, end_col, 3.0)

	GameState.last_result = {
		"won": i_won,
		"stars": 3 if i_won else 1,
		"level": GameState.current_level,
		"score": scores.get(my_id, 0)
	}

	var timer := get_tree().create_timer(2.2)
	timer.timeout.connect(func():
		var tree := get_tree()
		if tree:
			tree.call_deferred("change_scene_to_file", "res://scenes/ui/Result.tscn")
	)

func _evaluate_time_over() -> void:
	var top_peer: int = 1
	var top_frags: int = -1
	for pid in scores:
		if scores[pid] > top_frags:
			top_frags = scores[pid]
			top_peer = pid

	announce_winner.rpc(top_peer)
