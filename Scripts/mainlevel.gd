extends Node2D

@export_group("Generation Settings")
@export var chunk_size: int = 24
@export var rock_spawn_chance: float = 0.05
@export var cave_openness: float = -0.05 # Controls how wide/narrow tunnels are
@export var rock_scene: PackedScene

@onready var tile_map: TileMap = $TileMap
@onready var player: CharacterBody2D = $Player

var generated_chunks = {}
var internal_seed: int
var noise: FastNoiseLite

func _ready() -> void:
	# 1. Setup Random Seed
	randomize()
	internal_seed = randi()
	
	# 2. Fix the 16x depth illusion
	tile_map.y_sort_enabled = true
	player.y_sort_enabled = true
	
	# 3. Configure the Noise for jagged, narrow caves
	noise = FastNoiseLite.new()
	noise.seed = internal_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.025
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	
	# 4. Build the start area
	generate_initial_area()

func _process(_delta: float) -> void:
	update_chunks()

func update_chunks() -> void:
	var p_pos = tile_map.local_to_map(tile_map.to_local(player.global_position))
	var p_chunk = Vector2i(floor(float(p_pos.x) / chunk_size), floor(float(p_pos.y) / chunk_size))
	
	# Keep a 3x3 grid of chunks loaded around the player
	for x in range(-1, 2):
		for y in range(-1, 2):
			var target = p_chunk + Vector2i(x, y)
			if not generated_chunks.has(target):
				generate_chunk(target)

func is_floor_at(pos: Vector2i) -> bool:
	# Guarantee a safe open space at exactly 0,0 so you don't spawn in a wall
	if pos.length() < 5.0: 
		return true 
	
	# Check the noise math
	var val = noise.get_noise_2d(pos.x, pos.y)
	return val < cave_openness

func generate_chunk(chunk_pos: Vector2i) -> void:
	generated_chunks[chunk_pos] = true
	var start_x = chunk_pos.x * chunk_size
	var start_y = chunk_pos.y * chunk_size
	
	var floor_cells: Array[Vector2i] = []
	
	# Step 1: Carve out the dirt floors and spawn rocks
	for x in range(start_x, start_x + chunk_size):
		for y in range(start_y, start_y + chunk_size):
			var pos = Vector2i(x, y)
			if is_floor_at(pos):
				floor_cells.append(pos)
				seed(hash(pos) + internal_seed)
				if randf() < rock_spawn_chance: 
					spawn_rock(pos)

	# Step 2: Tell Godot's built-in terrain to draw walls around the floors
	tile_map.set_cells_terrain_connect(0, floor_cells, 0, 0)
	
	# Step 3: Draw roofs and void safely after the walls are finished
	call_deferred("add_roofs_and_void", start_x, start_y)

func add_roofs_and_void(start_x: int, start_y: int) -> void:
	for x in range(start_x - 1, start_x + chunk_size + 1):
		for y in range(start_y - 1, start_y + chunk_size + 1):
			var pos = Vector2i(x, y)
			var atlas = tile_map.get_cell_atlas_coords(0, pos)
			
			# Fill empty spaces with the void tile (0, 5)
			if atlas == Vector2i(-1, -1):
				tile_map.set_cell(0, pos, 0, Vector2i(0, 5))
				
			# Check what wall Godot just placed, and put the matching roof above it
			elif atlas == Vector2i(1, 1):
				tile_map.set_cell(0, pos + Vector2i.UP, 0, Vector2i(1, 0)) # Top Wall Roof
			elif atlas == Vector2i(0, 1):
				tile_map.set_cell(0, pos + Vector2i.UP, 0, Vector2i(0, 0)) # Top-Left Roof
			elif atlas == Vector2i(2, 1):
				tile_map.set_cell(0, pos + Vector2i.UP, 0, Vector2i(2, 0)) # Top-Right Roof

func generate_initial_area() -> void:
	for x in range(-1, 2):
		for y in range(-1, 2):
			generate_chunk(Vector2i(x, y))
	
	# Safely drop the player directly in the cleared starting zone
	player.global_position = tile_map.to_global(tile_map.map_to_local(Vector2i.ZERO))

func spawn_rock(grid_pos: Vector2i) -> void:
	if rock_scene == null: return
	var new_rock = rock_scene.instantiate()
	new_rock.position = tile_map.to_global(tile_map.map_to_local(grid_pos))
	new_rock.y_sort_enabled = true
	call_deferred("add_child", new_rock)
