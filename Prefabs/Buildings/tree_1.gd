extends Node3D



func _ready() -> void:
	scale *= randf_range(0.9,1.3)
	rotation_degrees.y += randf_range(0,360)
