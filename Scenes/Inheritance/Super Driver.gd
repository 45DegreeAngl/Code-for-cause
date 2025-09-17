extends BaseDriver
class_name SuperDriver

@onready var WHEEL_BASE = $Back_Left.position.distance_to($Front_Left.position) if $Back_Left else 3.0

func update_context_variables(_delta):
	if target:
		dist_to_target = xz_plane_dist(self.global_position, target.global_position)
	
	if dist_to_target < hunt_dist:
		hunt = true
	else:
		hunt = false
	
	# The AI is "parked" if it's not hunting AND the global path is invalid.
	var path_is_valid = Globals.driving_path != null and Globals.driving_path.curve.get_point_count() > 1
	if !hunt and not path_is_valid:
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
	if reversing:
		engine_input = -1
		steer_input = 1
		return

	if hunt:
		# Hunt logic remains unchanged.
		var target_point_global = target.global_position
		var target_lookahead_vector = (target_point_global - global_position).normalized()
		var target_angle_to_lookahead = (-basis.z).signed_angle_to(target_lookahead_vector, global_basis.y)
		steer_input = target_angle_to_lookahead / (PI / 4)
		
		var vector_to_target = target_point_global - global_position
		var dot_product = (-basis.z).dot(vector_to_target.normalized())
		
		if dot_product > 0.5 and linear_velocity.length() > 40:
			engine_input = -0.5
		else:
			engine_input = 1
	else:
		# --- Path Following Logic ---
		var path_to_follow: Path3D = Globals.driving_path
		
		if path_to_follow == null or path_to_follow.curve.get_point_count() < 2:
			return

		var speed = linear_velocity.length()
		var global_to_curve_space_pos = path_to_follow.to_local(global_position)
		var closest_point_offset = path_to_follow.curve.get_closest_offset(global_to_curve_space_pos)

		# --- Steering Calculation (Stanley Method) ---
		var closest_point = path_to_follow.curve.get_closest_point(global_to_curve_space_pos)
		var path_heading: Vector3

		# CHANGED: Determine path heading based on the 'backwards' variable.
		if backwards:
			# Driving against the path's baked direction (+Z).
			# We look at a point slightly *behind* on the path to find our forward vector.
			var slightly_behind_point = path_to_follow.curve.sample_baked(closest_point_offset - 0.1)
			path_heading = (path_to_follow.to_global(closest_point) - path_to_follow.to_global(slightly_behind_point)).normalized()
		else:
			# Driving with the path's baked direction (-Z).
			var slightly_ahead_point = path_to_follow.curve.sample_baked(closest_point_offset + 0.1)
			path_heading = (path_to_follow.to_global(slightly_ahead_point) - path_to_follow.to_global(closest_point)).normalized()
		
		# The rest of the Stanley controller works perfectly with the correct path_heading.
		var heading_error = (-global_basis.z).signed_angle_to(path_heading, Vector3.UP)
		var path_normal = path_heading.rotated(Vector3.UP, PI / 2)
		var cross_track_error = (path_to_follow.to_global(closest_point) - global_position).dot(path_normal)
		var cross_track_error_gain = 2.0
		var effective_speed = max(speed, 5.0)
		var cross_track_steering = atan2(cross_track_error_gain * cross_track_error, effective_speed)
		var stanley_steer_angle = heading_error + cross_track_steering
		var normalizing_angle = (PI / 4) / steer_responsiveness
		steer_input = clamp(stanley_steer_angle / normalizing_angle, -1.0, 1.0)

		# --- Throttle/Braking Calculation ---
		var lookahead_dist = 5.0 + speed * 0.3
		
		# CHANGED: If driving backwards, the lookahead distance is negative.
		if backwards:
			lookahead_dist *= -1
		
		var lookahead_point = path_to_follow.curve.sample_baked(closest_point_offset + lookahead_dist)
		var lookahead_heading = (path_to_follow.to_global(lookahead_point) - global_position).normalized()
		var curvature_factor = clamp(abs((-global_basis.z).dot(lookahead_heading)), 0.0, 1.0)
		var target_speed = lerp(min_speed_on_curve, max_speed, curvature_factor)
		var speed_error = target_speed - speed
		var throttle_gain = 0.1
		engine_input = clamp(speed_error * throttle_gain, -1.0, 1.0)
