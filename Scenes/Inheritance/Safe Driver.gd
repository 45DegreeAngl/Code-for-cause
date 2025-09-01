extends BaseDriver
class_name SafeDriver
@export var point_accept_distance : float = 15
@onready var cur_road : RoadSegment = null
func get_cur_road():
	return cur_road

@export var navigation_region : NavigationRegion3D
func set_nav_region(nav: NavigationRegion3D):
	if nav == navigation_region:
		#printerr("Attempting to set current nav region to current nav region")
		return false
	navigation_region = nav
	navigation_agent.set_navigation_map(nav.get_navigation_map())
	return true

@export var navigation_path : Path3D
func set_nav_path(path_node: Path3D):
	if path_node == navigation_path:
		#printerr("Attempting to set current path node to current nav path")
		return false
	navigation_path = path_node
	
	# Reset navigation index when a new path is given
	cur_nav_index = get_closest_nav_point() 
	if navigation_path:
		navigation_endpoint = navigation_path.global_transform * navigation_path.curve.get_point_position(cur_nav_index)
	return true

@export var navigation_agent : NavigationAgent3D

var navigation_endpoint : Vector3
var cur_nav_index: int = 0

signal request_new_nav_region(vehicle: BaseDriver,road_completed:bool)

func _ready()->void:
	#if !request_new_nav_region.is_connected(Globals.world_node.give_new_nav_region):
		#request_new_nav_region.connect(Globals.world_node.give_new_nav_region)
	request_new_nav_region.emit(self)

func update_context_variables(_delta):
	# Check if the target is within hunting distance
	if target:
		var distance_to_target = self.global_position.distance_to(target.global_position)
		if distance_to_target < hunt_dist:
			hunt = true
		else:
			hunt = false
			cur_nav_index = get_closest_nav_point()
		
		if target.global_position.z - 300 > self.global_position.z:
			if !hunt and !backwards:
				parked = true
		else:
			parked = false
			cur_nav_index = get_closest_nav_point()

func update_steer(delta):
	nav_control(delta)
	steering = move_toward(steering, steer_input * get_max_steer(), delta * 2.5)
	if parked:
		engine_input = move_toward(engine_input,0,delta*2.5)
	engine_force = max(engine_input * ENGINE_POWER, -ENGINE_POWER / 1.5)

func get_closest_nav_point() -> int:
	if !navigation_path or navigation_path.curve.point_count == 0:
		return 0  # Default to the first point

	var result: int
	if backwards:
		result = navigation_path.curve.point_count-1
	else:
		result = 0
	var closest_distance = INF

	for point in range(navigation_path.curve.point_count):
		var world_point = navigation_path.global_transform * navigation_path.curve.get_point_position(point)
		var distance = global_position.distance_to(world_point)

		if distance < closest_distance:
			closest_distance = distance
			result = point

	return result

func nav_control(_delta: float) -> void:
	if !navigation_path or navigation_path.curve.point_count == 0:
		return  # No valid path
	
	if reversing:
		engine_input=-1
		steer_input=0
		return
	# Follow path normally
	if global_position.distance_to(navigation_endpoint) <= point_accept_distance:
		if backwards:
			cur_nav_index -= 1
		else:
			cur_nav_index += 1

		# If at the last point, request a new navigation region
		if cur_nav_index >= navigation_path.curve.point_count or cur_nav_index <0:
			await get_tree().create_timer(0.25).timeout  # Delay to prevent instant switching
			request_new_nav_region.emit(self,true)
			return

		# Update the next target position along the path
		navigation_endpoint = navigation_path.global_transform * navigation_path.curve.get_point_position(cur_nav_index)
	# If hunting, override normal navigation and chase target
	if hunt:
		navigation_endpoint = target.global_position
	# Set navigation agent target position
	navigation_agent.set_target_position(navigation_endpoint)

	# Get next path position
	var next_position = navigation_agent.get_next_path_position()
	var direction_vector = (next_position - global_position).normalized()

	# Compute steering input
	var angle_to_target = (-basis.z).signed_angle_to(direction_vector, Vector3.UP)
	steer_input = clampf(angle_to_target / deg_to_rad(MAX_STEER_DEG), -1, 1)

	# Compute engine input based on distance
	engine_input = 1.0 if global_position.distance_to(next_position) > 1.0 else 0.0
