extends Node

@export var road_segments : Array[PackedScene] = []
#each packed scene has a marker labeled "Entrance" and "Exit"

var balls : Dictionary = {}

func _ready():
	for segment in road_segments:
		var instanced_segment : Node3D = segment.instantiate()
		add_child(instanced_segment)
		var offset = instanced_segment.find_child("Entrance").global_position - instanced_segment.find_child("Exit").global_position
		instanced_segment.queue_free()
		balls[segment] = offset * $Roads.scale * Vector3(1,0,1)
	print(balls)
	spawn_road(road_segments[0])
	spawn_road(road_segments[0])
	spawn_road(road_segments[0])

var current_road : PackedScene
var current_offset : Vector3 = Vector3.ZERO


#spawn road at given location
func spawn_road(segment:PackedScene)->Node3D:
	var instanced_segment : Node3D = segment.instantiate()
	#instantiate segment
	#calculate offset
	#add_child
	$Roads.add_child(instanced_segment)
	#move_child
	instanced_segment.global_position = current_offset
	current_road = segment
	current_offset = current_offset+balls[segment]
	#set current_road
	#set current_offset
	return instanced_segment
