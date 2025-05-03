extends Node3D

@export var target_node: Node3D# target position (to follow the character)

@export var mouse_sensitivity = 0.1# camera rotation speed
@export var controller_sensitivity = 4

@export var physical_skel:Skeleton3D# character physical skeleton

@onready var spring_arm = $SpringArm3D



func _physics_process(delta):
	for child in physical_skel.get_children():
		# prevent the camera from clipping into the character
		if child is PhysicalBone3D:spring_arm.add_excluded_object(child.get_rid())
	
	if joy_pad_RStick:
		rotation_degrees.y -= Globals.per_cont_sens*joy_pad_RStick.x*delta*25
		rotation_degrees.x -= Globals.per_cont_sens*joy_pad_RStick.y*delta*25
		rotation_degrees.x = clamp(rotation_degrees.x,-45,45)
	
	if target_node != null:
		# lerp position to the target position
		global_position = lerp(global_position,target_node.global_position,0.5)

var joy_pad_RStick : Vector2 = Vector2.ZERO

func _input(event):
	if Globals.game_paused or Globals.game_over:
		return
	# mouse lock
	if Input.is_action_just_pressed("KEYWORD_PAUSE"):
		
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.is_pressed():
		
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	#rotate camera
	if event is InputEventMouseMotion and !Globals.game_paused:
		rotation_degrees.y -= Globals.per_mous_sens*event.relative.x
		rotation_degrees.x -= Globals.per_mous_sens*event.relative.y
		rotation_degrees.x = clamp(rotation_degrees.x,-45,45)
	elif event is InputEventJoypadMotion:
		match event.axis:
			2:
				joy_pad_RStick.x = event.axis_value
			3:
				joy_pad_RStick.y = event.axis_value
		
