extends Node

const MAX_ROAD_SEGMENTS_LOADED: int = 7
const MAX_GABE_SEGMENTS_LOADED: int = 3
var road_load_fails : int = 0
var gabe_load_fails : int = 0

#road segments to load
var road_seg_to_load : Dictionary = {}
var gabesmart_seg_to_load : Dictionary = {}

#nickname : road
@onready var glob_path:Path3D = $"Global Path"
var road_segments : Dictionary = {}
var gabesmart_segments : Dictionary = {}
@export var exes_house : PackedScene = null

@export_subgroup("RNG Settings")
@export var max_gabesmart_pity : int = 5
@export_range(0,1,0.01) var gabesmart_chance : float

var gabesmart_pity = 0
var first_roads_loaded : bool = false
var first_gabes_loaded : bool = false

@export_subgroup("Game Variables")
@export var cops_node:Node3D
@export var pedestrians_node:Node3D
@export var road_node:Node3D
@export var previous_road:RoadSegment

signal road_generated

func _ready():
	Globals.world_node = self
	Globals.driving_path = glob_path
	if not gabesmart_chance:
		@warning_ignore("integer_division")
		gabesmart_chance = 1/(2*max_gabesmart_pity)
	load_road_segments_from_folder()
	load_gabe_segments_from_folder()
	
	for num_roads in range(3):
		append_segment()
	#spawn_road(road_segments[2])#PENISPENISPENISPENISCOCKOCKCOCKOCKCOCKOCKCOKCOKC
	
	Debug.cops_node = cops_node
	Debug.sober_node = pedestrians_node
	
	#if exes_house:
		#spawn_road(exes_house)
		
	road_generated.emit()

func load_road_segments_from_folder():
	road_segments = {}
	road_seg_to_load = {}
	var file_array : Array = Globals.get_exported_files("res://Scenes/Roads/Normal Segments")
	
	for file:String in file_array:
		if file.contains(".import"):
			continue
		
		var road_seg = load(file)
		
		if road_seg:
			var nickname : String = file.substr(file.rfind("/")+1)
			nickname = nickname.substr(0,nickname.find("."))
			road_seg_to_load[nickname] = file
			#print(nickname,file)
		else:
			print("Failed to load, not adding : ",file," to road_seg_to_load")
	
	
	while road_segments.size()<MAX_ROAD_SEGMENTS_LOADED && road_segments.size() < road_seg_to_load.size() && road_load_fails<MAX_ROAD_SEGMENTS_LOADED:
		load_random_road_seg()
	first_roads_loaded = true
	
func load_random_road_seg():
	if road_seg_to_load.is_empty():
		#print("road_seg_to_load is empty, attempting to populate")
		load_road_segments_from_folder()
	var chosen_key : String = road_seg_to_load.keys().pick_random()
	var road_seg = load(road_seg_to_load[chosen_key])
	if road_seg:
		road_segments[chosen_key] = road_seg
	elif(road_load_fails<MAX_ROAD_SEGMENTS_LOADED):
		#print("fail to load road segment")
		road_load_fails+=1
		load_random_road_seg()


func load_gabe_segments_from_folder():
	gabesmart_segments = {}
	gabesmart_seg_to_load = {}
	var file_array : Array = Globals.get_exported_files("res://Scenes/Roads/Gabesmart Segments")

	for file:String in file_array:
		if file.contains(".import"):
			continue
		
		var road_seg = load(file)
		
		if road_seg:
			var nickname : String = file.substr(file.rfind("/")+1)
			nickname = nickname.substr(0,nickname.find("."))
			gabesmart_seg_to_load[nickname] = file
		else:
			print("Failed to load, not adding : ",file," to road_seg_to_load")
	
	
	while gabesmart_segments.size()<MAX_GABE_SEGMENTS_LOADED && gabesmart_segments.size() < gabesmart_seg_to_load.size() && gabe_load_fails<MAX_GABE_SEGMENTS_LOADED:
		load_random_gabe_seg()
	first_gabes_loaded = true

func load_random_gabe_seg():
	if gabesmart_seg_to_load.is_empty():
		load_gabe_segments_from_folder()
	var chosen_key : String = gabesmart_seg_to_load.keys().pick_random()
	var road_seg = load(gabesmart_seg_to_load[chosen_key])
	if road_seg:
		gabesmart_segments[chosen_key] = road_seg
	elif(gabe_load_fails<MAX_ROAD_SEGMENTS_LOADED):
		gabe_load_fails+=1
		load_random_gabe_seg()

