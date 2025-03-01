extends Node3D

@export_enum("X","Y","Z","XY","XZ","YZ","XYZ")var axis = "X"

var time_in_seconds : float = 0

func _process(delta: float) -> void:
	time_in_seconds += delta
	match axis:
		"X":
			rotation.x = deg_to_rad(time_in_seconds)
		"Y":
			rotation.y = deg_to_rad(time_in_seconds)
		"Z":
			rotation.z = deg_to_rad(time_in_seconds)
		"XY":
			rotation.x = deg_to_rad(time_in_seconds)
			rotation.y = deg_to_rad(time_in_seconds)
		"XZ":
			rotation.x = deg_to_rad(time_in_seconds)
			rotation.z = deg_to_rad(time_in_seconds)
		"YZ":
			rotation.y = deg_to_rad(time_in_seconds)
			rotation.z = deg_to_rad(time_in_seconds)
		"XYZ":
			rotation.x = deg_to_rad(time_in_seconds)
			rotation.y = deg_to_rad(time_in_seconds)
			rotation.z = deg_to_rad(time_in_seconds)
	time_in_seconds = roundi(time_in_seconds)%360
