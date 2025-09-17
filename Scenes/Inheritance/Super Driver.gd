extends BaseDriver
class_name SuperDriver

var current_path : Path3D = null

@onready var WHEEL_BASE = $Back_Left.position.distance_to($Front_Left.position) if $Back_Left else 3.0


func update_context_variables(_delta):
	if dist_to_target < hunt_dist:
		hunt = true
	else:
		hunt = false
	
	# CHANGED: Replaced the arbitrary Z-coordinate check for parking.
	# Now, "parked" is true if the AI is not hunting and has no path to follow.
	if !hunt and current_path == null:
		parked = true
	else:
		parked = false


func update_steer(_delta):
	control(_delta)
	
	if parked:
		engine_input = move_toward(engine_input, 0, _delta * 2.5)
	
	steering = move_toward(steering, steer_input * get_max_steer(), _delta * 2.5)
	engine_force = max(engine_input * ENGINE_POWER, -ENGINE_POWER / 1.5)


func control(_delta) -> void:
	# --- Reversing Logic ---
	if reversing:
		engine_input = -1
		# NOTE: Consider adding some steering input during reverse to help get unstuck.
		steer_input = 1 
		return

	# --- Hunt Logic (Target is close) ---
	if hunt:
		current_path = null
		var target_point_global = target.global_position # Assuming Globals.player_vehicle is the target
		var target_lookahead_vector = (target_point_global - global_position).normalized()
		var target_angle_to_lookahead = (-basis.z).signed_angle_to(target_lookahead_vector, global_basis.y)
		steer_input = target_angle_to_lookahead / (PI / 4) # Normalize by 45 degrees
		
		var vector_to_target = target_point_global - global_position
		var dot_product = (-basis.z).dot(vector_to_target.normalized())
		
		# Brake if facing the target and moving too fast to prevent overshooting
		if dot_product > 0.5 and linear_velocity.length() > 40:
			engine_input = -0.5 # Gentle braking is better than full reverse
		else:
			engine_input = 1
		return

	# --- Path Following Logic (Target is far) ---
	if current_path == null:
		current_path = find_nearest_path()
		# If no path is found at all, do nothing. The "parked" state will take over.
		if !current_path:
			engine_input = 0
			steer_input = 0
			return
	
	# --- Path Following Calculations ---
	var speed = linear_velocity.length()
	var global_to_curve_space_pos = current_path.to_local(global_position)
	var closest_point_offset = current_path.curve.get_closest_offset(global_to_curve_space_pos)

	# --- Steering Calculation (Using Stanley Method) ---
	# 1. Calculate heading error
	var closest_point = current_path.curve.get_closest_point(global_to_curve_space_pos)
	var slightly_ahead_point = current_path.curve.sample_baked(closest_point_offset + 0.1)
	var path_heading = (current_path.to_global(slightly_ahead_point) - current_path.to_global(closest_point)).normalized()
	var heading_error = (-global_basis.z).signed_angle_to(path_heading, Vector3.UP)
	
	# 2. Calculate cross-track error
	var path_normal = path_heading.rotated(Vector3.UP, PI / 2)
	var cross_track_error = (current_path.to_global(closest_point) - global_position).dot(path_normal)
	
	# 3. Combine into Stanley steering command
	var cross_track_error_gain = 2.0
	# Use a small value for speed if the car is stopped to avoid division by zero
	var effective_speed = max(speed, 0.1) 
	var cross_track_steering = atan2(cross_track_error_gain * cross_track_error, effective_speed)
	
	# CHANGED: This now correctly uses the Stanley controller output for steering.
	var stanley_steer_angle = heading_error + cross_track_steering
	steer_input = stanley_steer_angle * 2.0 # Multiply by a gain to make it more responsive

	# --- Throttle/Braking Calculation based on path curvature ---
	var throttle_lookahead_dist = 3.0 + speed * 0.25 # Look further ahead at higher speeds
	
	var sample_pts = []
	for i in range(3):
		var dist = throttle_lookahead_dist / 3.0 * (i + 1)
		var point_on_curve = current_path.curve.sample_baked(closest_point_offset + dist)
		sample_pts.append(current_path.to_global(point_on_curve))
	
	var a = xz_plane_dist(sample_pts[0], sample_pts[1])
	var b = xz_plane_dist(sample_pts[1], sample_pts[2])
	var c = xz_plane_dist(sample_pts[2], sample_pts[0])
	var area = abs(xz_triangle_area(sample_pts[0], sample_pts[1], sample_pts[2]))
	
	# Menger curvature calculation. Avoid division by zero.
	var curvature = 0.0
	if a * b * c > 0.001:
		curvature = (4 * area) / (a * b * c)

	# CHANGED: Simplified braking logic. If curvature is high and we are moving fast, brake.
	var curvature_threshold = 0.05 # This value needs tuning
	if curvature > curvature_threshold and speed > 20:
		engine_input = -1 # Brake hard for the corner
	else:
		engine_input = 1 # Full throttle otherwise
	
	# --- Path Completion ---
	# NOTE: This logic should be improved to transition to a 'next_path' if one exists.
	if closest_point_offset / current_path.curve.get_baked_length() > 0.98:
		# Example of how you might handle a path transition:
		# if current_path.has_method("get_next_path") and current_path.get_next_path() != null:
		#     current_path = current_path.get_next_path()
		# else:
		current_path = null # Fallback to finding nearest if no next path is defined


func find_nearest_path() -> Path3D:
	var paths : Array[Node] = get_tree().get_nodes_in_group("road_path")
	var closest_path = null
	var min_dist = INF
	for path in paths:
		# NOTE: A better check might be distance to the *start* of the path curve.
		var dist = global_position.distance_to(path.global_position)
		if dist < min_dist:
			min_dist = dist
			closest_path = path
	return closest_path
