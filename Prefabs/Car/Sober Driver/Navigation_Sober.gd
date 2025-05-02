extends VehicleBody3D
@export var DEBUG_MODE : bool = false
@export var backwards : bool = false
@export var target: VehicleBody3D
@export var hunt_distance : float = 15
@export var point_accept_distance : float = 15

@export var STEERING_CURVE : Curve
@export var MAX_STEER_DEG : float = 45.0
##this is applied per traction wheel, so dont forget to adjust relative to how many traction wheels there are
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
func set_nav_region(nav:NavigationRegion3D):
	navigation_region = nav
@export var navigation_path : Path3D
func set_nav_path(path_node:Path3D):
	navigation_path = path_node

@onready var navigation_agent : NavigationAgent3D = $NavigationAgent3D

var navigation_endpoint : Vector3
var cur_nav_index:int = 0

#var current_path : Path3D = null

var hunt : bool = false

var reversing := false

var parked : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$StuckTimer.connect("timeout", on_stuck_timer_ended)
	$ReverseTimer.connect("timeout", on_reverse_timer_ended)
	randomize_chasis_color()
	for driver in human_drivers:
		randomize_driver_color(driver)
	adjust_cur_nav_index()

#func curve_point_to_global(point : Vector3, path : Path3D):
	#return path.global_basis * point + path.global_position
var saved_linear_velocity : Vector3 = Vector3.ZERO

func _on_collide(_body):
	if abs(linear_velocity.length()-saved_linear_velocity.length())>1 and !$Sounds/Crash.playing:
		$Sounds/Crash.stream = Globals.crash_sounds[Globals.crash_sounds.keys().pick_random()]
		$Sounds/Crash.play()

#func distance_to(a, b):
	#return sqrt(pow((a.x-b.x),2) + pow((a.z-b.z),2))

func curve_point_to_global(point : Vector3, path : Path3D):
	return path.global_basis * point + path.global_position

signal request_new_nav_region(vehicle:VehicleBody3D)
func nav_control(_delta: float) -> void:
	if !navigation_path:
		return
	if !navigation_endpoint:
		if backwards:
			cur_nav_index = navigation_path.curve.point_count-1
		navigation_endpoint = navigation_path.curve.get_point_position(cur_nav_index)
	# Get the global position of the target
	var target_position = curve_point_to_global(navigation_endpoint,navigation_path)
	
	if target_position.distance_to(self.global_position)<=point_accept_distance:
		navigation_is_finished()
	
	if reversing:
		engine_input = -1
		steer_input = 0
		return
	elif hunt:
		target_position = target.global_position
	
	# If parked or hunt is active, stop moving
	if parked :
		return

	# Set the target position for the navigation agent
	navigation_agent.set_target_position(target_position)

	# Check if the path is valid and ready
	if navigation_agent.is_navigation_finished():
		return

	# Get the current location to follow the calculated path
	var next_position = navigation_agent.get_next_path_position()

	# Calculate the vector to the next position
	var direction_vector = (next_position - global_position).normalized()

	# Compute the steering input based on the direction vector
	var angle_to_target = (-basis.z).signed_angle_to(direction_vector, Vector3.UP)
	steer_input = clamp(angle_to_target / deg_to_rad(MAX_STEER_DEG), -1, 1)

	print(steer_input)

	# Compute engine input based on distance to next position
	var distance_to_next = global_position.distance_to(next_position)
	engine_input = 1 if distance_to_next > 2 else 0  # Adjust threshold as needed

func navigation_is_finished():
	if !navigation_path or !navigation_region:
		print("I ",self," require a nav path node or a navigation region")
		request_new_nav_region.emit(self)
		return
	if backwards:
		cur_nav_index-=1
	else:
		cur_nav_index+=1
	#check if the next road is present
	if 0<=cur_nav_index and cur_nav_index<navigation_path.curve.point_count:
		#if we reach a point in the path, look for next point
		navigation_endpoint = navigation_path.curve.get_point_position(cur_nav_index)
	#if no point is found, look for next navigation region
	else:
		request_new_nav_region.emit(self)

func adjust_cur_nav_index():
	if !navigation_path:
		cur_nav_index = 0
		return
	cur_nav_index = get_closest_nav_point()
	print("Adjusted nav index to: ",cur_nav_index)

func get_closest_nav_point()->int:
	if !navigation_path or navigation_path.curve.point_count==0:
		return -1
	var result : int = 0
	var current_closest : Vector3 = navigation_path.curve.get_point_position(result)
	
	for point in navigation_path.curve.point_count:
		if curve_point_to_global(current_closest,\
		navigation_path).distance_to(global_position)>=\
		curve_point_to_global(navigation_path.curve.get_point_position(point),\
		navigation_path).distance_to(global_position):
			current_closest = navigation_path.curve.get_point_position(point)
			result = point
	
	return result


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#control(delta)
	nav_control(delta)
	change_engine_pitch()
	check_stuck()
	
	if target:
		#print(distance_to(self.global_position,target.global_position))
		if target.global_position.distance_to(self.global_position)<hunt_distance:
			hunt = true
		else:
			hunt = false
			navigation_is_finished()
		
		if target.global_position.z-300>self.global_position.z:
			if !hunt:
				parked = true
		else:
			parked = false
	
	if parked:
		return
	steering = move_toward(steering,steer_input * get_max_steer(),delta*2.5)
	engine_force = max(engine_input * ENGINE_POWER,-ENGINE_POWER/1.5)


func change_engine_pitch():
	if (not $Engine.playing) and $Engine.pitch_scale > 0.01:
		$Engine.play()
	var pitch = min(1, linear_velocity.length()/SOUND_MAX_SPEED)
	if pitch <= 0.01:
		$Engine.stop()
	if pitch>0.0:
		$Engine.pitch_scale = pitch


func get_max_steer():
	if linear_velocity.length() >= 60:
		return deg_to_rad(MAX_STEER_DEG) * 0.1
	return deg_to_rad(MAX_STEER_DEG) * STEERING_CURVE.sample(linear_velocity.length()/60)

const colors :Array[Color] = [Color.RED,Color.BLUE]
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
	reversing = false

func randomize_chasis_color():
	if Globals.car_colors.size()==0:
		return
	var chosen_color = Globals.car_colors[Globals.car_colors.keys().pick_random()]
	var chasis_mesh:Mesh = $Mesh/Chassis.mesh.duplicate()
	var chasis_material:StandardMaterial3D = chasis_mesh.surface_get_material(0).duplicate()
	chasis_material.albedo_color = chosen_color
	chasis_mesh.surface_set_material(0,chasis_material)
	$Mesh/Chassis.mesh = chasis_mesh

@export var human_drivers: Array[MeshInstance3D]

func randomize_driver_color(mesh:MeshInstance3D):
	if Globals.car_colors.size()==0:
		return
	var chosen_color = Globals.car_colors[Globals.car_colors.keys().pick_random()]
	var human_mesh:Mesh = mesh.mesh.duplicate()
	var human_material:StandardMaterial3D = human_mesh.surface_get_material(0).duplicate()
	human_material.albedo_color = chosen_color
	human_mesh.surface_set_material(0,human_material)
	mesh.mesh = human_mesh
