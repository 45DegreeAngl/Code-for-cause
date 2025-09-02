extends VehicleBody3D
class_name BaseCar

#this script is for the car generally, so engine pitch, and car stats
@export_subgroup("Car Stats")
@export var STEERING_CURVE : Curve
@export var MAX_STEER_DEG : float = 45.0
##this is applied per traction wheel, so dont forget to adjust relative to how many traction wheels there are
@export var ENGINE_POWER : float = 200
var original_engine_power:float = 0
var steer_input : float :
	set(val):
		steer_input = clampf(val, -1, 1)
var engine_input : float :
	set(val):
		engine_input = clampf(val, -1, 1)
var cur_lin_vel:Vector3 = Vector3.ZERO

#context stats
@export_subgroup("Context")
@export var stuck_timer : Timer
var stuck : bool = false

# lag reduction stats
@export_subgroup("Performance Settings")
# how often navigation should be updated, in ms
@export var update_interval : float = 200
# the variable we'll use to keep track of the time till the next update. We apply a random offset to prevent two cars spawned at the same time from updating at the same time
@onready var time_to_update = randf() * update_interval

func get_max_steer():
	if linear_velocity.length() >= 60:
		return deg_to_rad(MAX_STEER_DEG) * 0.1
	return deg_to_rad(MAX_STEER_DEG) * STEERING_CURVE.sample(linear_velocity.length()/60)

func check_stuck():
	if !stuck_timer.is_connected("timeout",on_stuck_timer_ended):
		stuck_timer.connect("timeout",on_stuck_timer_ended)
	if linear_velocity.length() < 1:
		if stuck_timer.is_stopped():
			stuck_timer.start()
	else:
		stuck_timer.stop()

func on_stuck_timer_ended():
	stuck = true

##context math functions
func py_distance(a,b):
	return sqrt(pow((a-b),2) + pow((a-b),2))

func xz_plane_dist(a:Vector3, b:Vector3):
	return sqrt(pow((a.x-b.x),2) + pow((a.z-b.z),2))

func xz_triangle_area(a:Vector3,b:Vector3,c:Vector3):
	return (b.x-a.x)*(c.z-a.z) - (b.z-a.z)*(c.x-a.x)

func _physics_process(delta: float) -> void:
	time_to_update += delta * 1000
	
	if time_to_update >= update_interval:
		time_to_update = 0
		driver_process(delta)
		update_context_variables(delta)
		update_steer(delta)
		update_cosmetics(delta)
		
		#steering = steer_input
		#engine_force = engine_input
		cur_lin_vel = linear_velocity
		check_stuck()
	

func driver_process(_delta):
	pass

func update_context_variables(_delta):
	pass

func update_steer(_delta):
	pass

func update_cosmetics(_delta):
	pass
