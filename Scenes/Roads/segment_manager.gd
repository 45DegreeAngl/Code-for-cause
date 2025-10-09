# RoadManager.gd
extends Node

## Manages the logic for which road segments to load and spawn.
## Decides when to spawn a new road and which type to use.

# --- EXPORTS ---
# Assign the RoadSpawner node here in the inspector
@export var spawner: Node
@export var exes_house: PackedScene = null

@export_subgroup("RNG Settings")
@export var max_gabesmart_pity: int = 5
@export_range(0, 1, 0.01) var gabesmart_chance: float

# --- CACHING AND LOADING ---
const MAX_ROAD_SEGMENTS_LOADED: int = 7
const MAX_GABE_SEGMENTS_LOADED: int = 3
var _loading_road_requests: Dictionary = {}
var _loading_gabe_requests: Dictionary = {}
var road_seg_to_load: Dictionary = {}
var gabesmart_seg_to_load: Dictionary = {}
var road_segments: Dictionary = {}
var gabesmart_segments: Dictionary = {}

var gabesmart_pity = 0

signal road_generated

# --- GAME STATE ---
var cur_player_road: int = 0:
	set(value):
		cur_player_road = value
		
		# Tell the spawner what to do based on game state
		if value > Globals.roads_to_win and Globals.roads_to_win != int(INF):
			pass
		elif value == int(Globals.roads_to_win) and Globals.roads_to_win != int(INF):
			if exes_house:
				spawner.append_segment(exes_house)
		else:
			var next_segment_scene = _get_next_road_scene()
			if next_segment_scene:
				spawner.append_segment(next_segment_scene)
		
		# Tell spawner to perform cleanup
		spawner.remove_oldest_segment_if_needed()

func _ready():
	if not spawner:
		printerr("RoadManager: The 'spawner' property is not set! Assign the RoadSpawner node.")
		get_tree().quit()

	# Assuming the RoadManager is the main world node
	Globals.world_node = self
	if not gabesmart_chance:
		gabesmart_chance = 1.0 / (2.0 * max_gabesmart_pity)
	
	# Step 1: Find all available segment file paths
	populate_road_segment_paths()
	populate_gabe_segment_paths()
	
	# Step 2: Load the FIRST batch synchronously
	_load_initial_segments()
	
	# Step 3: Tell the spawner to build the starting area
	for _i in range(3):
		spawner.append_segment(_get_next_road_scene())
		
	# Step 4: Kick off background loading for future segments
	fill_segment_cache()
	
	road_generated.emit()

func _process(_delta):
	# This node is still responsible for checking the status of loading resources
	_check_loading_status()
	fill_segment_cache()

# This is the old "spawn_road" function, but renamed.
# Its only job is to CHOOSE a PackedScene from the cache.
func _get_next_road_scene() -> PackedScene:
	var use_gabesmart = (gabesmart_pity >= max_gabesmart_pity or randf() <= gabesmart_chance)

	if use_gabesmart and not gabesmart_segments.is_empty():
		gabesmart_pity = 0
		return gabesmart_segments.values().pick_random()
	elif not road_segments.is_empty():
		gabesmart_pity += 1
		return road_segments.values().pick_random()
	else:
		printerr("Could not get a road scene, no segments are loaded!")
		return null

# Public function that can be called from anywhere (e.g., a trigger on a road segment)
func increment_player_road():
	self.cur_player_road += 1

func populate_road_segment_paths():
	road_seg_to_load = {}
	var file_array: Array = Globals.get_exported_files("res://Scenes/Roads/Normal Segments")
	
	for file: String in file_array:
		if file.contains(".import"):
			continue
		var nickname: String = file.get_file().get_basename()
		road_seg_to_load[nickname] = file

func populate_gabe_segment_paths():
	gabesmart_seg_to_load = {}
	var file_array: Array = Globals.get_exported_files("res://Scenes/Roads/Gabesmart Segments")

	for file: String in file_array:
		if file.contains(".import"):
			continue
		var nickname: String = file.get_file().get_basename()
		gabesmart_seg_to_load[nickname] = file

func _load_initial_segments():
	# Load normal roads
	var road_keys = road_seg_to_load.keys()
	road_keys.shuffle()
	for i in range(min(road_keys.size(), MAX_ROAD_SEGMENTS_LOADED)):
		var key = road_keys[i]
		road_segments[key] = load(road_seg_to_load[key])

	# Load Gabesmart roads
	var gabe_keys = gabesmart_seg_to_load.keys()
	gabe_keys.shuffle()
	for i in range(min(gabe_keys.size(), MAX_GABE_SEGMENTS_LOADED)):
		var key = gabe_keys[i]
		gabesmart_segments[key] = load(gabesmart_seg_to_load[key])
	
	print("Initial segments loaded synchronously.")

func _check_loading_status():
	# Check status of normal road segments
	var finished_roads = []
	for nickname in _loading_road_requests.keys():
		var status = ResourceLoader.load_threaded_get_status(road_seg_to_load[nickname])
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource = ResourceLoader.load_threaded_get(road_seg_to_load[nickname])
			road_segments[nickname] = resource
			finished_roads.append(nickname)
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			printerr("Failed to load road segment: ", nickname)
			finished_roads.append(nickname)
	for nickname in finished_roads:
		_loading_road_requests.erase(nickname)

	# Check status of Gabesmart segments (same logic)
	var finished_gabes = []
	for nickname in _loading_gabe_requests.keys():
		var status = ResourceLoader.load_threaded_get_status(gabesmart_seg_to_load[nickname])
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource = ResourceLoader.load_threaded_get(gabesmart_seg_to_load[nickname])
			gabesmart_segments[nickname] = resource
			finished_gabes.append(nickname)
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			printerr("Failed to load Gabesmart segment: ", nickname)
			finished_gabes.append(nickname)
	for nickname in finished_gabes:
		_loading_gabe_requests.erase(nickname)

func fill_segment_cache():
	while road_segments.size() + _loading_road_requests.size() < MAX_ROAD_SEGMENTS_LOADED:
		if not request_random_road_seg():
			break

	while gabesmart_segments.size() + _loading_gabe_requests.size() < MAX_GABE_SEGMENTS_LOADED:
		if not request_random_gabe_seg():
			break

func request_random_road_seg() -> bool:
	var potential_keys = road_seg_to_load.keys().filter(func(k): return not road_segments.has(k) and not _loading_road_requests.has(k))

	if potential_keys.is_empty():
		return false # All available segments are loaded or loading
	
	var chosen_key: String = potential_keys.pick_random()
	ResourceLoader.load_threaded_request(road_seg_to_load[chosen_key])
	_loading_road_requests[chosen_key] = true
	return true

func request_random_gabe_seg() -> bool:
	var potential_keys = gabesmart_seg_to_load.keys().filter(func(k): return not gabesmart_segments.has(k) and not _loading_gabe_requests.has(k))

	if potential_keys.is_empty():
		return false
	
	var chosen_key: String = potential_keys.pick_random()
	ResourceLoader.load_threaded_request(gabesmart_seg_to_load[chosen_key])
	_loading_gabe_requests[chosen_key] = true
	return true
