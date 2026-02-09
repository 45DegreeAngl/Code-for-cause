extends Node

# --- State Management ---
# We use an enum to clearly define the current chat mode.
enum VoiceMode { LOBBY, GAME }
var current_voice_mode: VoiceMode = VoiceMode.LOBBY

# --- Configuration ---
# Set to true for Voice Activated Detection (VAD), false for Push-to-Talk (PTT).
var use_voice_activation: bool = false
# Set to true to hear your own microphone for testing purposes.
var has_loopback: bool = true

# This signal is emitted ONLY in GAME mode for the PlayerManager to handle proximity chat.
signal voice_data_captured(voice_data)

# --- Internal Variables ---
var current_sample_rate: int = 48000
var local_playback: AudioStreamGeneratorPlayback = null
var local_voice_buffer: PackedByteArray = PackedByteArray()
var network_playback: AudioStreamGeneratorPlayback = null
var network_voice_buffer: PackedByteArray = PackedByteArray()


func _ready() -> void:
	# Register as a global static node for easy access from other scripts.
	Globals.register_static_node("steam_mic", self)

	# Set up the audio player for local mic loopback.
	$Local.stream.mix_rate = current_sample_rate
	$Local.play()
	local_playback = $Local.get_stream_playback()

	# Set up the non-3D audio player for global lobby chat.
	$Network.stream.mix_rate = current_sample_rate
	$Network.play()
	network_playback = $Network.get_stream_playback()

	# If using Voice Activation, start recording immediately.
	if use_voice_activation:
		record_voice(true)


# --- Centralized Input ---
# This script now handles the input, not the player controller.
func _unhandled_input(event):
	# Push-to-Talk is ignored if Voice Activation is enabled.
	if use_voice_activation:
		return

	if event.is_action_pressed("push2talk"):
		record_voice(true)
	
	if event.is_action_released("push2talk"):
		record_voice(false)


func _process(_delta: float) -> void:
	if !GlobalSteam.is_online:
		return
	#check_for_voice()


# --- Core Logic ---

# This function is called by other scripts (like PlayerManager or UI) to change the chat behavior.
func set_voice_mode(mode: String):
	if mode == "lobby":
		current_voice_mode = VoiceMode.LOBBY
		print("Voice Chat: Switched to Lobby Mode (Global)")
	elif mode == "game":
		current_voice_mode = VoiceMode.GAME
		print("Voice Chat: Switched to Game Mode (Proximity)")


# Captures voice from Steam and routes it based on the current mode.
func check_for_voice() -> void:
	var available_voice: Dictionary #= Steam.getAvailableVoice()

	if available_voice['result'] == Steam.VOICE_RESULT_OK and available_voice['buffer'] > 0:
		var voice_data: Dictionary = Steam.getVoice()
		if voice_data['result'] == Steam.VOICE_RESULT_OK and voice_data['written']:
			
			# Route data based on the current mode
			if current_voice_mode == VoiceMode.LOBBY:
				# In the lobby, send a generic voice packet for global playback.
				Network.p2p_send_lobby_voice_data(voice_data)
			elif current_voice_mode == VoiceMode.GAME:
				# In-game, emit the signal for PlayerManager to handle proximity chat.
				voice_data_captured.emit(voice_data)

			# If loopback is enabled, play our own voice back to ourselves.
			if has_loopback:
				process_local_loopback(voice_data)


# Plays incoming voice data from the lobby through the non-3D $Network player.
func process_lobby_voice_data(voice_data: Dictionary) -> void:
	get_sample_rate()
	$Network.stream.mix_rate = current_sample_rate
	
	var decompressed_voice: Dictionary = Steam.decompressVoice(voice_data['buffer'], current_sample_rate)

	if decompressed_voice['result'] == Steam.VOICE_RESULT_OK and decompressed_voice['size'] > 0:
		network_voice_buffer = decompressed_voice['uncompressed']
		network_voice_buffer.resize(decompressed_voice['size'])
		
		for i: int in range(0, mini(network_playback.get_frames_available() * 2, network_voice_buffer.size()), 2):
			var raw_value: int = network_voice_buffer[0] | (network_voice_buffer[1] << 8)
			raw_value = (raw_value + 32768) & 0xffff
			var amplitude: float = float(raw_value - 32768) / 32768.0
			network_playback.push_frame(Vector2(amplitude, amplitude))
			network_voice_buffer.remove_at(0)
			network_voice_buffer.remove_at(0)


# Plays the user's own voice back through the $Local player for testing.
func process_local_loopback(voice_data: Dictionary) -> void:
	get_sample_rate()
	$Local.stream.mix_rate = current_sample_rate
	
	var decompressed_voice: Dictionary = Steam.decompressVoice(voice_data['buffer'], current_sample_rate)

	if decompressed_voice['result'] == Steam.VOICE_RESULT_OK and decompressed_voice['size'] > 0:
		local_voice_buffer = decompressed_voice['uncompressed']
		local_voice_buffer.resize(decompressed_voice['size'])

		for i: int in range(0, mini(local_playback.get_frames_available() * 2, local_voice_buffer.size()), 2):
			var raw_value: int = local_voice_buffer[0] | (local_voice_buffer[1] << 8)
			raw_value = (raw_value + 32768) & 0xffff
			var amplitude: float = float(raw_value - 32768) / 32768.0
			local_playback.push_frame(Vector2(amplitude, amplitude))
			local_voice_buffer.remove_at(0)
			local_voice_buffer.remove_at(0)


# --- Steam API Control ---

# Tells Steam when the user is actively speaking.
func record_voice(is_recording: bool) -> void:
	# This helps with the Steam Overlay UI, showing who is talking.
	Steam.setInGameVoiceSpeaking(GlobalSteam.steam_id, is_recording)

	if is_recording:
		Steam.startVoiceRecording()
	else:
		Steam.stopVoiceRecording()


# Gets the optimal sample rate for voice chat from Steam.
func get_sample_rate() -> void:
	current_sample_rate = Steam.getVoiceOptimalSampleRate()
