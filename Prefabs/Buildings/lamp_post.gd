extends Node3D
class_name LampPost

@export var rescale : bool = true
@export var scalar : float = 20.0

func _ready():
	if rescale:
		scale *= scalar
		$OmniLight3D.omni_range *= scalar
