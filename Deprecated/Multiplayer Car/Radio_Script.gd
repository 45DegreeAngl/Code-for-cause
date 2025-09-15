extends AudioStreamPlayer3D
class_name RadioPlayer

@export var radio_on : bool = false

var step : int = 1
var cur_index : int = 0
var cur_song : String = ""

func _ready() -> void:
	if radio_on:
		$Sounds/Radio.volume_db = -25

func toggle_radio()->void:
	#toggle on and off
	if radio_on:
		$Sounds/Radio.volume_db = -80
		radio_on = false
	else:
		$Sounds/Radio.volume_db = -25
		radio_on = true

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
	$Sounds/Radio.stream = Globals.radio[Globals.radio.keys()[cur_index]]
	$Sounds/Radio.play()

func find_new_song():
	if radio_on:
		$Sounds/Radio.stop()
		_on_radio_finished()
		seek_random_position()

# Function to seek to a random position in the audio stream
func seek_random_position():
	$Sounds/Radio.stop()
	var stream_length = $Sounds/Radio.get_stream().get_length()
	if stream_length > 0:
		
		var random_position = (randf_range(0,stream_length))
		$Sounds/Radio.play(random_position)
		print("Seeking to position:", random_position)
	else:
		print("Stream length is zero or undefined.")
