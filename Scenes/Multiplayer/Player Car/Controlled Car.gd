#this will be the car each player individually will control, they will also have to be able to spawn the physics bodies characters
#extends VehicleBody3D
#class_name BaseCar
#
##this script is for the car generally, so engine pitch, and car stats
#@export_subgroup("Car Stats")
#@export var STEERING_CURVE : Curve
#@export var MAX_STEER_DEG : float = 45.0
###this is applied per traction wheel, so dont forget to adjust relative to how many traction wheels there are
#@export var ENGINE_POWER : float = 200
#var original_engine_power:float = 0
#var steer_input : float :
	#set(val):
		#steer_input = clampf(val, -1, 1)
#var engine_input : float :
	#set(val):
		#engine_input = clampf(val, -1, 1)
#var cur_lin_vel:Vector3 = Vector3.ZERO
#
##context stats
#@export_subgroup("Context")
#@export var stuck_timer : Timer
#var stuck : bool = false
#
## lag reduction stats
#@export_subgroup("Performance Settings")
## how often navigation should be updated, in ms
#@export var update_interval : float = 200
## the variable we'll use to keep track of the time till the next update. We apply a random offset to prevent two cars spawned at the same time from updating at the same time
#@onready var time_to_update = randf() * update_interval
#
#func get_max_steer():
	#if linear_velocity.length() >= 60:
		#return deg_to_rad(MAX_STEER_DEG) * 0.1
	#return deg_to_rad(MAX_STEER_DEG) * STEERING_CURVE.sample(linear_velocity.length()/60)
#
#func check_stuck():
	#if !stuck_timer.is_connected("timeout",on_stuck_timer_ended):
		#stuck_timer.connect("timeout",on_stuck_timer_ended)
	#if linear_velocity.length() < 1:
		#if stuck_timer.is_stopped():
			#stuck_timer.start()
	#else:
		#stuck_timer.stop()
#
#func on_stuck_timer_ended():
	#stuck = true
#
###context math functions
#func py_distance(a,b):
	#return sqrt(pow((a-b),2) + pow((a-b),2))
#
#func xz_plane_dist(a:Vector3, b:Vector3):
	#return sqrt(pow((a.x-b.x),2) + pow((a.z-b.z),2))
#
#func xz_triangle_area(a:Vector3,b:Vector3,c:Vector3):
	#return (b.x-a.x)*(c.z-a.z) - (b.z-a.z)*(c.x-a.x)
#
#func _physics_process(delta: float) -> void:
	#time_to_update += delta * 1000
	#
	#if time_to_update >= update_interval:
		#time_to_update = 0
		#driver_process(delta)
		#update_context_variables(delta)
		#update_steer(delta)
		#update_cosmetics(delta)
		#
		##steering = steer_input
		##engine_force = engine_input
		#cur_lin_vel = linear_velocity
		#check_stuck()
	#
#
#func driver_process(_delta):
	#pass
#
#func update_context_variables(_delta):
	#pass
#
#func update_steer(_delta):
	#pass
#
#func update_cosmetics(_delta):
	#pass


extends BaseCar
class_name ControlledCar
##This car is from
##https://poly.pizza/m/a_HKCtYAv2W
##the creative commons liscence is this Nissan GTR by David Sirera [CC-BY] via Poly Pizza
##Nissan GTR by David Sirera [CC-BY] (https://creativecommons.org/licenses/by/3.0/) via Poly Pizza (https://poly.pizza/m/a_HKCtYAv2W)
@export var DEBUG_MODE : bool = false

@export var cosmetic_node : ControlledCosmetic
@export var cop_node : Node

var occupied:bool = true

@onready var driver_look_area:Area3D = $Cameras/Windshield/Area3D
@onready var character_raycast : RayCast3D

var network_id = -1
var owner_steam_id: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_multiplayer:
		network_id = Globals.generate_network_id()
		Globals.register_node(self, network_id)

	original_engine_power = ENGINE_POWER
	Globals.player_vehicle = self
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cosmetic_node._on_radio_finished()
	Globals.car_contents = {"Beer":1,"Sake":0,"Jaeger":0}
	Globals.update_bottles.emit()
	Globals.timer = 0
	
	if DEBUG_MODE:
		return
	MainShaderCanvas.filter_dict["drunk"][0].visible = !Globals.motion_sickness
	MainShaderCanvas.filter_dict["BeerMeter"][0].visible = true
	Globals.drunkenness= Globals.drunkenness
	
	Debug.fp_cam = $Cameras/Windshield
	Debug.wheel_cam = $Cameras/Camera3D
	Debug.lock_target = self
	Debug.car_target = self
	Debug.player_model = $Mesh/Character