#spawn road at given location
func spawn_road(segment:PackedScene = null)->Node3D:
	var instanced_segment : Node3D
	var segment_key : String = ""
	if segment:
		instanced_segment = segment.instantiate()
		return instanced_segment

	if gabesmart_pity >= max_gabesmart_pity:
		segment_key = gabesmart_segments.keys().pick_random()
		gabesmart_pity = 0
		instanced_segment = gabesmart_segments[segment_key].instantiate()
	elif randf() <= gabesmart_chance:
		segment_key = gabesmart_segments.keys().pick_random()
		gabesmart_pity = 0
		instanced_segment = gabesmart_segments[segment_key].instantiate()
	else:
		segment_key = road_segments.keys().pick_random()
		gabesmart_pity += 1
		instanced_segment = road_segments[segment_key].instantiate()

	if !road_segments.keys().is_empty() and road_segments.keys().has(segment_key):
		if road_segments.keys().size() == MAX_ROAD_SEGMENTS_LOADED:
			road_segments.erase(segment_key)
			load_random_road_seg()

	if !gabesmart_segments.keys().is_empty() and gabesmart_segments.keys().has(segment_key):
		if gabesmart_seg_to_load.keys().size()>1:
			if gabesmart_segments.keys().size() == MAX_GABE_SEGMENTS_LOADED:
				gabesmart_segments.erase(segment_key)
				load_random_gabe_seg()
	
	instanced_segment.name = str(cur_player_road+road_node.get_child_count())
	return instanced_segment

func append_segment(segment:PackedScene = null):
	var instanced_segment
	if segment:
		instanced_segment = spawn_road(segment)
	else:
		instanced_segment = spawn_road()
	
	instanced_segment.visible = false
	
	road_node.add_child(instanced_segment)
	instanced_segment.global_position = previous_road.find_child("Exit").global_position
	
	# Connect player road counter signal.
	if instanced_segment.has_signal("increment_player_road_counter"):
		instanced_segment.increment_player_road_counter.connect(increment_player_road)
	
	previous_road = instanced_segment
	
	# Append this segment's path to the global path.
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
	instanced_segment.spawn_drivers()

var cur_player_road: int = 0:
	set(value):
		if value > Globals.roads_to_win and Globals.roads_to_win != int(INF):
			pass
		elif value == int(Globals.roads_to_win) and Globals.roads_to_win != int(INF):
			if exes_house:
				append_segment(exes_house)
		else:
			append_segment()

		cur_player_road = value
		
		# Manage the number of active road segments.
		if road_node.get_child_count() > 8:
			var road_to_remove: Node3D = road_node.get_child(0)
			
			# ADDED: Critical logic to remove old points from the global path.
			if "nav_curve" in road_to_remove and road_to_remove.nav_curve is Path3D:
				var path_to_remove: Path3D = road_to_remove.nav_curve
				# -1 because the first point is skipped during append.
				var points_to_remove = path_to_remove.curve.get_point_count() - 1
				points_to_remove = max(0, points_to_remove)
				
				for i in range(points_to_remove):
					if glob_path.curve.get_point_count() > 0:
						glob_path.curve.remove_point(0)
			
			for cop : Node3D in Globals.world_node.find_child("Cops").get_children():
				if cop.global_position.z > road_to_remove.global_position.z:
					cop.call_deferred("queue_free")
			for pedestrian : Node3D in Globals.world_node.find_child("Pedestrians").get_children():
				if pedestrian.global_position.z > road_to_remove.global_position.z:
					pedestrian.call_deferred("queue_free")
			road_to_remove.queue_free()

#change this to give Array [prev, next]
##we move in the -z direction
func get_road_at_pos(glob_pos:Vector3)->RoadSegment:
	var last_road : RoadSegment = road_node.get_children().back()
	var cur_road : RoadSegment
	#loop through all roads
	for index:int in road_node.get_child_count():
		cur_road = road_node.get_child(index)
		if glob_pos.z>cur_road.global_position.z:
			return road_node.get_child(index-1)
	return last_road

func get_next_road(cur:RoadSegment,reverse:bool=false)->RoadSegment:
	var result:RoadSegment
	var road_array:Array = road_node.get_children()
	var result_index = road_array.find(cur)
	if reverse:
		result_index = maxi(0,result_index-1)
	else:
		result_index = mini(road_array.size()-1,result_index+1)
	
	result = road_array.get(result_index)
	#print("result index: ",result_index)
	print(result)
	return result

func increment_player_road():
	cur_player_road+=1
