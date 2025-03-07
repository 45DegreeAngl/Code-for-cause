extends Node3D
class_name DebrisGroup

@export var road_scale_factor : float = 20

func _ready():
	for child in get_children():
		if child is Debris:
			child.rescale_children(road_scale_factor)
