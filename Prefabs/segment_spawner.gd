extends Node

@export var road_segments : Array[PackedScene] = []
#each packed scene has a marker labeled "Entrance" and "Exit"

#var packed_offsets : Dictionary = {}

func _ready():
	#for segment in road_segments:
		#var instanced_segment : Node3D = segment.instantiate()
		#add_child(instanced_segment)
		#var offset = instanced_segment.find_child("Exit").global_position - instanced_segment.find_child("Entrance").global_position
		#instanced_segment.queue_free()
		#packed_offsets[segment] = offset * Vector3(1,1,1) * $Roads.scale
	#print(packed_offsets)
	spawn_road(road_segments[3])
	for num_roads in range(200):
		spawn_road(road_segments.pick_random())
	

@onready var previous_road : Node3D = $"Roads/Debug Straight"
#var current_offset : Vector3 = Vector3.ZERO


#spawn road at given location
func spawn_road(segment:PackedScene)->Node3D:
	var instanced_segment : Node3D = segment.instantiate()
	#instantiate segment
	#calculate offset
	#add_child
	$Roads.add_child(instanced_segment)
	#move_child
	instanced_segment.global_position = previous_road.find_child("Exit").global_position
	#current_offset - instanced_segment.find_child("Entrance").position
	
	previous_road = instanced_segment
	#set current_road
	#set current_offset
	return instanced_segment
