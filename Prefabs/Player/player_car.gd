extends VehicleBody3D
##This car is from
##https://poly.pizza/m/a_HKCtYAv2W
##the creative commons liscence is this Nissan GTR by David Sirera [CC-BY] via Poly Pizza
##Nissan GTR by David Sirera [CC-BY] (https://creativecommons.org/licenses/by/3.0/) via Poly Pizza (https://poly.pizza/m/a_HKCtYAv2W)
@export var DEBUG_MODE : bool = false

@export_subgroup("Car Stats")
@export var STEERING_CURVE : Curve
@export var MAX_STEER_DEG : float = 45.0
##this is applied per traction wheel, so dont forget to adjust relative to how many traction wheels there are
@export var ENGINE_POWER : float = 200
@export var SOUND_MAX_SPEED : float = 75

@export_subgroup("Radio")
@export var radio_on : bool = false
var occupied:bool = true

@onready var driver_look_area:Area3D = $Cameras/Windshield/Area3D
@onready var character_raycast : RayCast3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.player_vehicle = self
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_on_radio_finished()
	Globals.update_bottles.emit()
	Globals.timer = 0
	if DEBUG_MODE:
		return
	#MainShaderCanvas.toggle_filter("drunk")
	MainShaderCanvas.toggle_filter("BeerMeter")
	Globals.drunkenness= Globals.drunkenness

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Globals.timer+=delta
	if !occupied or Globals.game_over:
		if abs(linear_velocity):
			engine_force = move_toward(linear_velocity.length(),-linear_velocity.length(),delta)
		else:
			engine_force = move_toward(engine_force,0,delta)
		return
	
	#The line thats commented out below should remain here but commented as a reminder to check the cars max speed every time it's tweaked
	#print(linear_velocity.length())
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
				Globals.player_character = spawned_player
				$CanvasLayer/Tooltips/Label.text = ""
				
			looking_at.Alchohol:#check globals to see how many beers in car, drink one if present, frown if no
				#print(Globals.player_voice_lines.size())
				drink_random()
				if $Milk_Crate.alchohol_count>0:
					$CanvasLayer/Tooltips/Label.text = "NEED MORE ALCOHOL"
				#print("glug glug glug")
			looking_at.Radio:#change radio 
				#toggle on and off
				if radio_on:
					$Sounds/Radio.volume_db = -80
					radio_on = false
				else:
					$Sounds/Radio.volume_db = -25
					radio_on = true
					
	elif Input.is_action_just_pressed("Q"):#change radio track if playing
		if radio_on and cur_look_at == looking_at.Radio:
			$Sounds/Radio.stop()
			_on_radio_finished()
			seek_random_position()
	
	change_engine_pitch()
	steering = move_toward(steering,Input.get_axis("D","A") * get_max_steer(),delta*2.5)
	##Fix rotate code when smarter
	$Wheel.rotation.z = steering*2*PI
	var forward_axis = Input.get_axis("S","W")
	engine_force = max(forward_axis * ENGINE_POWER,-ENGINE_POWER/1.5)
	##Fix rotate code when smarter
	$Spedometer/Tick.rotate_object_local(-Vector3(deg_to_rad(0),deg_to_rad(-90),deg_to_rad(30)).normalized(),move_toward((engine_force/ENGINE_POWER),(engine_force/ENGINE_POWER),delta))
	saved_linear_velocity = linear_velocity

var saved_linear_velocity : Vector3
func _on_collide(body):
	if body.has_meta("Cop"):
		call_deferred("die_by_cop")
	elif abs(linear_velocity.length()-saved_linear_velocity.length())>1 and !$Sounds/Crash.playing:
		$Sounds/Crash.stream = Globals.crash_sounds[Globals.crash_sounds.keys().pick_random()]
		$Sounds/Crash.play()
	elif body is Debris:
		#play debris hit effect
		pass

func flip_car():
	process_mode = PROCESS_MODE_DISABLED
	rotation = Vector3.ZERO
	global_position += Vector3(0,10,0)
	process_mode = PROCESS_MODE_INHERIT

func die_by_cop():
	Globals.game_lost.emit("Cops")

func drink_random():
	var temp_array :Array = []
	for bottle in Globals.car_contents:
		if Globals.car_contents[bottle]>0:
			temp_array.append(bottle)
	if temp_array.is_empty():
		return
	if randi_range(0,2)==0:
		$"Sounds/Voice Lines".stream = Globals.player_voice_lines[randi_range(2, Globals.player_voice_lines.size()-1)]
		$"Sounds/Voice Lines".play()
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
	

@export var camera_sense : float = 0.001
var rot_x = 180
var rot_y = 0
func _input(event: InputEvent) -> void:
	if !occupied:
		return
	
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index==MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_ASCIITILDE:
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
	if (not $Sounds/Engine.playing) and $Sounds/Engine.pitch_scale > 0.01:
		$Sounds/Engine.play()
	var pitch = min(1, linear_velocity.length()/SOUND_MAX_SPEED)
	if pitch <= 0.01:
		$Sounds/Engine.stop()
	if pitch>0.0:
		$Sounds/Engine.pitch_scale = pitch

