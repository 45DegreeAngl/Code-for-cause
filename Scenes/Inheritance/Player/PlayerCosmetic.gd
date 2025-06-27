extends BaseCosmetic
class_name PlayerCosmetic

@export var voice : AudioStreamPlayer
@export var wheel : Node3D
@export var speedometer_tick : MeshInstance3D

@export_subgroup("Radio")
@export var radio_on : bool = false
@export var radio : AudioStreamPlayer3D
var step : int = 1
var cur_index : int = 0
var cur_song : String = ""

func context_ready()->void:
	if radio_on:
		radio.volume_db = -25

func context_process(delta):
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
