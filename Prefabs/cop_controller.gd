extends VehicleBody3D
##This car is from
##https://poly.pizza/m/a_HKCtYAv2W
##the creative commons liscence is this Nissan GTR by David Sirera [CC-BY] via Poly Pizza
##Nissan GTR by David Sirera [CC-BY] (https://creativecommons.org/licenses/by/3.0/) via Poly Pizza (https://poly.pizza/m/a_HKCtYAv2W)
@export var DEBUG_MODE : bool = false

@export var STEERING_CURVE : Curve
@export var MAX_STEER_DEG : float = 45.0
##this is applied per traction wheel, so dont forget to adjust relative to how many traction wheels there are
@export var ENGINE_POWER : float = 200
@export var SOUND_MAX_SPEED : float = 75

var steer_input : float :
	set(val):
		steer_input = clampf(val, -1, 1)
var engine_input : float :
	set(val):
		engine_input = clampf(val, -1, 1)

var current_path : Path3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func control(delta) -> void:
	var lookahead_dist = 1.5
	if current_path == null:
		current_path = find_nearest_path()
	
	var global_to_curve_space_pos = current_path.global_basis.inverse() * (global_position - current_path.global_position)
	var closest_point_offset = current_path.curve.get_closest_offset(global_to_curve_space_pos)
	var lookahead_point = current_path.curve.sample_baked(closest_point_offset + lookahead_dist)
	var lookahead_point_global = current_path.global_basis * lookahead_point + current_path.global_position
	var lookahead_vector = (lookahead_point_global - global_position).normalized()
	
	var angle_to_lookahead = (-basis.z).signed_angle_to(lookahead_vector, global_basis.y)
	if(closest_point_offset/current_path.curve.get_baked_length() > 0.99):
		current_path = null
	
	steer_input = angle_to_lookahead/(PI/2)
	
	engine_input = 1-2*abs(steer_input)

func find_nearest_path() -> Path3D:
	var paths : Array[Node] = get_tree().get_nodes_in_group("road_path")
	var closest_path = null
	var min_dist = INF
	for path in paths:
		var dist = global_position.distance_to(path.global_position)
		if dist < min_dist:
			min_dist = dist
			closest_path = path
	return closest_path

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	control(delta)
	change_engine_pitch()
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
