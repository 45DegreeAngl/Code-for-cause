extends Node3D
class_name LampPost

@export var rescale : bool = true
@export var scalar : float = 20.0
@export var lights : Array[Light3D] = []

func _ready():
	if rescale:
		for light in lights:
			light.omni_range *= scalar
