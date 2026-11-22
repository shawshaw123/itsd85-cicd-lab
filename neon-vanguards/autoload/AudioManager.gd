extends Node

var bgm_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE := 8

const SOUNDS: Dictionary = {
	"gun_rifle": preload("res://assets/audio/gun_rifle.wav"),
	"gun_shotgun": preload("res://assets/audio/gun_shotgun.wav"),
	"gun_sniper": preload("res://assets/audio/gun_sniper.wav"),
	"gun_rocket": preload("res://assets/audio/gun_rocket.wav"),
	"explosion": preload("res://assets/audio/explosion.wav"),
	"pickup": preload("res://assets/audio/pickup.wav"),
	"hurt": preload("res://assets/audio/hurt.wav"),
	"reload": preload("res://assets/audio/reload.wav"),
}

var bgm_stream: AudioStream = preload("res://assets/audio/bgm_battle.wav")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Ensure seamless loop on WAV stream
	if bgm_stream is AudioStreamWAV:
		var wav := bgm_stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		if wav.data and wav.data.size() > 0:
			wav.loop_end = int(wav.data.size() / 2)
		else:
			wav.loop_end = 0

	# 1. Background Music Player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = bgm_stream
	bgm_player.volume_db = 0.0 # Full clean volume
	bgm_player.bus = "Master"
	bgm_player.finished.connect(_on_bgm_finished)
	add_child(bgm_player)

	# 2. Sound Effects Pool
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.volume_db = 3.0 # Crisp, audible volume
		p.bus = "Master"
		add_child(p)
		sfx_pool.append(p)

	play_music()

func _process(_delta: float) -> void:
	if not GameState.sound_enabled:
		if bgm_player and bgm_player.playing:
			bgm_player.stop()
		return

	if bgm_player and not bgm_player.playing:
		bgm_player.play()

func _on_bgm_finished() -> void:
	if bgm_player:
		bgm_player.play()

func play_music() -> void:
	GameState.sound_enabled = true
	if not bgm_player:
		return
	if not bgm_player.playing:
		bgm_player.play()

func stop_music() -> void:
	if bgm_player and bgm_player.playing:
		bgm_player.stop()

func play_click_sfx() -> void:
	play_sfx("pickup", 1.4)

func play_gun_sfx(weapon_id: String) -> void:
	var sound_key := "gun_rifle"
	match weapon_id:
		"shotgun":
			sound_key = "gun_shotgun"
		"sniper":
			sound_key = "gun_sniper"
		"rocket":
			sound_key = "gun_rocket"
		_:
			sound_key = "gun_rifle"

	# Add slight pitch variation (0.95 to 1.05) for realistic punch
	var pitch := randf_range(0.96, 1.04)
	play_sfx(sound_key, pitch)

func play_sfx(sound_name: String, pitch: float = 1.0) -> void:
	if not GameState.sound_enabled:
		return

	var stream: AudioStream = SOUNDS.get(sound_name)
	if not stream:
		return

	# Find available player in pool
	var chosen: AudioStreamPlayer = null
	for p in sfx_pool:
		if not p.playing:
			chosen = p
			break

	if not chosen:
		chosen = sfx_pool[0]

	chosen.stream = stream
	chosen.pitch_scale = pitch
	chosen.play()
