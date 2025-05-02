extends Camera3D
@export var floor_y: float = 0.0  # Y position of the floor (adjust as needed)

func get_mouse_target_position() -> Vector3:
	# Get mouse position in viewport
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Convert to world space ray
	var ray_origin = self.project_ray_origin(mouse_pos)
	var ray_direction = self.project_ray_normal(mouse_pos)
	
	# Check intersection with floor (assuming flat plane at floor_y)
	var t = (floor_y - ray_origin.y) / ray_direction.y
	if t > 0:  # Ensure the ray is pointing downward
		return ray_origin + ray_direction * t  # Intersection point
	
	return Vector3.ZERO  # Return a default value if no valid hit
