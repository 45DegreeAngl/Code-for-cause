extends Node3D
@export var road_scale_factor : float = 20

func _ready():
	for child in get_children():
		if child is Debris:
			child.rescale_children(road_scale_factor)
