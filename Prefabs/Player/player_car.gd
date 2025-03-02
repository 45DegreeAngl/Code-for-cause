extends VehicleBody3D
##This car is from
##https://poly.pizza/m/a_HKCtYAv2W
##the creative commons liscence is this Nissan GTR by David Sirera [CC-BY] via Poly Pizza
##Nissan GTR by David Sirera [CC-BY] (https://creativecommons.org/licenses/by/3.0/) via Poly Pizza (https://poly.pizza/m/a_HKCtYAv2W)
@export var STEERING_CURVE : Curve
@export var MAX_STEER = 0.8
##this is applied per traction wheel, so dont forget to adjust relative to how many traction wheels there are
@export var ENGINE_POWER : float = 200
@export var SOUND_MAX_SPEED : float = 75


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	change_engine_pitch()
	steering = move_toward(steering,Input.get_axis("D","A") * get_max_steer(),delta*2.5)
	engine_force = max(Input.get_axis("S","W") * ENGINE_POWER,-ENGINE_POWER/1.5)

@export var camera_sense : float = 0.001
var rot_x = 180
var rot_y = 0
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_ESCAPE:
			match Input.mouse_mode:
				Input.MOUSE_MODE_CAPTURED:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				Input.MOUSE_MODE_VISIBLE:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		rot_x += event.relative.x * camera_sense
		rot_y += event.relative.y * camera_sense
		
		rot_y = clampf(rot_y,deg_to_rad(-90),deg_to_rad(90))
		handle_cam_rotation()

func handle_cam_rotation():
	$Cameras/Windshield.transform.basis = Basis() #reset rot
	$Cameras/Windshield.rotate_object_local(Vector3(0,1,0),-rot_x)
	$Cameras/Windshield.rotate_object_local(Vector3(1,0,0),-rot_y)
	
func change_engine_pitch():
	if (not $Engine.playing) and $Engine.pitch_scale > 0.01:
		$Engine.play()
	var pitch = min(1, linear_velocity.length()/SOUND_MAX_SPEED)
	if pitch <= 0.01:
		$Engine.stop()
	$Engine.pitch_scale = pitch

func get_max_steer():
	if linear_velocity.length() >= 100:
		return MAX_STEER * 0.1
	return MAX_STEER * STEERING_CURVE.sample(linear_velocity.length()/100)
