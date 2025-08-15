extends BaseDriver
class_name RecklessDriver

@export var front_ray : RayCast3D

func update_context_variables(_delta):
	engine_input = -ENGINE_POWER/4

func update_steer(delta):
	var target_pos = to_local(target.global_position)
	var direction = front_ray.target_position
	var angle = direction.direction_to(target_pos)
	angle = angle.rotated(Vector3.UP,deg_to_rad(270))#might have to change this
	var steer_dir = angle.dot(direction)
	if steer_dir:
		steering = move_toward(steering,steer_dir,delta)
	engine_force = engine_input
