extends BaseCar
class_name PlayerCar
##This car is from
##https://poly.pizza/m/a_HKCtYAv2W
##the creative commons liscence is this Nissan GTR by David Sirera [CC-BY] via Poly Pizza
##Nissan GTR by David Sirera [CC-BY] (https://creativecommons.org/licenses/by/3.0/) via Poly Pizza (https://poly.pizza/m/a_HKCtYAv2W)
@export var DEBUG_MODE : bool = false

@export var cosmetic_node : PlayerCosmetic
@export var cop_node : Node

var occupied:bool = true

@onready var driver_look_area:Area3D = $Cameras/Windshield/Area3D
@onready var character_raycast : RayCast3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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

func driver_process(delta):
	Globals.timer+=delta

func update_context_variables(_delta):
	if $"Ground Ray".get_collider():
		var collision_thing = $"Ground Ray".get_collider()
		#print("balls",collision_thing)
		if collision_thing is GridMap and collision_thing.has_meta("Road") and !collision_thing.get_meta("Road"):
			ENGINE_POWER = original_engine_power/2
		else:
			ENGINE_POWER = original_engine_power

func update_steer(delta):
	if !occupied or Globals.game_over or Globals.game_paused:
		if abs(linear_velocity):
			engine_force = move_toward(linear_velocity.length(),-linear_velocity.length(),delta)
		else:
			engine_force = move_toward(engine_force,0,delta)
		return

	if Input.is_action_just_pressed("KEYWORD_INTERACT"):
		match cur_look_at:
			looking_at.Door:#spawn human player, switch camera
				if !door_blocked:
					spawned_player = spawn_player_character()
					Globals.player_character = spawned_player
					cur_look_at = null
					update_tooltip_text()
				else:
					print($"Interactibles/Door box".get_overlapping_bodies())
				 
			looking_at.Alchohol:#check globals to see how many beers in car, drink one if present, frown if no
				#print(Globals.player_voice_lines.size())
				drink_random()
				update_tooltip_text()
				#print("glug glug glug")
			looking_at.Radio:#change radio 
				cosmetic_node.toggle_radio()
					
	elif Input.is_action_just_pressed("KEYWORD_ALT_INTERACT"):#change radio track if playing
		if cur_look_at == looking_at.Radio:
			cosmetic_node.change_frequency()
		else:
			throw_debris()
	if joy_pad_RStick:
		rot_x += joy_pad_RStick.x * Globals.car_cont_sens * delta *25
		rot_y += joy_pad_RStick.y * Globals.car_cont_sens * delta *25
		rot_y = clampf(rot_y,-1.5,0.75)
		handle_cam_rotation()

	steering = move_toward(steering,Input.get_axis("KEYWORD_RIGHT","KEYWORD_LEFT") * get_max_steer(),delta*2.5)
	var forward_axis = Input.get_axis("KEYWORD_BACKWARD","KEYWORD_FORWARD")
	engine_force = max(forward_axis * ENGINE_POWER,-ENGINE_POWER/1.5)

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

func flip_car():
	process_mode = PROCESS_MODE_DISABLED
	rotation = Vector3.ZERO
	global_position += Vector3(0,10,0)
	process_mode = PROCESS_MODE_INHERIT
	#print(Globals.car_flip_count)
	Globals.car_flip_count+=1

func die_by_cop():
	if !DEBUG_MODE:
		Globals.game_lost.emit("Cops")

func drink_random():
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
				GlobalSteam.setAchievement("BULK BUYER")
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

func throw_debris():
	if $Debrie.get_child_count()>0:
		var chosen:RigidBody3D = $Debrie.get_children().pick_random()
		print(chosen)
		chosen.global_position = $"Debrie Launch".global_position
		print(chosen.global_position)
		print($"Debrie Launch".global_position)
		chosen.reparent(Globals.world_node.previous_road,true)
		chosen.process_mode = Node.PROCESS_MODE_INHERIT
		Globals.litter_count+=1

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
	if area == driver_look_area:
		cur_look_at = looking_at.Door
		door_blocked = !$"Interactibles/Door box".get_overlapping_bodies().is_empty()
		update_tooltip_text()
		#print("door")
	elif spawned_player == area.get_parent().get_parent().get_parent().get_parent().get_parent():
		spawned_player.set_car_door("Car")
		cur_look_at = looking_at.Outside
		update_tooltip_text()
		

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
	if area == driver_look_area:
		cur_look_at = null
		update_tooltip_text()
		#print("null")
	if spawned_player == area.get_parent().get_parent().get_parent().get_parent().get_parent():
		spawned_player.set_car_door(null)
		cur_look_at = null
		update_tooltip_text()

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
