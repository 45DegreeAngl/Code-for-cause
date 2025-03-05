extends Node
@export_subgroup("Segment Arrays")
@export var road_segments : Array[PackedScene] = []
@export var gabesmart_segments : Array[PackedScene] = []

@export_subgroup("RNG Settings")
@export var max_gabesmart_pity : int = 5
@export_range(0,1,0.01) var gabesmart_chance : float

var gabesmart_pity = 0

signal road_generated

func _ready():
	if not gabesmart_chance:
		gabesmart_chance = 1/(2*max_gabesmart_pity)
	spawn_road(road_segments[7])
	for num_roads in range(100):
		spawn_road()
		
	road_generated.emit()
@onready var previous_road : Node3D = $"Roads/Debug Straight"

#spawn road at given location
func spawn_road(segment:PackedScene = null)->Node3D:
	if not segment:
		var instanced_segment : Node3D
		
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
		return instanced_segment
		
	var instanced_segment : Node3D = segment.instantiate()
	$Roads.add_child(instanced_segment)
	instanced_segment.global_position = previous_road.find_child("Exit").global_position
	previous_road = instanced_segment
	return instanced_segment
