extends CharacterBody3D

@export_subgroup("Stats")
@export var speed:int = 300
@export var gravity:float = 100
@export var jump_height:int = 100
@export var mouse_sensitivity: float = 0.002

@export var neck:Node3D
@export var shirt:MeshInstance3D
@export var cam:Camera3D
@export var voice:AudioStreamPlayer3D
@export var mic:AudioStreamPlayer3D
@export var ray:RayCast3D

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

func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	# 1. Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("KEYWORD_PAUSE"):
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		move_and_slide()
		return
	
	#Interaction Logic
	var ray_col = ray.get_collider()
	if ray_col:
		if ray_col.has_method("attempt_enter") and Input.is_action_just_pressed("KEYWORD_INTERACT"):
			ray_col.attempt_enter(self)
			
			
	
	# 2. Movement Logic
	var in_vec: Vector2 = Input.get_vector("KEYWORD_LEFT", "KEYWORD_RIGHT", "KEYWORD_FORWARD", "KEYWORD_BACKWARD")
	
	# We use the neck's basis to determine direction.
	# This ensures "Forward" is always where the camera is looking.
	var direction: Vector3 = (neck.global_transform.basis * Vector3(in_vec.x, 0, in_vec.y))
	
	# Flatten the direction so the player doesn't "fly" or "dig" into the ground
	# when looking up or down while moving.
	direction.y = 0
	direction = direction.normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	if Input.is_action_just_pressed("KEYWORD_JUMP") and is_on_floor():
		velocity.y += jump_height
	
	move_and_slide()
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


@rpc("call_local","any_peer","reliable")
func set_shirt_color(col:Color):
	var shirt_material:StandardMaterial3D = shirt.mesh.material
	shirt_material.albedo_color = col
