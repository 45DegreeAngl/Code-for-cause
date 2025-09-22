#this is the script that this script extends from, its commented out here just for you to know its origins
#extends Node
#class_name BaseCosmetic
#@export var car_ref : VehicleBody3D = null
#
#@export_category("Color")
#@export var randomize_color_meshes: Array[MeshInstance3D] = []
#@export var head_lights : Array[SpotLight3D] = []
#@export var back_lights : Array[SpotLight3D] = []
#@export_category("Sound")
#@export var engine_player : AudioStreamPlayer3D
#@export var ENGINE_SOUND_MAX_SPEED : float = 75
#@export var crash_player : AudioStreamPlayer3D
#
#func randomize_mesh_colors(mesh: MeshInstance3D):
	#if Globals.car_colors.size() == 0 or mesh == null or mesh.mesh == null:
		#return
	#
	#var original_mesh := mesh.mesh
	#var sel_mesh := original_mesh.duplicate()
	#
	#if sel_mesh.get_surface_count() == 0:
		#return
	#
	#var material :StandardMaterial3D= sel_mesh.surface_get_material(0)
	#if material == null or not material is StandardMaterial3D:
		#return
	#
	#var chosen_color = Globals.car_colors[Globals.car_colors.keys().pick_random()]
	#var sel_material := material.duplicate()
	#sel_material.albedo_color = chosen_color
	#sel_mesh.surface_set_material(0, sel_material)
	#mesh.mesh = sel_mesh
#
#func change_engine_pitch():
	#if (not engine_player.playing) and engine_player.pitch_scale > 0.01:
		#engine_player.play()
	#var pitch = min(1, car_ref.linear_velocity.length()/ENGINE_SOUND_MAX_SPEED)
	#if pitch <= 0.01:
		#engine_player.stop()
	#if pitch>0.0:
		#engine_player.pitch_scale = pitch
#
#func set_head_light_energy(intensity:float):
	#for light:SpotLight3D in head_lights:
		#light.light_energy = intensity
#
#func toggle_head_lights():
	#for light:SpotLight3D in head_lights:
		#light.visible = !light.visible
#
#func toggle_rear_lights():
	#for light:SpotLight3D in back_lights:
		#light.visible = !light.visible
#
#func _ready()->void:
	#for mesh in randomize_color_meshes:
		#randomize_mesh_colors(mesh)
	#if car_ref and !car_ref.body_entered.is_connected(_on_collide):
		#car_ref.body_entered.connect(_on_collide)
	#context_ready()
#
#func context_ready()->void:
	#pass
#
#func _process(delta: float) -> void:
	#if car_ref:
		#change_engine_pitch()
	#context_process(delta)
#
#func context_process(_delta:float)->void:
	#pass
#
#
#func _on_collide(_body):
	#if abs(car_ref.linear_velocity.length() - car_ref.cur_lin_vel.length()) > 1 and !crash_player.playing:
		#crash_player.stream = Globals.crash_sounds[Globals.crash_sounds.keys().pick_random()]
		#crash_player.play()

extends BaseCosmetic
class_name ControlledCosmetic

@export var voice : AudioStreamPlayer
@export var wheel : Node3D
@export var speedometer_tick : MeshInstance3D

@export_subgroup("Radio")
@export var radio_on : bool = false
@export var radio : AudioStreamPlayer3D
var step : int = 1
var cur_index : int = 0
var cur_song : String = ""

var is_multiplayer: bool = false
var network_id = -1
var owner_steam_id = 0

func set_steam_owner(id):
	owner_steam_id = id

func _init():
	network_id = Globals.generate_network_id()
	Globals.register_node(self, network_id)

func context_ready()->void:
	if radio_on:
		radio.volume_db = -25

func context_process(_delta):
	pass

func update_wheel(value):
	wheel.rotation.z = value

func update_speedometer_tick(a,b):
	speedometer_tick.rotate_object_local(a,b)

func toggle_radio()->void:
	#toggle on and off
	if radio_on:
		radio.volume_db = -80
		radio_on = false
	else:
		radio.volume_db = -25
		radio_on = true

func change_frequency():
	if radio_on:
		radio.stop()
		_on_radio_finished()
		seek_random_position()

#go to next track
func _on_radio_finished() -> void:
	if !Globals.radio.keys().is_empty():
		Globals.radio.erase(Globals.radio.keys()[cur_index])
		Globals.load_random_song()
	if Globals.radio.keys().is_empty():
		return
	print("RADIO CHANGED")
	step = randi_range(1,Globals.radio.size())
	cur_index += step
	cur_index = cur_index%Globals.radio.size()
	print(Globals.radio.keys()[cur_index])
	radio.stream = Globals.radio[Globals.radio.keys()[cur_index]]
	radio.play()

