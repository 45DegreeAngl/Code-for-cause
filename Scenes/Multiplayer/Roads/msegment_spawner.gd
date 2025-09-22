#segment spawner
extends Node

const MAX_ROAD_SEGMENTS_LOADED: int = 7
const MAX_GABE_SEGMENTS_LOADED: int = 3

# Dictionaries to track the loading progress of resources.
var _loading_road_requests: Dictionary = {}
var _loading_gabe_requests: Dictionary = {}

# Road segments available to load (path strings)
var road_seg_to_load: Dictionary = {}
var gabesmart_seg_to_load: Dictionary = {}

# Nickname : Road (fully loaded PackedScenes)
@onready var glob_path: Path3D = $"Global Path"
var road_segments: Dictionary = {}
var gabesmart_segments: Dictionary = {}
@export var exes_house: PackedScene = null

@export_subgroup("RNG Settings")
@export var max_gabesmart_pity: int = 5
@export_range(0, 1, 0.01) var gabesmart_chance: float

var gabesmart_pity = 0

@export_subgroup("Game Variables")
@export var pedestrians_node: Node3D
@export var road_node: Node3D
@export var previous_road: Node
@export var players_node : Node3D

@export var is_multiplayer: bool = false
var network_id = -1

signal road_generated

func _ready():
	network_id = Globals.generate_network_id()
	Globals.register_static_node("segment_spawner",self)
	Globals.world_node = self
	Globals.driving_path = glob_path
	if not gabesmart_chance:
		gabesmart_chance = 1.0 / (2.0 * max_gabesmart_pity)
	
	# Step 1: Find all available segment file paths (this is fast)
	populate_road_segment_paths()
	populate_gabe_segment_paths()
	
	# In multiplayer, only the host generates the initial layout.
	if is_multiplayer and not Network.is_host:
		return
		
	# FIX: Step 2: Load the FIRST batch of segments SYNCHRONOUSLY to prevent a crash.
	_load_initial_segments()
	
	# Step 3: Now that we have segments loaded, we can safely build the starting area.
	for num_roads in range(3):
		append_segment()
		
	# Step 4: Kick off the background loading system for all FUTURE segments.
	fill_segment_cache()
	
	Debug.sober_node = pedestrians_node
	
	road_generated.emit()

# NEW FUNCTION: Loads the initial set of roads using the blocking `load()`
# This ensures we have segments ready to go at the very start of the game.
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

func _process(_delta):
	# Background loading can happen on all machines
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
	
	# Continuously try to fill the cache in the background
	fill_segment_cache()

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

func spawn_road(segment_key: String = "") -> Node3D:
	var instanced_segment: Node3D
	
	if segment_key.is_empty():
		# This path is for the host to decide a new road
		if not Network.is_host and is_multiplayer: return null # Clients can't decide
		
		var use_gabesmart = (gabesmart_pity >= max_gabesmart_pity or randf() <= gabesmart_chance)
		if use_gabesmart and not gabesmart_segments.is_empty():
			segment_key = gabesmart_segments.keys().pick_random()
			gabesmart_pity = 0
		elif not road_segments.is_empty():
			segment_key = road_segments.keys().pick_random()
			gabesmart_pity += 1
		else:
			printerr("Could not spawn road, no segments are loaded!")
			return null
		
		# Host tells clients to spawn this segment
		if is_multiplayer:
			Network.p2p_call_func(network_id, "spawn_segment_from_host", [segment_key])

	# All peers (host and clients) instance the segment using the key
	if gabesmart_segments.has(segment_key):
		instanced_segment = gabesmart_segments[segment_key].instantiate()
		gabesmart_segments.erase(segment_key) # Remove from available pool
	elif road_segments.has(segment_key):
		instanced_segment = road_segments[segment_key].instantiate()
		road_segments.erase(segment_key) # Remove from available pool
	else:
		# Maybe it's still loading? This is a potential race condition.
		# For now, we'll just warn. A more robust system might queue the spawn.
		printerr("Client or host tried to spawn segment '%s' but it was not in the loaded cache." % segment_key)
		return null

	instanced_segment.name = str(cur_player_road + road_node.get_child_count())
	return instanced_segment

func spawn_segment_from_host(segment_key: String):
	# This function is called on clients via P2P call
	if Network.is_host: return # Host already spawned it
	append_segment(segment_key)

