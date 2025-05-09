extends Node

const MAX_ROAD_SEGMENTS_LOADED: int = 7
const MAX_GABE_SEGMENTS_LOADED: int = 3
var road_load_fails : int = 0
var gabe_load_fails : int = 0

#road segments to load
var road_seg_to_load : Dictionary = {}
var gabesmart_seg_to_load : Dictionary = {}

#nickname : road
var road_segments : Dictionary = {}
var gabesmart_segments : Dictionary = {}
@export var exes_house : PackedScene = null

@export_subgroup("RNG Settings")
@export var max_gabesmart_pity : int = 5
@export_range(0,1,0.01) var gabesmart_chance : float

var gabesmart_pity = 0
var first_roads_loaded : bool = false
var first_gabes_loaded : bool = false

signal road_generated

func _ready():
	Globals.world_node = self
	if not gabesmart_chance:
		@warning_ignore("integer_division")
		gabesmart_chance = 1/(2*max_gabesmart_pity)
	load_road_segments_from_folder()
	load_gabe_segments_from_folder()
	
	for num_roads in range(3):
		append_segment()
	#spawn_road(road_segments[2])#PENISPENISPENISPENISCOCKOCKCOCKOCKCOCKOCKCOKCOKC
	
	Debug.cops_node = $Cops
	Debug.sober_node = $Pedestrians
	
	#if exes_house:
		#spawn_road(exes_house)
		
	road_generated.emit()

@onready var previous_road : Node3D = $"Roads/Cul de Sac Tutorial"

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
	
	instanced_segment.name = str(cur_player_road+$Roads.get_child_count())
	return instanced_segment

func append_segment(segment:PackedScene = null):
	var instanced_segment
	if segment:
		instanced_segment = spawn_road(segment)
	else:
		instanced_segment = spawn_road()
	
	instanced_segment.visible = false
	
	$Roads.add_child(instanced_segment)
	instanced_segment.global_position = previous_road.find_child("Exit").global_position
	if instanced_segment.has_signal("increment_player_road_counter"):
		instanced_segment.increment_player_road_counter.connect(increment_player_road)
	if instanced_segment.has_signal("driver_spawned"):
		instanced_segment.driver_spawned.connect(give_new_nav_region)
	previous_road = instanced_segment
	instanced_segment.visible = true
	instanced_segment.spawn_drivers()

var cur_player_road:int = 0:
	set(value):
		print(value)
		if value > Globals.roads_to_win and Globals.roads_to_win!=int(INF):
			print("no road for you")
			pass
		elif value == int(Globals.roads_to_win) and Globals.roads_to_win!=int(INF):
			if exes_house:
				append_segment(exes_house)
		else:
			print("spawning new road")
			append_segment()

		cur_player_road=value
		if $Roads.get_child_count()>8:
			var temp_array:Array[Node3D] = [$Roads.get_child(0)]
			
			for temp:Node3D in temp_array:
				for cop : Node3D in Globals.world_node.find_child("Cops").get_children():
					if cop.global_position.z > temp.global_position.z:
						print("Deleting this cop: ",cop)
						cop.call_deferred("queue_free")
				for pedestrian : Node3D in Globals.world_node.find_child("Pedestrians").get_children():
					if pedestrian.global_position.z > temp.global_position.z:
						print("Deleting this pedestrian: ",pedestrian)
						pedestrian.call_deferred("queue_free")
				temp.queue_free()

var debug_dic : Dictionary = {}

##driver management
func give_new_nav_region(vehicle:VehicleBody3D,road_completed:bool = false):
	var cur_entry = debug_dic.get_or_add(vehicle.name,0)
	debug_dic[vehicle.name] = cur_entry+1
	print("I ",vehicle.name," called this function #:",debug_dic[vehicle.name])
	var vehicle_road : RoadSegment 
	
	if vehicle.has_method("get_cur_road"):
		var cur_road = vehicle.get_cur_road()
		if cur_road and road_completed:
			vehicle_road = get_next_road(cur_road,vehicle.backwards)
			#print(vehicle_road)
		else:
			vehicle_road = get_road_at_pos(vehicle.global_position)

		vehicle.cur_road = vehicle_road
	else:
		vehicle_road = get_road_at_pos(vehicle.global_position)
	#= get_road_at_pos(vehicle.global_position)
	#print(vehicle_road.name)
	if !vehicle_road:
		printerr("ERROR: vehicle_road is null!")
		return
	#now i should have a vehicle road that IS proper, now we just need to assign the proper
	if !vehicle_road.nav_region:
		print("Missing Nav_Region for road")
	if !vehicle_road.nav_curve:
		print("Missing Nav_Curve for road")
	#variables to the vehicle that was given
	if vehicle.has_method("set_nav_region"):
		var result:bool = vehicle.set_nav_region(vehicle_road.nav_region)
		if result:
			print("Nav Region Set for Vehicle: ",vehicle,"\nSet to: ",vehicle_road.nav_region)
	if vehicle.has_method("set_nav_path"):
		var result = vehicle.set_nav_path(vehicle_road.nav_curve)
		if result:
			print("Nav Path Set for Vehicle: ",vehicle,"\nSet to: ",vehicle_road.nav_curve)
	#if vehicle.has_method("adjust_cur_nav_index"):
		#vehicle.adjust_cur_nav_index()
		#print("Adjusting Nav Index for Vehicle: ",vehicle)
	if vehicle.has_signal("request_new_nav_region"):
		if !vehicle.is_connected("request_new_nav_region",give_new_nav_region):
			vehicle.request_new_nav_region.connect(give_new_nav_region)
		
#change this to give Array [prev, next]
##we move in the -z direction
func get_road_at_pos(glob_pos:Vector3)->RoadSegment:
	#if glob_pos.z>first_road.global_position.z:
		#return first_road
	#if glob_pos is less than the position of the last road, return last road
	var last_road : RoadSegment = $Roads.get_children().back()
	#if glob_pos.z>last_road.global_position.z:
		#return last_road
	#var segment_arrays : Array[RoadSegment] = [$Roads.get_children()[0],$Roads.get_children()[1]]
	var cur_road : RoadSegment
	#loop through all roads
	for index:int in $Roads.get_child_count():
		cur_road = $Roads.get_child(index)
		if glob_pos.z>cur_road.global_position.z:
			return $Roads.get_child(index-1)
	return last_road

func get_next_road(cur:RoadSegment,reverse:bool=false)->RoadSegment:
	var result:RoadSegment
	var road_array:Array = $Roads.get_children()
	var result_index = road_array.find(cur)
	if reverse:
		result_index = maxi(0,result_index-1)
	else:
		result_index = mini(road_array.size()-1,result_index+1)
	
	result = road_array.get(result_index)
	print("result index: ",result_index)
	print(result)
	return result

func increment_player_road():
	cur_player_road+=1
