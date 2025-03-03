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

var occupied:bool = true

@onready var driver_look_area:Area3D = $Cameras/Windshield/Area3D
@onready var character_raycast : RayCast3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	MainShaderCanvas.toggle_filter("drunk")
	Globals.drunkenness=Globals.drunkenness


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !occupied:
		return
	if Input.is_action_just_pressed("F"):#toggle Headlights
		for child in $Light.get_children():
			if child is Light3D and child.name.findn("Head")!=-1 and child.has_method("get_param"):
				#print(child)
				var cur_energy = child.get_param(Light3D.PARAM_ENERGY)
				if cur_energy:
					child.set_param(Light3D.PARAM_ENERGY,0)
				else:
					child.set_param(Light3D.PARAM_ENERGY,1)
	elif Input.is_action_just_pressed("E"):
		match cur_look_at:
			looking_at.Door:#spawn human player, switch camera
				spawned_player = spawn_player_character()
				
			looking_at.Alchohol:#check globals to see how many beers in car, drink one if present, frown if no
				Globals.drunkenness+=1
				#print("glug glug glug")
			looking_at.Radio:#change radio
				pass
	
	change_engine_pitch()
	steering = move_toward(steering,Input.get_axis("D","A") * get_max_steer(),delta*2.5)
	engine_force = -max(Input.get_axis("S","W") * ENGINE_POWER,-ENGINE_POWER/1.5)

@export var camera_sense : float = 0.001
var rot_x = 180
var rot_y = 0
func _input(event: InputEvent) -> void:
	if !occupied:
		return
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
	if pitch>0.0:
		$Engine.pitch_scale = pitch


func get_max_steer():
	if linear_velocity.length() >= 100:
		return MAX_STEER * 0.1
	return MAX_STEER * STEERING_CURVE.sample(linear_velocity.length()/100)

var spawned_player : Node3D = null

func spawn_player_character()->Node3D:
	if spawned_player:
		return
	#instantiate player character
	var player_instance : Node3D = Globals.player_packed.instantiate()
	#update car occupation
	occupied = false
	#add character to scene
	Globals.world_node.add_child(player_instance)
	#move player to this location
	player_instance.global_transform.origin = $"Interactibles/Player Location".global_position
	#activate player camera
	player_instance.find_child("CameraPivot").get_child(0).get_child(0).current = true
	#deactivate car camera
	$Cameras/Windshield.current = false
	player_instance.car = self
	#activate player_instance
	player_instance.physical_skel.physical_bones_start_simulation()
	return player_instance

func enter_car():
	occupied = true
	$Cameras/Windshield.current = true
	spawned_player.call_deferred("queue_free")
	set_deferred("player_instance",null)

enum looking_at{Door,Alchohol,Radio}
var cur_look_at = null

func _on_enter_exit_area_entered(area: Area3D) -> void:
	if area == driver_look_area:
		cur_look_at = looking_at.Door
		print("door")
	elif area.get_parent().get_parent().get_parent().get_parent().get_parent().has_method("set_car_door"):
		area.get_parent().get_parent().get_parent().get_parent().get_parent().set_car_door("Car")

func _on_alcholol_area_entered(area: Area3D) -> void:
	if area == driver_look_area:
		cur_look_at = looking_at.Alchohol
		print("alchohol")

func _on_radio_area_entered(area: Area3D) -> void:
	if area == driver_look_area:
		cur_look_at = looking_at.Radio
		print("radio")

func _on_raycast_exit(area:Area3D)->void:
	if area == driver_look_area:
		cur_look_at = null
		print("null")
	if area.get_parent().get_parent().get_parent().get_parent().get_parent().has_method("set_car_door"):
		area.get_parent().get_parent().get_parent().get_parent().get_parent().set_car_door(null)


func _on_sobriety_timer_timeout() -> void:
	Globals.drunkenness-=1
	print(Globals.drunkenness)
	if Globals.drunkenness<=0:
		Globals.game_lost.emit()
	elif Globals.drunkenness<11:
		$"Sobriety Alarm".play()
	else:
		$"Sobriety Alarm".stop()
	
