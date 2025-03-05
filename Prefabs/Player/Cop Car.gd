extends VehicleBody3D

@export var target:VehicleBody3D

@export var STEERING_CURVE : Curve
@export var MAX_STEER_DEG : float = 45.0
##this is applied per traction wheel, so dont forget to adjust relative to how many traction wheels there are
@export var ENGINE_POWER : float = 200
@export var SOUND_MAX_SPEED : float = 75
@onready var front_ray: RayCast3D = $"Front Ray"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	hunt(delta)
	engine_force = -ENGINE_POWER/4
	pass

func hunt(delta:float):
	var target_pos = to_local(target.global_position)
	var direction = front_ray.target_position
	var angle = direction.direction_to(target_pos)
	angle = angle.rotated(Vector3.UP,deg_to_rad(270))#might have to change this
	var steer_dir = angle.dot(direction)
	if steer_dir:
		steering = move_toward(steering,steer_dir,delta)

func change_engine_pitch():
	if (not $Engine.playing) and $Engine.pitch_scale > 0.01:
		$Engine.play()
	var pitch = min(1, linear_velocity.length()/SOUND_MAX_SPEED)
	if pitch <= 0.01:
		$Engine.stop()
	if pitch>0.0:
		$Engine.pitch_scale = pitch

func talk():
	if randi_range(0,5)!=0:
		return
	if int(Globals.timer)%2==0:
		$Announcement.stream = Globals.world_voice_lines["Pull Over"]
		$Announcement.play()
	else:
		$Announcement.stream = Globals.world_voice_lines["Best Driver"]
		$Announcement.play()


func get_max_steer():
	if linear_velocity.length() >= 60:
		return deg_to_rad(MAX_STEER_DEG) * 0.1
	return deg_to_rad(MAX_STEER_DEG) * STEERING_CURVE.sample(linear_velocity.length()/60)