func set_steam_owner(id: int):
	owner_steam_id = id
	# Authority is true if you are the host OR if the car's owner ID is your own Steam ID.
	is_authority = Network.is_host or GlobalSteam.steam_id == owner_steam_id
	if cosmetic_node:
		cosmetic_node.set_steam_owner(id)

func driver_process(delta):
	Globals.timer+=delta

func update_context_variables(_delta):
	if $"Ground Ray".get_collider():
		var collision_thing = $"Ground Ray".get_collider()
		if collision_thing.has_meta("Road"):
			if collision_thing.get_meta("Road"):
				ENGINE_POWER = original_engine_power
			else:
				ENGINE_POWER = original_engine_power/2
		else:
			ENGINE_POWER = original_engine_power/2

func update_steer(delta):
	if is_multiplayer and not is_authority: return

	if !occupied or Globals.game_over or Globals.game_paused:
		if abs(linear_velocity):
			engine_force = move_toward(linear_velocity.length(),-linear_velocity.length(),delta)
		else:
			engine_force = move_toward(engine_force,0,delta)
		return

	var input_payload = {
		"interact": Input.is_action_just_pressed("KEYWORD_INTERACT"),
		"alt_interact": Input.is_action_just_pressed("KEYWORD_ALT_INTERACT"),
		"steer_axis": Input.get_axis("KEYWORD_RIGHT", "KEYWORD_LEFT"),
		"engine_axis": Input.get_axis("KEYWORD_BACKWARD", "KEYWORD_FORWARD"),
		"misc_interact": Input.is_action_just_pressed("KEYWORD_MISC_INTERACT"),
		"delta": delta # Include delta time for consistent physics
	}
	
	if is_multiplayer:
		Network.p2p_send_input_to_host(input_payload)
	else:
		handle_input(input_payload)

func handle_input(input_payload: Dictionary):
	# This function is now the single point of authority for applying input.
	# It's called directly for single-player, and by the host for multiplayer.
	var delta = input_payload.get("delta", get_physics_process_delta_time())
	steering = move_toward(steering, input_payload.get("steer_axis", 0.0) * get_max_steer(), delta * 2.5)
	engine_force = max(input_payload.get("engine_axis", 0.0) * ENGINE_POWER, -ENGINE_POWER / 1.5)

	if input_payload.get("interact", false):
		match cur_look_at:
			looking_at.Door:
				if !door_blocked:
					spawn_player_character()
			looking_at.Alchohol:
				drink_random()
			looking_at.Radio:
				cosmetic_node.toggle_radio()
					
	elif input_payload.get("alt_interact", false):
		if cur_look_at == looking_at.Radio:
			cosmetic_node.change_frequency()
		else:
			throw_debris()
	
	if input_payload.get("misc_interact", false):
		cosmetic_node.toggle_head_lights()


func update_cosmetics(delta):
	if Input.is_action_just_pressed("KEYWORD_MISC_INTERACT"):#toggle Headlights
		cosmetic_node.toggle_head_lights()
	cosmetic_node.update_wheel(steering*2*PI)
	cosmetic_node.update_speedometer_tick(-Vector3(deg_to_rad(0),deg_to_rad(-90),deg_to_rad(30)).normalized(),move_toward((engine_force/ENGINE_POWER),(engine_force/ENGINE_POWER),delta))

func _on_collide(body):
	if body.has_meta("Cop"):
		call_deferred("die_by_cop")
	elif abs(linear_velocity.length()-cur_lin_vel.length())>1 and !$Sounds/Crash.playing:
		$Sounds/Crash.stream = Globals.crash_sounds[Globals.crash_sounds.keys().pick_random()]
		$Sounds/Crash.play()
	elif body is Debris:
		#play debris hit effect
		pass
	if body is VehicleBody3D and !body.has_meta("Cop"):
		Globals.sober_drivers_hit+=1

func flip_car_rpc():
	process_mode = PROCESS_MODE_DISABLED
	rotation = Vector3.ZERO
	global_position += Vector3(0,10,0)
	process_mode = PROCESS_MODE_INHERIT
	Globals.car_flip_count+=1

func flip_car():
	if is_multiplayer:
		Network.p2p_call_func(network_id, "flip_car_rpc")
	else:
		flip_car_rpc()

func die_by_cop():
	if !DEBUG_MODE:
		Globals.game_lost.emit("Cops")

