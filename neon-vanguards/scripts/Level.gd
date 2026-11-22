extends Node2D

@export var level_number: int = 1
@export var goal_text: String = "Eliminate all rogue drones"
@export var time_limit: float = 60.0
@export var target_score: int = 1

var time_left: float
var score: int = 0
var finished: bool = false
var current_map_width: float = 1280.0
var current_map_height: float = 720.0

@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	if DisplayServer.has_method("screen_set_orientation"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	AudioManager.play_music()
	time_left = time_limit
	if hud and hud.has_method("set_goal"):
		hud.set_goal(goal_text)
	_update_hud()
	_adapt_map_to_screen()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed() -> void:
	_adapt_map_to_screen()

func get_map_bounds() -> Rect2:
	return Rect2(0, 0, current_map_width, current_map_height)

func _adapt_map_to_screen() -> void:
	var vp := get_viewport_rect().size
	var w := maxf(1280.0, vp.x)
	var h := maxf(720.0, vp.y)
	current_map_width = w
	current_map_height = h

	# 1. Expand Background TextureRect to full responsive bounds
	var bg := get_node_or_null("Background") as TextureRect
	if bg:
		bg.offset_left = 0
		bg.offset_top = 0
		bg.offset_right = w
		bg.offset_bottom = h
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE

	# 2. Expand Floor and Trim Visuals in Bounds
	var bounds := get_node_or_null("Bounds") as StaticBody2D
	if bounds:
		for child in bounds.get_children():
			if child is ColorRect:
				child.offset_left = 0
				child.offset_right = w
				if child.name == "FloorVisual":
					child.offset_bottom = h

		# 3. Expand Physics Collisions (Floor, Ceiling, RightWall)
		var floor_col := bounds.get_node_or_null("Floor") as CollisionPolygon2D
		if floor_col:
			floor_col.polygon = PackedVector2Array([
				Vector2(0, 670), Vector2(w, 670), Vector2(w, h), Vector2(0, h)
			])

		var ceil_col := bounds.get_node_or_null("Ceiling") as CollisionPolygon2D
		if ceil_col:
			ceil_col.polygon = PackedVector2Array([
				Vector2(0, 0), Vector2(w, 0), Vector2(w, 20), Vector2(0, 20)
			])

		var right_col := bounds.get_node_or_null("RightWall") as CollisionPolygon2D
		if right_col:
			right_col.polygon = PackedVector2Array([
				Vector2(w - 20, 0), Vector2(w, 0), Vector2(w, h), Vector2(w - 20, h)
			])

	# 4. Center ambient particles across the responsive width
	for child in get_children():
		if child is CPUParticles2D:
			child.position.x = w * 0.5
			child.emission_rect_extents.x = w * 0.5

	# 5. Immediately update camera limits on local player
	var player := get_tree().get_first_node_in_group("player") as NeonPlayer
	if not player:
		player = get_node_or_null("Player") as NeonPlayer
	if player and player.camera_node:
		player.camera_node.limit_left = 0
		player.camera_node.limit_top = 0
		player.camera_node.limit_right = int(w)
		player.camera_node.limit_bottom = int(h)

func _process(delta: float) -> void:
	if finished:
		return
	time_left -= delta
	_update_hud()
	if time_left <= 0.0:
		end_level(false)

func _update_hud() -> void:
	if hud and hud.has_method("update_status"):
		hud.update_status(time_left, score, target_score)

func add_score(points: int) -> void:
	score += points
	_update_hud()
	if score >= target_score:
		end_level(true)

func end_level(won: bool) -> void:
	if finished:
		return
	finished = true
	var stars: int = 0
	if won:
		stars = 1
		if time_left > time_limit * 0.5:
			stars = 3
		elif time_left > time_limit * 0.25:
			stars = 2
		GameState.complete_level(level_number, stars)

	GameState.last_result = {
		"won": won,
		"stars": stars,
		"level": level_number,
		"score": score
	}
	var tree := get_tree()
	if tree:
		tree.call_deferred("change_scene_to_file", "res://scenes/ui/Result.tscn")
