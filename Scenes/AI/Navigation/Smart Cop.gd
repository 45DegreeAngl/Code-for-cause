extends VehicleBody3D

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

signal request_new_nav_region(vehicle: VehicleBody3D)

var hunt : bool = false
var reversing := false
var parked : bool = false
var saved_linear_velocity : Vector3 = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#$StuckTimer.connect("timeout", on_stuck_timer_ended)
	#$ReverseTimer.connect("timeout", on_reverse_timer_ended)
	for driver in human_drivers:
		randomize_driver_color(driver)
	request_new_nav_region.emit(self)

func _on_collide(_body):
	if abs(linear_velocity.length() - saved_linear_velocity.length()) > 1 and !$Sounds/Crash.playing:
		$Sounds/Crash.stream = Globals.crash_sounds[Globals.crash_sounds.keys().pick_random()]
		$Sounds/Crash.play()

func _process(delta: float) -> void:
	# Check if the target is within hunting distance
	if target:
		var distance_to_target = self.global_position.distance_to(target.global_position)
		if distance_to_target < hunt_distance:
			if $Timer.is_stopped():
				$Timer.start()
				$Siren.playing = true  # Activate siren
			Globals.detected = true
			hunt = true
		else:
			if !$Timer.is_stopped():
				$Timer.stop()
				$Siren.playing = false  # Stop siren
			hunt = false
			cur_nav_index = get_closest_nav_point()
		
		if target.global_position.z - 300 > self.global_position.z:
			if !hunt and !backwards:
				parked = true
		else:
			parked = false
			cur_nav_index = get_closest_nav_point()
	
	if parked:
		return
	
	nav_control(delta)  # Follow path or chase target
	change_engine_pitch()
	check_stuck()

	steering = move_toward(steering, steer_input * get_max_steer(), delta * 2.5)
	engine_force = max(engine_input * ENGINE_POWER, -ENGINE_POWER / 1.5)

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
			request_new_nav_region.emit(self)
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

func change_engine_pitch():
	if (not $Engine.playing) and $Engine.pitch_scale > 0.01:
		$Engine.play()
	var pitch = min(1, linear_velocity.length() / SOUND_MAX_SPEED)
	if pitch <= 0.01:
		$Engine.stop()
	if pitch > 0.0:
		$Engine.pitch_scale = pitch
var red_light: bool = false  # Controls police light toggle
func toggle_colors():
	var red_mat : StandardMaterial3D = $Mesh/Chassis.get_active_material(4)
	var blue_mat : StandardMaterial3D = $Mesh/Chassis.get_active_material(6)
	
	red_mat.emission_enabled = red_light
	blue_mat.emission_enabled = !red_light
	red_mat.emission = Color.RED if red_light else Color.BLACK
	blue_mat.emission = Color.BLUE if !red_light else Color.BLACK
	
	red_light = !red_light

func talk():
	if randi_range(0, 5) != 0:
		return
	if int(Globals.timer) % 2 == 0:
		$Announcement.stream = Globals.world_voice_lines["Pull Over"]
	else:
		$Announcement.stream = Globals.world_voice_lines["Best Driver"]
	$Announcement.play()

func get_max_steer():
	if linear_velocity.length() >= 60:
		return deg_to_rad(MAX_STEER_DEG) * 0.1
	return deg_to_rad(MAX_STEER_DEG) * STEERING_CURVE.sample(linear_velocity.length() / 60)

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
	

@export var human_drivers: Array[MeshInstance3D]
func randomize_driver_color(mesh: MeshInstance3D):
	if Globals.car_colors.size() == 0 or !mesh:
		return
	var chosen_color = Globals.car_colors[Globals.car_colors.keys().pick_random()]
	var human_mesh: Mesh = mesh.mesh.duplicate()
	var human_material: StandardMaterial3D = human_mesh.surface_get_material(0).duplicate()
	human_material.albedo_color = chosen_color
	human_mesh.surface_set_material(0, human_material)
	mesh.mesh = human_mesh
