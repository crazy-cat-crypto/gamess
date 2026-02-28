extends Node2D

const TILE_SIZE: int = 16
const WORLD_WIDTH: int = 120
const WORLD_HEIGHT: int = 60
const SURFACE_ROW: int = 10

const TARGET_SHARDS: int = 10
const MAX_OXYGEN: float = 100.0
const OXYGEN_DRAIN_PER_SEC: float = 10.0
const OXYGEN_REFILL_PER_SEC: float = 30.0

const BLOCK_DIRT: int = 0
const BLOCK_STONE: int = 1
const BLOCK_BEDROCK: int = 2

@onready var world: Node2D = $World
@onready var player: CharacterBody2D = $Player
@onready var oxygen_bar: ProgressBar = $HUD/OxygenBar
@onready var shard_label: Label = $HUD/ShardLabel
@onready var status_label: Label = $HUD/StatusLabel

var block_scene: PackedScene = preload("res://scenes/block.tscn")
var shard_scene: PackedScene = preload("res://scenes/shard.tscn")

var blocks: Dictionary = {}
var oxygen: float = MAX_OXYGEN
var collected_shards: int = 0
var game_over: bool = false

func _ready() -> void:
	randomize()
	_build_world()
	_spawn_player()
	_carve_starter_path()
	_place_initial_shards(TARGET_SHARDS)
	player.mine_requested.connect(_on_mine_requested)
	_update_hud("Mine with left click. Collect 10 shards and return to surface.")

func _process(delta: float) -> void:
	if game_over:
		if Input.is_key_pressed(KEY_R):
			get_tree().reload_current_scene()
		return

	var underground: bool = player.global_position.y > float(SURFACE_ROW * TILE_SIZE)
	if underground:
		oxygen = maxf(0.0, oxygen - OXYGEN_DRAIN_PER_SEC * delta)
	else:
		oxygen = minf(MAX_OXYGEN, oxygen + OXYGEN_REFILL_PER_SEC * delta)

	if oxygen <= 0.0:
		_end_game(false, "Out of oxygen! Press R to restart.")
		return

	if collected_shards >= TARGET_SHARDS and not underground:
		_end_game(true, "You escaped with all shards! Press R to play again.")
		return

	_update_hud()

func _build_world() -> void:
	for y in range(SURFACE_ROW, WORLD_HEIGHT):
		for x in range(WORLD_WIDTH):
			if y == WORLD_HEIGHT - 1:
				_spawn_block(Vector2i(x, y), BLOCK_BEDROCK)
			elif y > 36:
				_spawn_block(Vector2i(x, y), BLOCK_STONE)
			else:
				_spawn_block(Vector2i(x, y), BLOCK_DIRT)

	_carve_random_caves(14, 120)

func _spawn_block(cell: Vector2i, block_type: int) -> void:
	var block: StaticBody2D = block_scene.instantiate()
	block.position = Vector2(cell.x * TILE_SIZE, cell.y * TILE_SIZE)
	block.set_block_type(block_type)
	world.add_child(block)
	blocks[cell] = block

func _remove_block(cell: Vector2i) -> void:
	if not blocks.has(cell):
		return
	var block: Node = blocks[cell]
	blocks.erase(cell)
	block.queue_free()

func _spawn_player() -> void:
	player.global_position = Vector2((WORLD_WIDTH / 2) * TILE_SIZE, (SURFACE_ROW - 2) * TILE_SIZE)

func _carve_starter_path() -> void:
	var shaft_x: int = WORLD_WIDTH / 2
	for y in range(SURFACE_ROW, SURFACE_ROW + 8):
		_remove_block(Vector2i(shaft_x, y))
		_remove_block(Vector2i(shaft_x + 1, y))

func _carve_random_caves(walkers: int, steps: int) -> void:
	for _i in range(walkers):
		var pos := Vector2i(randi_range(8, WORLD_WIDTH - 9), randi_range(SURFACE_ROW + 4, WORLD_HEIGHT - 8))
		for _j in range(steps):
			for y in range(-1, 2):
				for x in range(-1, 2):
					_remove_block(pos + Vector2i(x, y))
			pos.x = clampi(pos.x + randi_range(-1, 1), 1, WORLD_WIDTH - 2)
			pos.y = clampi(pos.y + randi_range(-1, 1), SURFACE_ROW + 2, WORLD_HEIGHT - 3)

func _place_initial_shards(count: int) -> void:
	var placed: int = 0
	var attempts: int = 0
	while placed < count and attempts < 2000:
		attempts += 1
		var cell := Vector2i(randi_range(4, WORLD_WIDTH - 5), randi_range(SURFACE_ROW + 6, WORLD_HEIGHT - 5))
		if blocks.has(cell):
			var block: StaticBody2D = blocks[cell]
			if not block.breakable:
				continue
			_remove_block(cell)
		if _has_open_neighbor(cell):
			_spawn_shard(cell)
			placed += 1

func _spawn_shard(cell: Vector2i) -> void:
	var shard: Area2D = shard_scene.instantiate()
	shard.global_position = Vector2(cell.x * TILE_SIZE + TILE_SIZE * 0.5, cell.y * TILE_SIZE + TILE_SIZE * 0.5)
	shard.picked.connect(_on_shard_picked)
	world.add_child(shard)

func _has_open_neighbor(cell: Vector2i) -> bool:
	var neighbors := [
		Vector2i(cell.x + 1, cell.y),
		Vector2i(cell.x - 1, cell.y),
		Vector2i(cell.x, cell.y + 1),
		Vector2i(cell.x, cell.y - 1)
	]
	for n in neighbors:
		if not blocks.has(n):
			return true
	return false

func _on_mine_requested(world_position: Vector2) -> void:
	if game_over:
		return

	var cell := _world_to_cell(world_position)
	if not blocks.has(cell):
		return

	var target_center := Vector2(cell.x * TILE_SIZE + TILE_SIZE * 0.5, cell.y * TILE_SIZE + TILE_SIZE * 0.5)
	if player.global_position.distance_to(target_center) > player.mine_reach + 8.0:
		return

	var block: StaticBody2D = blocks[cell]
	if not block.breakable:
		return

	_remove_block(cell)

func _on_shard_picked() -> void:
	collected_shards += 1
	if collected_shards >= TARGET_SHARDS:
		_update_hud("Return to the surface!")

func _world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / TILE_SIZE), floori(world_position.y / TILE_SIZE))

func _end_game(won: bool, message: String) -> void:
	game_over = true
	if won:
		status_label.text = "WIN: " + message
	else:
		status_label.text = "LOSE: " + message

func _update_hud(message: String = "") -> void:
	oxygen_bar.max_value = MAX_OXYGEN
	oxygen_bar.value = oxygen
	shard_label.text = "Shards: %d/%d" % [collected_shards, TARGET_SHARDS]
	if message != "":
		status_label.text = message
	elif not game_over:
		status_label.text = "Surface refills oxygen. Press R to restart."
