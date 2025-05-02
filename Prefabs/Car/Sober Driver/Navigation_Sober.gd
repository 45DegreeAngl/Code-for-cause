extends VehicleBody3D

@export var DEBUG_PATH_FIND_CAM : Camera3D
@export var DEBUG_MODE : bool = false
@export var backwards : bool = false
@export var target: VehicleBody3D
@export var hunt_distance : float = 15
@export var point_accept_distance : float = 15

@export var STEERING_CURVE : Curve
@export var MAX_STEER_DEG : float = 45.0
@export var ENGINE_POWER : float = 200
@export var SOUND_MAX_SPEED : float = 75
@onready var WHEEL_BASE = $Back_Left.position.distance_to($Front_Left.position)

var steer_input : float :
	set(val):
		steer_input = clampf(val, -1, 1)
var engine_input : float :
	set(val):
		engine_input = clampf(val, -1, 1)

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

signal request_new_nav_region(vehicle: VehicleBody3D)

var hunt : bool = false
var reversing := false
var parked : bool = false

func _ready() -> void:
	#$StuckTimer.connect("timeout", on_stuck_timer_ended)
	#$ReverseTimer.connect("timeout", on_reverse_timer_ended)
	randomize_chasis_color()
	for driver in human_drivers:
		randomize_driver_color(driver)
	request_new_nav_region.emit(self)

var saved_linear_velocity : Vector3 = Vector3.ZERO

func _on_collide(_body):
	if abs(linear_velocity.length() - saved_linear_velocity.length()) > 1 and !$Sounds/Crash.playing:
		$Sounds/Crash.stream = Globals.crash_sounds[Globals.crash_sounds.keys().pick_random()]
		$Sounds/Crash.play()

func _process(delta: float) -> void:
	# Check if the target is within hunting distance
	if target:
		if target.global_position.distance_to(self.global_position) < hunt_distance:
			hunt = true  # Enable hunting mode
			
		else:
			hunt = false  # Follow navigation path
			cur_nav_index = get_closest_nav_point()
			
		if target.global_position.z - 300 > self.global_position.z:
			if !hunt:
				parked = true
		else:
			parked = false
			cur_nav_index = get_closest_nav_point()
	
	if parked:
		return

	navigation_control(delta)  # Follow path navigation logic
	change_engine_pitch()
	check_stuck()

	steering = move_toward(steering, steer_input * get_max_steer(), delta * 2.5)
	engine_force = max(engine_input * ENGINE_POWER, -ENGINE_POWER / 1.5)

func navigation_control(_delta: float) -> void:
	
	if !navigation_path or navigation_path.curve.point_count == 0:
		return  # No valid path
	
	if reversing:
		engine_input=-1
		steer_input=0
		return
	elif hunt:
		var target_point_global = target.global_position
		var target_lookahead_vector = (target_point_global - global_position).normalized()
		var target_angle_to_lookahead = (-basis.z).signed_angle_to(target_lookahead_vector, global_basis.y)
		steer_input = target_angle_to_lookahead/(PI/4)
		
		var vector_to_target = target_point_global-global_position
		var dot_product = (-basis.z).dot(vector_to_target.normalized())
		
		if dot_product>0 and linear_velocity.length() > 40:
			engine_input = -1
		else:
			engine_input = 1
		return
	
	# Check if we're near the current navigation point
	if global_position.distance_to(navigation_endpoint) <= point_accept_distance:
		cur_nav_index += 1

		# If at the last point, request a new navigation region
		if cur_nav_index >= navigation_path.curve.point_count:
			await get_tree().create_timer(0.3).timeout  # Wait before switching
			request_new_nav_region.emit(self)
			return

		# Update the next target position along the path
		navigation_endpoint = navigation_path.global_transform * navigation_path.curve.get_point_position(cur_nav_index)

	if hunt:
		navigation_endpoint = target.global_position

	# Set navigation agent target position
	navigation_agent.set_target_position(navigation_endpoint)

	# Get next path position
	var next_position = navigation_agent.get_next_path_position()
	# Compute the angle to the target navigation point
	var direction_vector = (next_position - global_position).normalized()
	var angle_to_target = (-basis.z).signed_angle_to(direction_vector, Vector3.UP)

	var adjusted_angle = angle_to_target if angle_to_target >= 0 else TAU + angle_to_target
	var distance_to_next = global_position.distance_to(next_position)

	# Apply movement logic based on reversing state
	if distance_to_next > 1.0:
		engine_input = -1.0 if reversing else 1.0
	else:
		engine_input = 0.0

	steer_input = clampf(angle_to_target / deg_to_rad(MAX_STEER_DEG), -1, 1)




func get_closest_nav_point() -> int:
	if !navigation_path or navigation_path.curve.point_count == 0:
		return 0  # Default to the first point

	var result: int = 0
	var closest_distance = INF

	for point in range(navigation_path.curve.point_count):
		var world_point = navigation_path.global_transform * navigation_path.curve.get_point_position(point)
		var distance = global_position.distance_to(world_point)

		if distance < closest_distance:
			closest_distance = distance
			result = point

	return result
func change_engine_pitch():
	if (not $Engine.playing) and $Engine.pitch_scale > 0.01:
		$Engine.play()
	var pitch = min(1, linear_velocity.length() / SOUND_MAX_SPEED)
	if pitch <= 0.01:
		$Engine.stop()
	if pitch > 0.0:
		$Engine.pitch_scale = pitch

func get_max_steer():
	if linear_velocity.length() >= 60:
		return deg_to_rad(MAX_STEER_DEG) * 0.1
	return deg_to_rad(MAX_STEER_DEG) * STEERING_CURVE.sample(linear_velocity.length() / 60)

const colors : Array[Color] = [Color.RED, Color.BLUE]
func _on_flicker_timer_timeout() -> void:
	match $Light/RED.light_color:
		Color.RED:
			$Light/RED.light_color = colors[1]
		Color.BLUE:
			$Light/RED.light_color = colors[0]

func check_stuck():
	if linear_velocity.length() < 1:
		if $StuckTimer.is_stopped():
			$StuckTimer.start()
	else:
		$StuckTimer.stop()

func on_stuck_timer_ended():
	reversing = true
	$ReverseTimer.start()

func on_reverse_timer_ended():
	cur_nav_index = get_closest_nav_point()
	reversing = false

func randomize_chasis_color():
	if Globals.car_colors.size() == 0:
		return
	var chosen_color = Globals.car_colors[Globals.car_colors.keys().pick_random()]
	var chasis_mesh:Mesh = $Mesh/Chassis.mesh.duplicate()
	var chasis_material:StandardMaterial3D = chasis_mesh.surface_get_material(0).duplicate()
	chasis_material.albedo_color = chosen_color
	chasis_mesh.surface_set_material(0, chasis_material)
	$Mesh/Chassis.mesh = chasis_mesh

@export var human_drivers: Array[MeshInstance3D]

func randomize_driver_color(mesh:MeshInstance3D):
	if Globals.car_colors.size() == 0:
		return
	var chosen_color = Globals.car_colors[Globals.car_colors.keys().pick_random()]
	var human_mesh:Mesh = mesh.mesh.duplicate()
	var human_material:StandardMaterial3D = human_mesh.surface_get_material(0).duplicate()
	human_material.albedo_color = chosen_color
	human_mesh.surface_set_material(0, human_material)
	mesh.mesh = human_mesh