# Function to seek to a random position in the audio stream
func seek_random_position():
	radio.stop()
	var stream_length = radio.get_stream().get_length()
	if stream_length > 0:
		
		var random_position = (randf_range(0,stream_length))
		radio.play(random_position)
		print("Seeking to position:", random_position)
	else:
		print("Stream length is zero or undefined.")


func play_voice():
	voice.stream = Globals.player_voice_lines[randi_range(2, Globals.player_voice_lines.size()-1)]
	voice.play()

@export_subgroup("COPS NODE")
var closest_cop : VehicleBody3D = null
@onready var label_3d: Label3D = $"../Cop_Detector/Label3D"

func update_cop_detector():
	if !car_ref.cop_node:
		return
	if car_ref.cop_node.get_child_count()<1:
		label_3d.text = tr("NONE_DETECTED_TEXT")
		closest_cop = null
		return
	var cur_distance = INF
	for cop in car_ref.cop_node.get_children():
		if !closest_cop:
			closest_cop = cop
			cur_distance = car_ref.global_position.distance_to(cop.global_position)
		if cur_distance>car_ref.global_position.distance_to(cop.global_position):
			closest_cop = cop
			cur_distance = car_ref.global_position.distance_to(cop.global_position)
	label_3d.text = str(roundi(cur_distance)) + "m"
	if cur_distance<=100:
		$"../Cop_Detector/Green/OmniLight3D".light_energy = 0
		$"../Cop_Detector/Red/OmniLight3D".light_energy = 0.2
	else:
		$"../Cop_Detector/Green/OmniLight3D".light_energy = 0.1
		$"../Cop_Detector/Red/OmniLight3D".light_energy = 0

func _ready()->void:
	# The base _ready() handles color randomization and collision signals.
	# We need to override this for multiplayer.
	if is_multiplayer:
		if GlobalSteam.is_steam_authority(owner_steam_id):
			# Host/owner decides the color and tells everyone else.
			var color = Globals.car_colors[Globals.car_colors.keys().pick_random()]
			Network.p2p_call_func(network_id, "set_car_color", [color])
			set_car_color(color) # Set for self
	else:
		# Original single-player logic
		for mesh in randomize_color_meshes:
			randomize_mesh_colors(mesh)

	if car_ref and !car_ref.body_entered.is_connected(_on_collide):
		car_ref.body_entered.connect(_on_collide)
	context_ready()

func set_car_color(color: Color):
	for mesh in randomize_color_meshes:
		if mesh == null or mesh.mesh == null:
			continue
		
		var original_mesh := mesh.mesh
		var sel_mesh := original_mesh.duplicate()
		
		if sel_mesh.get_surface_count() == 0:
			continue
		
		var material :StandardMaterial3D= sel_mesh.surface_get_material(0)
		if material == null or not material is StandardMaterial3D:
			continue
		
		var sel_material := material.duplicate()
		sel_material.albedo_color = color
		sel_mesh.surface_set_material(0, sel_material)
		mesh.mesh = sel_mesh

func toggle_head_lights():
	if is_multiplayer:
		if GlobalSteam.is_steam_authority(owner_steam_id):
			Network.p2p_call_func(network_id, "set_headlights_state", [!head_lights[0].visible])
			set_headlights_state(!head_lights[0].visible)
	else:
		# Original single-player logic
		for light:SpotLight3D in head_lights:
			light.visible = !light.visible

func set_headlights_state(is_visible: bool):
	for light:SpotLight3D in head_lights:
		light.visible = is_visible

func _on_collide(_body):
	var velocity_diff = abs(car_ref.linear_velocity.length() - car_ref.cur_lin_vel.length())
	if velocity_diff > 1 and !crash_player.playing:
		if is_multiplayer:
			if GlobalSteam.is_steam_authority(owner_steam_id):
				var sound_key = Globals.crash_sounds.keys().pick_random()
				Network.p2p_call_func(network_id, "play_crash_sound", [sound_key])
				play_crash_sound(sound_key)
		else:
			crash_player.stream = Globals.crash_sounds[Globals.crash_sounds.keys().pick_random()]
			crash_player.play()

func play_crash_sound(sound_key: String):
	if !crash_player.playing:
		crash_player.stream = Globals.crash_sounds[sound_key]
		crash_player.play()