func append_segment(segment_identifier = ""): # Can be a PackedScene or a String key
	var instanced_segment
	if segment_identifier is PackedScene:
		# This handles the special case for exes_house
		var house_key = "exes_house"
		instanced_segment = segment_identifier.instantiate()
		instanced_segment.name = house_key
		if is_multiplayer and Network.is_host:
			Network.p2p_call_func(network_id, "spawn_segment_from_host", [house_key])

	elif segment_identifier is String:
		instanced_segment = spawn_road(segment_identifier)
	else:
		instanced_segment = spawn_road()


	if not is_instance_valid(instanced_segment):
		return

	if instanced_segment.has_method("set"): # Check if it's a valid object
		if "is_multiplayer" in instanced_segment:
			instanced_segment.set("is_multiplayer", is_multiplayer)

	instanced_segment.visible = false
	road_node.add_child(instanced_segment)
	instanced_segment.global_position = previous_road.find_child("Exit").global_position
	
	if instanced_segment.has_signal("increment_player_road_counter"):
		instanced_segment.increment_player_road_counter.connect(increment_player_road)
	
	previous_road = instanced_segment
	
	if "nav_curve" in instanced_segment and instanced_segment.nav_curve is Path3D:
		var local_path: Path3D = instanced_segment.nav_curve
		var local_curve: Curve3D = local_path.curve
		if local_curve:
			var start_index = 1 if glob_path.curve.get_point_count() > 0 else 0
			for i in range(start_index, local_curve.get_point_count()):
				var local_pos = local_curve.get_point_position(i)
				var local_in = local_curve.get_point_in(i)
				var local_out = local_curve.get_point_out(i)
				
				var world_pos = local_path.to_global(local_pos)
				var world_in = local_path.to_global(local_in + local_pos) - world_pos
				var world_out = local_path.to_global(local_out + local_pos) - world_pos
				
				glob_path.curve.add_point(world_pos, world_in, world_out)
	else:
		print("Warning: Road segment '", instanced_segment.name, "' script is missing 'nav_curve' variable.")
	
	instanced_segment.visible = true
	#instanced_segment.spawn_drivers()

var cur_player_road: int = 0:
	set(value):
		# This logic should only run on the host in a multiplayer game
		if is_multiplayer and not Network.is_host:
			cur_player_road = value
			return
			
		if value > Globals.roads_to_win and Globals.roads_to_win != int(INF):
			pass
		elif value == int(Globals.roads_to_win) and Globals.roads_to_win != int(INF):
			if exes_house:
				append_segment(exes_house)
		else:
			append_segment()

		cur_player_road = value
		
		if is_multiplayer and Network.is_host:
			Network.p2p_change_value(network_id, "cur_player_road", value)

		if road_node.get_child_count() > 8:
			var road_to_remove: Node3D = road_node.get_child(0)
			
			if "nav_curve" in road_to_remove and road_to_remove.nav_curve is Path3D:
				var path_to_remove: Path3D = road_to_remove.nav_curve
				var points_to_remove = path_to_remove.curve.get_point_count() - 1
				points_to_remove = max(0, points_to_remove)
				
				for i in range(points_to_remove):
					if glob_path.curve.get_point_count() > 0:
						glob_path.curve.remove_point(0)
			
			for pedestrian : Node3D in Globals.world_node.find_child("Pedestrians").get_children():
				if pedestrian.global_position.z > road_to_remove.global_position.z:
					pedestrian.call_deferred("queue_free")
			road_to_remove.queue_free()

func get_road_at_pos(glob_pos:Vector3)->Node:
	var last_road : Node = road_node.get_children().back()
	var cur_road : Node
	for index:int in road_node.get_child_count():
		cur_road = road_node.get_child(index)
		if glob_pos.z>cur_road.global_position.z:
			return road_node.get_child(index-1)
	return last_road

func get_next_road(cur:Node,reverse:bool=false)->Node:
	var result:Node
	var road_array:Array = road_node.get_children()
	var result_index = road_array.find(cur)
	if reverse:
		result_index = maxi(0,result_index-1)
	else:
		result_index = mini(road_array.size()-1,result_index+1)
	
	result = road_array[result_index]
	return result

func increment_player_road():
	# In multiplayer, only the host should increment the official road count
	if is_multiplayer and not Network.is_host:
		return
	cur_player_road+=1
