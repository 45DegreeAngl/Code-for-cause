extends GridMap
class_name RoadSegment

var index : int

@export var debris_locations : Array[DebrisLocation]

func _ready():
	pass

func spawn_debris(location : DebrisLocation) -> Node3D:
	return null
