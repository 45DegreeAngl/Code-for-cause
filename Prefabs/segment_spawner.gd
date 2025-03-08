extends Node
@export_subgroup("Segment Arrays")
@export var road_segments : Array[PackedScene] = []
@export var gabesmart_segments : Array[PackedScene] = []
@export var exes_house : PackedScene = null

@export_subgroup("RNG Settings")
@export var max_gabesmart_pity : int = 5
@export_range(0,1,0.01) var gabesmart_chance : float

var gabesmart_pity = 0

signal road_generated

func _ready():
	Globals.world_node = self
	if not gabesmart_chance:
		@warning_ignore("integer_division")
		gabesmart_chance = 1/(2*max_gabesmart_pity)

	spawn_road(road_segments[2])#PENISPENISPENISPENISCOCKOCKCOCKOCKCOCKOCKCOKCOKC
	for num_roads in range(2):
		spawn_road()
	#if exes_house:
		#spawn_road(exes_house)
		
	road_generated.emit()
@onready var previous_road : Node3D = $"Roads/Cul de Sac Tutorial"

#spawn road at given location
func spawn_road(segment:PackedScene = null)->Node3D:
	var instanced_segment : Node3D
	if not segment:
		if gabesmart_pity >= max_gabesmart_pity:
			instanced_segment = gabesmart_segments.pick_random().instantiate()
			gabesmart_pity = 0
		elif randf() <= gabesmart_chance:
			instanced_segment = gabesmart_segments.pick_random().instantiate()
			gabesmart_pity = 0
		else:
			instanced_segment = road_segments.pick_random().instantiate()
			gabesmart_pity += 1
		
		$Roads.add_child(instanced_segment)
		instanced_segment.global_position = previous_road.find_child("Exit").global_position
		previous_road = instanced_segment
		if instanced_segment.has_signal("increment_player_road_counter"):
			instanced_segment.increment_player_road_counter.connect(increment_player_road)
			
		return instanced_segment
	
	instanced_segment = segment.instantiate()
	$Roads.add_child(instanced_segment)
	instanced_segment.global_position = previous_road.find_child("Exit").global_position
	if instanced_segment.has_signal("increment_player_road_counter"):
		instanced_segment.increment_player_road_counter.connect(increment_player_road)
	previous_road = instanced_segment
	return instanced_segment

var cur_player_road:int = 0:
	set(value):
		print(value)
		if value > 50:
			pass
		elif value == 50:
			if exes_house:
				spawn_road(exes_house)
		else:
			print("spawning new road")
			spawn_road()

		cur_player_road=value
		if $Roads.get_child_count()>8:
			var temp_array:Array[Node3D] = [$Roads.get_child(0)]
			for temp:Node3D in temp_array:
				
				temp.queue_free()

func increment_player_road():
	cur_player_road+=1
