extends Node3D

@export_subgroup("Stats")
@export var mouse_sensitivity: float = 0.002

@export var neck:Node3D
@export var cam:Camera3D
@export var voice:AudioStreamPlayer3D
@export var mic:AudioStreamPlayer3D

var effect : AudioEffectCapture
var playback : AudioStreamGeneratorPlayback

func _ready() -> void:
	if is_multiplayer_authority():
		cam.make_current()
		
		var idx = AudioServer.get_bus_index("Record")
		effect = AudioServer.get_bus_effect(idx,0)
		
		mic.play()
		
		#AudioServer.set_bus_layout(AudioServer.generate_bus_layout())
	if voice.stream is AudioStreamGenerator:
		voice.play()
		playback = voice.get_stream_playback()

func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("KEYWORD_PAUSE"):
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		return
	
	
	_capture_and_send_audio()

const CHUNK_SIZE = 512 

func _capture_and_send_audio():
	if effect:
		# 1. Check directly in the loop to avoid infinite loops
		while effect.get_frames_available() >= CHUNK_SIZE:
			var stereo_data = effect.get_buffer(CHUNK_SIZE)
			
			# 2. Optimization: Convert Stereo to Mono
			var mono_data = PackedFloat32Array()
			mono_data.resize(CHUNK_SIZE)
			for i in range(CHUNK_SIZE):
				mono_data[i] = (stereo_data[i].x + stereo_data[i].y) / 2.0
			
			# 3. Send via RPC (using "unreliable" for better performance)
			send_audio_data.rpc(mono_data)

@rpc("any_peer", "call_remote", "unreliable")
func send_audio_data(data: PackedFloat32Array):
	if playback:
		# Convert mono back to Vector2 for the AudioStreamGenerator
		var stereo_data = PackedVector2Array()
		stereo_data.resize(data.size())
		for i in range(data.size()):
			stereo_data[i] = Vector2(data[i], data[i])
			
		# Push to the buffer
		if playback.get_frames_available() >= stereo_data.size():
			playback.push_buffer(stereo_data)

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	
	
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index==MOUSE_BUTTON_LEFT and !Globals.game_over:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return
	
	if event is InputEventMouseMotion:
		# Rotate the whole body horizontally (Y axis)
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate the neck vertically (X axis) and clamp it so you can't flip over
		neck.rotate_x(-event.relative.y * mouse_sensitivity)
		neck.rotation.x = clamp(neck.rotation.x, deg_to_rad(-80), deg_to_rad(80))
