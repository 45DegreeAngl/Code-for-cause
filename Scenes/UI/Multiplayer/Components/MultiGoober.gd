extends CharacterBody3D

@export_subgroup("Stats")
@export var speed:int = 300
@export var gravity:float = 100
@export var jump_height:int = 100
@export var mouse_sensitivity: float = 0.002

@export var neck:Node3D
@export var shirt:MeshInstance3D
@export var cam:Camera3D

func _ready() -> void:
	if is_multiplayer_authority():
		cam.make_current()

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