func get_max_steer():
	if linear_velocity.length() >= 60:
		return deg_to_rad(MAX_STEER_DEG) * 0.1
	return deg_to_rad(MAX_STEER_DEG) * STEERING_CURVE.sample(linear_velocity.length()/60)

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
			object.call_deferred("queue_free")
			Globals.update_bottles.emit()
		elif object is Debris:
			object.process_mode = Node.PROCESS_MODE_DISABLED
			object.reparent($Debrie)
			object.position = $"Debrie Spawns".get_children().pick_random().position
			object.rotation = Vector3(0,0,randf_range(0.5,1.0))
	spawned_player.call_deferred("queue_free")
	set_deferred("player_instance",null)
	Globals.set_deferred("player_character",null)

enum looking_at{Door,Alchohol,Radio}
var cur_look_at = null

func _on_enter_exit_area_entered(area: Area3D) -> void:
	if area == driver_look_area:
		cur_look_at = looking_at.Door
		$CanvasLayer/Tooltips/Label.text = "E to EXIT"
		#print("door")
	elif area.get_parent().get_parent().get_parent().get_parent().get_parent().has_method("set_car_door"):
		area.get_parent().get_parent().get_parent().get_parent().get_parent().set_car_door("Car")
		$CanvasLayer/Tooltips/Label.text += "E to ENTER\n"

func _on_alcholol_area_entered(area: Area3D) -> void:
	if area == driver_look_area:
		cur_look_at = looking_at.Alchohol
		if $Milk_Crate.alchohol_count>0:
			$CanvasLayer/Tooltips/Label.text = "E to DRINK"
		else:
			$CanvasLayer/Tooltips/Label.text = "NEED MORE ALCOHOL"
		#print("alchohol")

func _on_radio_area_entered(area: Area3D) -> void:
	if area == driver_look_area:
		cur_look_at = looking_at.Radio
		$CanvasLayer/Tooltips/Label.text = "E to TOGGLE\nQ to SWITCH STATION"
		#print("radio")

func flip_car_option(state:bool):
	if state:
		$CanvasLayer/Tooltips/Label.text += "Q to FLIP\n"
	else:
		$CanvasLayer/Tooltips/Label.text = ""

func _on_raycast_exit(area:Area3D)->void:
	if area == driver_look_area:
		cur_look_at = null
		#print("null")
	if area.get_parent().get_parent().get_parent().get_parent().get_parent().has_method("set_car_door"):
		area.get_parent().get_parent().get_parent().get_parent().get_parent().set_car_door(null)
	$CanvasLayer/Tooltips/Label.text = ""


func _on_sobriety_timer_timeout() -> void:
	if DEBUG_MODE:
		return
	Globals.drunkenness-=1
	if Globals.drunkenness<6:
		Globals.game_lost.emit("Sober")
		MainShaderCanvas.toggle_filter("BeerMeter")
	elif Globals.drunkenness==16:
		$"Sounds/Sobriety Alarm".stream = Globals.player_voice_lines[randi_range(0,1)]
		$"Sounds/Sobriety Alarm".play()
	else:
		$"Sounds/Sobriety Alarm".stop()

var step : int = 1
var cur_index : int = 0

#go to next track
func _on_radio_finished() -> void:
	print("RADIO CHANGED")
	step = randi_range(1,Globals.radio.size())
	cur_index += step
	cur_index = cur_index%Globals.radio.size()
	print(Globals.radio.keys()[cur_index])
	$Sounds/Radio.stream = Globals.radio[Globals.radio.keys()[cur_index]]
	$Sounds/Radio.play()

# Function to seek to a random position in the audio stream
func seek_random_position():
	var stream_length = $Sounds/Radio.get_stream().get_length()
	if stream_length > 0:
		var random_position = roundi(randf()) % roundi(stream_length)
		$Sounds/Radio.seek(random_position)
		print("Seeking to position:", random_position)
	else:
		print("Stream length is zero or undefined.")
@export_subgroup("COPS NODE")
var closest_cop : VehicleBody3D = null
@onready var label_3d: Label3D = $Cop_Detector/Label3D
@export var cops_node: Node3D

func update_cop_detector():
	if cops_node.get_child_count()<1:
		label_3d.text = "NO COPS NEARBY"
		closest_cop = null
		return
	var cur_distance = INF
	for cop in cops_node.get_children():
		if !closest_cop:
			closest_cop = cop
			cur_distance = self.global_position.distance_to(cop.global_position)
		if cur_distance>self.global_position.distance_to(cop.global_position):
			closest_cop = cop
			cur_distance = self.global_position.distance_to(cop.global_position)
	label_3d.text = str(roundi(cur_distance)) + "m"
	if cur_distance<=100:
		$Cop_Detector/Green/OmniLight3D.light_energy = 0
		$Cop_Detector/Red/OmniLight3D.light_energy = 0.2
	else:
		$Cop_Detector/Green/OmniLight3D.light_energy = 0.1
		$Cop_Detector/Red/OmniLight3D.light_energy = 0
