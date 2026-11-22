extends Node

const PORT := 7777
const MAX_CLIENTS := 1 # 1 guest + 1 host = 2 players

signal match_ready
signal net_error(message: String)

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.connection_failed.connect(func(): _fail("Could not reach the host. Check that you are on the same Wi-Fi."))
	multiplayer.server_disconnected.connect(func(): _fail("The host left the game."))
	multiplayer.peer_disconnected.connect(func(_id): _fail("The other player left."))

func host_game() -> void:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(PORT, MAX_CLIENTS) != OK:
		_fail("Cannot start hosting on port %d." % PORT)
		return
	multiplayer.multiplayer_peer = peer

func join_game(ip: String) -> void:
	if ip.strip_edges() == "":
		_fail("Please enter a valid IP address.")
		return
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client(ip, PORT) != OK:
		_fail("Invalid address.")
		return
	multiplayer.multiplayer_peer = peer

func my_ip() -> String:
	for a in IP.get_local_addresses():
		if a.begins_with("192.168.") or a.begins_with("10.") or a.begins_with("172."):
			return a
	return "127.0.0.1"

func leave() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null

func _on_peer_connected(_id: int) -> void:
	if multiplayer.is_server():
		match_ready.emit()

func _fail(message: String) -> void:
	leave()
	net_error.emit(message)

