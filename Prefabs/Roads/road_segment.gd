extends GridMap
class_name RoadSegment

var index : int

@export var debris_node : Node3D
@export var max_debris : int = 10


func _ready():
	spawn_debris()

func spawn_debris():
	for child in debris_node.get_children():
		child.spawn_debris()
