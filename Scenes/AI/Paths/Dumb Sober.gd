extends VehicleBody3D
@export var DEBUG_MODE : bool = false
@export var backwards:bool = false
@export var target: VehicleBody3D
@export var hunt_distance : float = 15

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

var cur_nav_index:int = 0
var path_endpoint : Vector3

@onready var cur_road : RoadSegment = null
func get_cur_road():
	return cur_road

var navigation_path : Path3D = null
func set_nav_path(path_node: Path3D):
	if path_node == navigation_path:
		#printerr("Attempting to set current path node to current nav path")
		return false
	navigation_path = path_node
	
	# Reset navigation index when a new path is given
	cur_nav_index = get_closest_nav_point() 
	if navigation_path:
		path_endpoint = navigation_path.global_transform * navigation_path.curve.get_point_position(cur_nav_index)
	return true

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
	request_new_nav_region.emit(self)

func curve_point_to_global(point : Vector3, path : Path3D):
	return path.global_basis * point + path.global_position
var saved_linear_velocity : Vector3 = Vector3.ZERO

signal request_new_nav_region(vehicle: VehicleBody3D,road_completed:bool)

func control(_delta) -> void:
	saved_linear_velocity = linear_velocity
	var lookahead_dist = 1.5
	var throttle_lookahead_dist = 3 + 1* sqrt(linear_velocity.length())
	
	if reversing:
		engine_input = -1
		steer_input = 0
	elif hunt:
		#navigation_path = null
		var target_point_global = Globals.player_vehicle.global_position
		var target_lookahead_vector = (target_point_global - global_position).normalized()
		var target_angle_to_lookahead = (-basis.z).signed_angle_to(target_lookahead_vector, global_basis.y)
		steer_input = target_angle_to_lookahead/(PI/4)
		
		var vector_to_target = target_point_global-global_position
		var dot_product = (-basis.z).dot(vector_to_target.normalized())
		
		if dot_product>0 and linear_velocity.length() > 40:
			engine_input = -1
		else:
			engine_input = 1
	else:
		if !navigation_path:
			return
		
		var global_to_curve_space_pos = navigation_path.global_basis.inverse() * (global_position - navigation_path.global_position)
		var closest_point_offset = navigation_path.curve.get_closest_offset(global_to_curve_space_pos)
		var lookahead_point = navigation_path.curve.sample_baked(closest_point_offset + lookahead_dist)
		var lookahead_point_global = curve_point_to_global(lookahead_point, navigation_path)
		var lookahead_vector = (lookahead_point_global - global_position).normalized()
		var angle_to_lookahead = (-basis.z).signed_angle_to(lookahead_vector, global_basis.y)
		
		var closest_point = navigation_path.curve.get_closest_point(global_to_curve_space_pos)
		var slightly_ahead_point = navigation_path.curve.sample_baked(closest_point_offset + 0.1)
		var global_slightly_ahead_point = curve_point_to_global(slightly_ahead_point, navigation_path)
		var global_closest_point = curve_point_to_global(closest_point, navigation_path)
		var path_heading = (global_slightly_ahead_point - global_closest_point).normalized()
		var path_normal = path_heading.rotated(Vector3.UP, PI/2)
		var cross_track_error = (global_closest_point - global_position).dot(path_normal)
		var current_heading = -global_basis.z
		
		var cross_track_error_gain = 2
		var stanley_steer_angle = current_heading.signed_angle_to(path_heading, Vector3.UP) + atan2((cross_track_error_gain * cross_track_error),linear_velocity.length())
		steer_input = angle_to_lookahead * 4
	
		var sample_pts = []
		
		for i in range(3):
			var this_lookahead_dist = throttle_lookahead_dist/3.0 * (i+1)
			var this_lookahead_point = navigation_path.curve.sample_baked(closest_point_offset + this_lookahead_dist)
			var this_lookahead_point_global = curve_point_to_global(this_lookahead_point, navigation_path)
			sample_pts.append(this_lookahead_point_global)
		
		var A = area(sample_pts[0], sample_pts[1], sample_pts[2])
		var curvature = 4*A/(distance_to(sample_pts[0], sample_pts[1]) * distance_to(sample_pts[1], sample_pts[2]) * distance_to(sample_pts[2], sample_pts[0]))
		var trajectory_curvature = stanley_steer_angle/WHEEL_BASE / linear_velocity.length()
		if abs(curvature) > abs(trajectory_curvature) and abs(steer_input) >= 1 and linear_velocity.length() > 40:
			engine_input = -1
		else:
			engine_input = 1
		
		if(closest_point_offset/navigation_path.curve.get_baked_length() > 0.95):
			printerr("I a dumb driver am requesting a new road")
			request_new_nav_region.emit(self,true)

func _on_collide(_body):
	if abs(linear_velocity.length()-saved_linear_velocity.length())>1 and !$Sounds/Crash.playing:
		$Sounds/Crash.stream = Globals.crash_sounds[Globals.crash_sounds.keys().pick_random()]
		$Sounds/Crash.play()

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


#returns triangle area in xz plane
func area(a,b,c):
	return (b.x-a.x)*(c.z-a.z) - (b.z-a.z)*(c.x-a.x)

func distance_to(a, b):
	return sqrt(pow((a.x-b.x),2) + pow((a.z-b.z),2))

#func find_nearest_path() -> Path3D:
	#var paths : Array[Node] = get_tree().get_nodes_in_group("road_path")
	#var closest_path = null
	#var min_dist = INF
	#for path in paths:
		#var dist = global_position.distance_to(path.global_position)
		#if dist < min_dist:
			#min_dist = dist
			#closest_path = path
	#return closest_path

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	control(delta)
	change_engine_pitch()
	check_stuck()
	
	#print(distance_to(self.global_position,target.global_position))
	if distance_to(self.global_position,target.global_position)<hunt_distance:
		hunt = true
	else:
		hunt = false
	
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
