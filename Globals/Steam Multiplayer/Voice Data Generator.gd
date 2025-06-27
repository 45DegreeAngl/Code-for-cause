extends AudioStreamPlayer3D
class_name prox_voice_3d

var current_sample_rate: int = 48000
var playback: AudioStreamGeneratorPlayback = null
var voice_buffer: PackedByteArray = PackedByteArray()

func _ready():
	stream = AudioStreamGenerator.new()
	stream.mix_rate = current_sample_rate
	play()
	playback = get_stream_playback()

func get_sample_rate() -> void:
	current_sample_rate = Steam.getVoiceOptimalSampleRate()
	#print("Current sample rate: %s" % current_sample_rate)

signal is_talking()

func process_voice_data(voice_data: Dictionary) -> void:
	#print("processing data")
	# Our sample rate function above without toggling
	get_sample_rate()
	
	stream.mix_rate = current_sample_rate
	
	var decompressed_voice: Dictionary = Steam.decompressVoice(voice_data['buffer'], current_sample_rate)

	if decompressed_voice['result'] == Steam.VOICE_RESULT_OK and decompressed_voice['size'] > 0:
		
		#print("Decompressed voice: %s" % decompressed_voice['size'])

		voice_buffer = decompressed_voice['uncompressed']
		voice_buffer.resize(decompressed_voice['size'])

		# We now iterate through the local_voice_buffer and push the samples to the audio generator
		for i: int in range(0, mini(playback.get_frames_available() * 2, voice_buffer.size()), 2):
			# Steam's audio data is represented as 16-bit single channel PCM audio, so we need to convert it to amplitudes
			# Combine the low and high bits to get full 16-bit value
			var raw_value: int = voice_buffer[0] | (voice_buffer[1] << 8)
			# Make it a 16-bit signed integer
			raw_value = (raw_value + 32768) & 0xffff
			# Convert the 16-bit integer to a float on from -1 to 1
			var amplitude: float = float(raw_value - 32768) / 32768.0

			# push_frame() takes a Vector2. The x represents the left channel and the y represents the right channel
			playback.push_frame(Vector2(amplitude, amplitude))

			# Delete the used samples
			voice_buffer.remove_at(0)
			voice_buffer.remove_at(0)
			is_talking.emit()
