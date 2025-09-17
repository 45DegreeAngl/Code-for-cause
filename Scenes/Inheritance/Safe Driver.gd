extends BaseDriver
class_name SafeDriver
# How far ahead on the path the driver will set its next target.
@export var lookahead_distance: float = 50.0
@export var navigation_agent: NavigationAgent3D

# This will be updated by the Area3D triggers on each road segment.
var current_road: RoadSegment = null
var navigation_endpoint: Vector3

# This function is called by the road segment's Area3D trigger.
func set_current_road(road: RoadSegment):
	if road == current_road:
		return # Already on this road.

	current_road = road
	if current_road and current_road.nav_region:
		# Critical step: Update the navigation agent with the new road's nav map.
		navigation_agent.set_navigation_map(current_road.nav_region.get_navigation_map())
	else:
		printerr("SafeDriver entered a road with no nav_region!")

func update_context_variables(_delta):
	if target:
		var distance_to_target = self.global_position.distance_to(target.global_position)
		hunt = distance_to_target < hunt_dist
	
	# The AI is "parked" if it's not hunting and the global path is invalid.
	var path_is_valid = Globals.driving_path != null and Globals.driving_path.curve.get_point_count() > 1
	parked = !hunt and not path_is_valid

func update_steer(delta):
	nav_control(delta)
	steering = move_toward(steering, steer_input * get_max_steer(), delta * 2.5)
	
	if parked:
		engine_input = move_toward(engine_input, 0, delta * 2.5)
		
	engine_force = max(engine_input * ENGINE_POWER, -ENGINE_POWER / 1.5)

func nav_control(_delta: float) -> void:
	if reversing or parked:
		engine_input = -1 if reversing else 0
		steer_input = 0
		return
	
	var path_to_follow: Path3D = Globals.driving_path
	if not path_to_follow:
		return

	# --- Determine the Target Endpoint ---
	if hunt:
		# When hunting, the target is the player.
		navigation_endpoint = target.global_position
	else:
		# When driving normally, find a point ahead on the global path.
		var closest_offset = path_to_follow.curve.get_closest_offset(self.global_position)
		var target_offset = closest_offset + (lookahead_distance if not backwards else -lookahead_distance)
		
		# Get the position of that point in world space.
		navigation_endpoint = path_to_follow.curve.sample_baked(target_offset, true)

	# --- Navigate to the Endpoint ---
	navigation_agent.set_target_position(navigation_endpoint)

	var next_nav_point = navigation_agent.get_next_path_position()
	var direction_vector = (next_nav_point - global_position).normalized()

	# Compute steering input
	var angle_to_target = (-basis.z).signed_angle_to(direction_vector, Vector3.UP)
	steer_input = clamp(angle_to_target * 2.0, -1.0, 1.0) # A simple gain often works well here

	# Compute engine input based on angle and distance. Slow down for sharp turns.
	var turn_severity = abs(angle_to_target) / (PI / 4) # Normalize by 45 degrees
	var target_speed = lerp(max_speed, 20.0, turn_severity)
	var speed_error = target_speed - linear_velocity.length()
	engine_input = clamp(speed_error * 0.1, -1.0, 1.0)
