extends Node3D
@export var randomize: bool = true



func _ready() -> void:
	if randomize:
		scale *= randf_range(0.9,1.3)
