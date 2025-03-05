extends Node

@export var road_segments : Array[PackedScene] = []
signal road_generated

func _ready():

	spawn_road(road_segments[7])
	for num_roads in range(100):

		spawn_road(road_segments.pick_random())
	road_generated.emit()
@onready var previous_road : Node3D = $"Roads/Debug Straight"

#spawn road at given location
func spawn_road(segment:PackedScene)->Node3D:
	var instanced_segment : Node3D = segment.instantiate()
	#instantiate segment
	#add_child
	$Roads.add_child(instanced_segment)
	#move_child
	instanced_segment.global_position = previous_road.find_child("Exit").global_position
	
	previous_road = instanced_segment
	#set previous_road
	return instanced_segment