func drink_random_rpc():
	var temp_array :Array = []
	for bottle in Globals.car_contents:
		if Globals.car_contents[bottle]>0:
			temp_array.append(bottle)
	if temp_array.is_empty():
		return
	if randi_range(0,2)==0:
		cosmetic_node.play_voice()
	var picked_bottle : String = temp_array.pick_random()
	match picked_bottle:
		"Beer":
			Globals.drunkenness+=10
		"Sake":
			Globals.drunkenness+=10
		"Jaeger":
			Globals.drunkenness+=10
		_:
			Globals.drunkenness+=1
	
	Globals.car_contents[picked_bottle] -= 1
	Globals.update_bottles.emit()

func drink_random():
	if is_multiplayer:
		Network.p2p_call_func(network_id, "drink_random_rpc")
	else:
		drink_random_rpc()

var rot_x = 0
var rot_y = 0
var joy_pad_RStick : Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if !occupied or Globals.game_paused:
		return
	
	if Input.is_action_just_pressed("KEYWORD_PAUSE"):
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index==MOUSE_BUTTON_LEFT and !Globals.game_over:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		rot_x += event.relative.x * Globals.car_mous_sens
		rot_y += event.relative.y * Globals.car_mous_sens
		
		rot_y = clampf(rot_y,deg_to_rad(-90),deg_to_rad(90))
		handle_cam_rotation()
	elif event is InputEventJoypadMotion:
		match event.axis:
			2:
				joy_pad_RStick.x = event.axis_value 
			3:
				joy_pad_RStick.y = event.axis_value 
		
	if Globals.game_over:
		return

func handle_cam_rotation():
	$Cameras/Windshield.transform.basis = Basis() #reset rot
	$Cameras/Windshield.rotate_object_local(Vector3(0,1,0),-rot_x)
	$Cameras/Windshield.rotate_object_local(Vector3(1,0,0),-rot_y)

func get_max_steer():
	if linear_velocity.length() >= 60:
		return deg_to_rad(MAX_STEER_DEG) * 0.1
	return deg_to_rad(MAX_STEER_DEG) * STEERING_CURVE.sample(linear_velocity.length()/60)

var spawned_player : Node3D = null
var door_blocked : bool = false

func spawn_player_character_rpc():
	if spawned_player:
		return
	#instantiate player character
	var player_instance : Node3D = Globals.multiplayer_packed.instantiate()
	player_instance.set_steam_owner(owner_steam_id)
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
	spawned_player = player_instance

func spawn_player_character()->Node3D:
	if is_multiplayer:
		Network.p2p_call_func(network_id, "spawn_player_character_rpc")
	else:
		spawn_player_character_rpc()
	return spawned_player

func enter_car_rpc():
	cur_look_at = null
	occupied = true
	$Cameras/Windshield.current = true
	var possible_objects : Array = [spawned_player.left_hand,spawned_player.right_hand]
	for object :RigidBody3D in possible_objects:
		if object==null:
			continue
		if object.has_meta("Bottle"):
			if object.get_meta("Bottle") == ("Sake"):
				Globals.car_contents["Sake"] +=1
			elif object.get_meta("Bottle") == ("Beer"):
				Globals.car_contents["Beer"] +=1
			elif object.get_meta("Bottle")==("Jaeger"):
				Globals.car_contents["Jaeger"] +=1
			elif object.get_meta("Bottle")==("Crate"):
				SteamAchievements.setAchievement("BULK BUYER")
				Globals.car_contents[object.get_meta("Bottle_Type")] += 6
				Globals.total_alcohol_bought+=5
			object.call_deferred("queue_free")
			Globals.total_alcohol_bought+=1
			Globals.update_bottles.emit()
		elif object is Debris:
			object.process_mode = Node.PROCESS_MODE_DISABLED
			object.reparent($Debrie)
			object.position = $"Debrie Spawns".get_children().pick_random().position
			object.rotation = Vector3(0,0,randf_range(0.5,1.0))
	spawned_player.call_deferred("queue_free")
	set_deferred("player_instance",null)
	Globals.set_deferred("player_character",null)
	await spawned_player.tree_exiting

func enter_car():
	if is_multiplayer:
		Network.p2p_call_func(network_id, "enter_car_rpc")
	else:
		enter_car_rpc()

func throw_debris_rpc():
	if $Debrie.get_child_count()>0:
		var chosen:RigidBody3D = $Debrie.get_children().pick_random()
		print(chosen)
		chosen.global_position = $"Debrie Launch".global_position
		print(chosen.global_position)
		print($"Debrie Launch".global_position)
		chosen.reparent(Globals.world_node.previous_road,true)
		chosen.process_mode = Node.PROCESS_MODE_INHERIT
		Globals.litter_count+=1

func throw_debris():
	if is_multiplayer:
		Network.p2p_call_func(network_id, "throw_debris_rpc")
	else:
		throw_debris_rpc()

enum looking_at{Door,Alchohol,Radio,Outside}
var cur_look_at = null

func update_tooltip_text():
	match cur_look_at:
		looking_at.Door:
			if door_blocked:
				$CanvasLayer/Tooltips/Label.text = tr("DOOR_BLOCKED_TOOLTIP")
			else:
				$CanvasLayer/Tooltips/Label.text = tr("EXIT_TOOLTIP").format([InputMap.action_get_events("KEYWORD_INTERACT")[0].as_text()])
				
		looking_at.Alchohol:
			if $Milk_Crate.alchohol_count>0:
				$CanvasLayer/Tooltips/Label.text = tr("DRINK_TOOLTIP").format([InputMap.action_get_events("KEYWORD_INTERACT")[0].as_text()])
			else:
				$CanvasLayer/Tooltips/Label.text = tr("NEED_ALCHOHOL_TOOLTIP")
		looking_at.Radio:
			$CanvasLayer/Tooltips/Label.text = tr("RADIO_TOOLTIP").format([InputMap.action_get_events("KEYWORD_INTERACT")[0].as_text(),InputMap.action_get_events("KEYWORD_ALT_INTERACT")[0].as_text()])
		looking_at.Outside:
			if !$CanvasLayer/Tooltips/Label.text.find(tr("ENTER_TOOLTIP").format([InputMap.action_get_events("KEYWORD_INTERACT")[0].as_text()]))!=-1:
				$CanvasLayer/Tooltips/Label.text += tr("ENTER_TOOLTIP").format([InputMap.action_get_events("KEYWORD_INTERACT")[0].as_text()])
		null,"_":
			$CanvasLayer/Tooltips/Label.text = ""

func _on_door_box_body_entered(_body: Node3D) -> void:
	door_blocked = !$"Interactibles/Door box".get_overlapping_bodies().is_empty()
	update_tooltip_text()

func _on_door_box_body_exited(_body: Node3D=null) -> void:
	door_blocked = !$"Interactibles/Door box".get_overlapping_bodies().is_empty()
	update_tooltip_text()

func _on_enter_exit_area_entered(area: Area3D) -> void:
	if not area:
		return
	if area == driver_look_area:
		cur_look_at = looking_at.Door
		door_blocked = !$"Interactibles/Door box".get_overlapping_bodies().is_empty()
		update_tooltip_text()
		#print("door")
	#elif spawned_player == area.get_parent().get_parent().get_parent().get_parent().get_parent():
		#spawned_player.set_car_door("Car")
		#cur_look_at = looking_at.Outside
		#update_tooltip_text()
		

func _on_alcholol_area_entered(area: Area3D) -> void:
	if area == driver_look_area:
		cur_look_at = looking_at.Alchohol
		update_tooltip_text()
		#print("alchohol")

func _on_radio_area_entered(area: Area3D) -> void:
	if area == driver_look_area:
		cur_look_at = looking_at.Radio
		update_tooltip_text()
		#print("radio")

func flip_car_option(state:bool):
	if state:
		$CanvasLayer/Tooltips/Label.text += tr("FLIP_TOOLTIP").format([InputMap.action_get_events("KEYWORD_ALT_INTERACT")[0].as_text()])
	else:
		$CanvasLayer/Tooltips/Label.text = ""

func _on_raycast_exit(area:Area3D)->void:
	if not area:
		return
	if area == driver_look_area:
		cur_look_at = null
		update_tooltip_text()
		#print("null")
	#if spawned_player == area.get_parent().get_parent().get_parent().get_parent().get_parent():
		#spawned_player.set_car_door(null)
		#cur_look_at = null
		#update_tooltip_text()

func _on_sobriety_timer_timeout() -> void:
	print(Globals.drunkenness)
	if DEBUG_MODE:
		return
	Globals.drunkenness-=1
	if Globals.drunkenness<6:
		Globals.game_lost.emit("Sober")
		MainShaderCanvas.toggle_filter("BeerMeter")
	elif Globals.drunkenness==16:
		$"Sounds/Sobriety Alarm".stream = Globals.player_voice_lines[randi_range(0,1)]#magic number for the player voice lines
		$"Sounds/Sobriety Alarm".play()
	else:
		$"Sounds/Sobriety Alarm".stop()

func get_network_state():
	return {
		"pos": global_transform.origin,
		"rot": global_transform.basis,
		"lin_vel": linear_velocity,
		"ang_vel": angular_velocity,
		"steering": steering,
		"engine_force": engine_force
	}

func set_network_state(state: Dictionary):
	if not is_authority:
		global_transform.origin = state.pos
		global_transform.basis = state.rot
		linear_velocity = state.lin_vel
		angular_velocity = state.ang_vel
		steering = state.steering
		engine_force = state.engine_force
