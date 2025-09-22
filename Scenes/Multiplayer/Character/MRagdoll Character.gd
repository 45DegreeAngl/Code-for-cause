extends Node3D


# movement/walking/jumping stuff
const JUMP_STRENGTH = 70
const SPEED = 50
const DAMPING = 0.9
@onready var on_floor_left = $"Physical/Armature/Skeleton3D/Physical Bone LLeg2/OnFloorLeft" # shapecast on the feet to check if its on floor
@onready var on_floor_right = $"Physical/Armature/Skeleton3D/Physical Bone RLeg2/OnFloorRight" # shapecast on the feet to check if its on floor
@onready var jump_timer = $Physical/JumpTimer # timer to stop excidental double jump
var can_jump = true
var is_on_floor = false
var walking = false # if it is walking


# spring stuff
@export var angular_spring_stiffness: float = 4000.0
@export var angular_spring_damping: float = 80.0
@export var max_angular_force: float = 9999.0

var physics_bones = [] # all physical bones

# turn it into ragdoll
@export var ragdoll_mode := false


@onready var physical_skel : Skeleton3D = $Physical/Armature/Skeleton3D
@onready var animated_skel : Skeleton3D = $Animated/Armature/Skeleton3D
@onready var camera_pivot = $CameraPivot
@onready var animation_tree = $Animated/AnimationTree
@onready var physical_bone_body : PhysicalBone3D = $"Physical/Armature/Skeleton3D/Physical Bone Body"

# grabbing related stuff
var active_arm_left = false
var active_arm_right = false
var grabbed_object = null
var grabbing_arm_left = false
var grabbing_arm_right = false
@onready var grab_joint_right = $Physical/GrabJointRight
@onready var grab_joint_left = $Physical/GrabJointLeft
@onready var physical_bone_l_arm_2 = $"Physical/Armature/Skeleton3D/Physical Bone LArm2"
@onready var physical_bone_r_arm_2 = $"Physical/Armature/Skeleton3D/Physical Bone RArm2"
@onready var l_grab_area = $"Physical/Armature/Skeleton3D/Physical Bone LArm2/LGrabArea"
@onready var r_grab_area = $"Physical/Armature/Skeleton3D/Physical Bone RArm2/RGrabArea"

var left_hand = null
var right_hand = null

var current_delta:float

var network_id = -1
var is_authority = false
var owner_steam_id: int = 0

func _ready():
	# Assign a network ID and register the node
	network_id = Globals.generate_network_id()
	Globals.register_node(self, network_id)
		
	#physical_skel.physical_bones_start_simulation()# activate ragdoll
	physics_bones = physical_skel.get_children().filter(func(x): return x is PhysicalBone3D) # get all the physical bones
	
func set_steam_owner(id: int):
	owner_steam_id = id
	is_authority = GlobalSteam.is_steam_authority(owner_steam_id)
	camera_pivot.is_authority = is_authority

func _input(_event):
	if not is_authority: return # Non-authoritative clients don't process input

	if Globals.game_over or Globals.game_paused:
		return
	if Input.is_action_just_pressed("KEYWORD_MISC_INTERACT"): ragdoll_mode = bool(1-int(ragdoll_mode)) # toggle ragdoll mode

	active_arm_left = Input.is_action_pressed("KEYWORD_LEFT_HAND")# activate left arm with mouse left click
	active_arm_right = Input.is_action_pressed("KEYWORD_RIGHT_HAND")# activate right arm with mouse right click
	
	if (not active_arm_left and grabbing_arm_left) or ragdoll_mode:
		#release whatever the arm is holding when ragdoll mode or the arm is deactivate
		grabbing_arm_left = false
		grab_joint_left.node_a = NodePath()
		grab_joint_left.node_b = NodePath()
		
		left_hand = null
		
	if (not active_arm_right and grabbing_arm_right) or ragdoll_mode:
		#release whatever the arm is holding when ragdoll mode or the arm is deactivate
		grabbing_arm_right = false
		grab_joint_right.node_a = NodePath()
		grab_joint_right.node_b = NodePath()
		
		right_hand = null

func handle_input(input_dict: Dictionary):
	if not is_authority: return

	if input_dict.has("ragdoll_toggle"):
		ragdoll_mode = !ragdoll_mode
	
	active_arm_left = input_dict.get("left_hand", false)
	active_arm_right = input_dict.get("right_hand", false)

	# Handle releasing grabbed objects
	if (not active_arm_left and grabbing_arm_left) or ragdoll_mode:
		release_left()
	if (not active_arm_right and grabbing_arm_right) or ragdoll_mode:
		release_right()

	var dir = Vector3.ZERO
	if input_dict.get("forward", false):
		dir += animated_skel.global_transform.basis.z
	if input_dict.get("left", false):
		dir += animated_skel.global_transform.basis.x
	if input_dict.get("right", false):
		dir -= animated_skel.global_transform.basis.x
	if input_dict.get("backward", false):
		dir -= animated_skel.global_transform.basis.z
	
	walking = dir != Vector3.ZERO
	
	if input_dict.get("interact", false) and car_door:
		Network.p2p_call_func(car.network_id, "enter_car")
	elif input_dict.get("alt_interact", false) and flippable and !(left_hand == Globals.player_vehicle or right_hand == Globals.player_vehicle):
		Network.p2p_call_func(car.network_id, "flip_car")

	dir = dir.normalized()
	physical_bone_body.linear_velocity += dir * SPEED * current_delta
	physical_bone_body.linear_velocity *= Vector3(DAMPING, 1, DAMPING)

	if input_dict.get("jump", false):
		if is_on_floor and can_jump:
			physical_bone_body.linear_velocity.y += JUMP_STRENGTH
			jump_timer.start()
			can_jump = false

func enter_car_rpc():
	if car:
		car.enter_car()

func flip_car_rpc():
	if car:
		car.flip_car()

func release_left():
	grabbing_arm_left = false
	grab_joint_left.node_a = NodePath()
	grab_joint_left.node_b = NodePath()
	left_hand = null

func release_right():
	grabbing_arm_right = false
	grab_joint_right.node_a = NodePath()
	grab_joint_right.node_b = NodePath()
	right_hand = null

func _process(_delta):
	var r = clamp((camera_pivot.rotation.x*2)/(PI)*2.1,-1,1)
	if active_arm_left or active_arm_right:
		animation_tree.set("parameters/grab_dir/blend_position",r) # move the arms toward the direction you're looking at
	else:
		animation_tree.set("parameters/grab_dir/blend_position",0)

var car : Node3D = null
func set_car_door(value):
	car_door = value
var car_door = null

func _physics_process(delta):
	current_delta = delta

	if is_authority:
		var input_payload = {
			"ragdoll_toggle": Input.is_action_just_pressed("KEYWORD_MISC_INTERACT"),
			"left_hand": Input.is_action_pressed("KEYWORD_LEFT_HAND"),
			"right_hand": Input.is_action_pressed("KEYWORD_RIGHT_HAND"),
			"forward": Input.is_action_pressed("KEYWORD_FORWARD"),
			"left": Input.is_action_pressed("KEYWORD_LEFT"),
			"right": Input.is_action_pressed("KEYWORD_RIGHT"),
			"backward": Input.is_action_pressed("KEYWORD_BACKWARD"),
			"interact": Input.is_action_just_pressed("KEYWORD_INTERACT"),
			"alt_interact": Input.is_action_just_pressed("KEYWORD_ALT_INTERACT"),
			"jump": Input.is_action_pressed("KEYWORD_JUMP")
		}
		Network.p2p_send_input_to_host(input_payload)
	
	if not ragdoll_mode:# if not in ragdoll mode
		if Globals.game_over:
			ragdoll_mode = true
			return
		elif Globals.game_paused:
			return
		# walking control
		walking = false
		# This local input block will be removed
		# The logic is now in handle_input
		
		#check if is on floor
		is_on_floor = false
		if on_floor_left.is_colliding():
			for i in on_floor_left.get_collision_count():
				if on_floor_left.get_collision_normal(i).y > 0.5:
					is_on_floor = true
					break
		if not is_on_floor: 
			if on_floor_right.is_colliding():
				for i in on_floor_right.get_collision_count():
					if on_floor_right.get_collision_normal(i).y > 0.5:
						is_on_floor = true
						break
		
		#jump - This will be removed
		
		#play walking animation/idle
		if walking:animation_tree.set("parameters/walking/blend_amount",1)
		else:animation_tree.set("parameters/walking/blend_amount",0)

		#rotate the character toward the camera direction
		animated_skel.rotation.y = camera_pivot.rotation.y
# spring related function
func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)

func grab_object(arm: String, body_path_str: String):
	var body_path = NodePath(body_path_str)
	var body = get_node(body_path)
	if body is PhysicsBody3D and body.get_parent() != physical_skel:
		if arm == "right" and active_arm_right and not grabbing_arm_right:
			grabbing_arm_right = true
			grab_joint_right.global_position = r_grab_area.global_position
			grab_joint_right.node_a = physical_bone_r_arm_2.get_path()
			grab_joint_right.node_b = body.get_path()
			if body is RigidBody3D:
				right_hand = body
		elif arm == "left" and active_arm_left and not grabbing_arm_left:
			grabbing_arm_left = true
			grabbed_object = body
			grab_joint_left.global_position = l_grab_area.global_position
			grab_joint_left.node_a = physical_bone_l_arm_2.get_path()
			grab_joint_left.node_b = body.get_path()
			if body is RigidBody3D:
				left_hand = body

func _on_r_grab_area_body_entered(body:Node3D):
	if is_authority and body is PhysicsBody3D and body.get_parent() != physical_skel:
		if active_arm_right and not grabbing_arm_right:
			Network.p2p_call_func(network_id, "grab_object", ["right", str(body.get_path())])

func _on_l_grab_area_body_entered(body:Node3D):
	if is_authority and body is PhysicsBody3D and body.get_parent() != physical_skel:
		if active_arm_left and not grabbing_arm_left:
			Network.p2p_call_func(network_id, "grab_object", ["left", str(body.get_path())])

func _on_jump_timer_timeout():
	# jump timer to avoid spamming jump and then fly away
	can_jump = true

func get_network_state():
	return {
		"pos": global_transform.origin,
		"rot": global_transform.basis,
		"lin_vel": physical_bone_body.linear_velocity,
		"ang_vel": physical_bone_body.angular_velocity,
		"ragdoll": ragdoll_mode,
		"walking": walking,
		"anim_rot_y": animated_skel.rotation.y
	}

func set_network_state(state: Dictionary):
	if not is_authority:
		global_transform.origin = state.pos
		global_transform.basis = state.rot
		physical_bone_body.linear_velocity = state.lin_vel
		physical_bone_body.angular_velocity = state.ang_vel
		ragdoll_mode = state.ragdoll
		walking = state.walking
		animated_skel.rotation.y = state.anim_rot_y

func _on_skeleton_3d_skeleton_updated() -> void:
	if not ragdoll_mode:# if not in ragdoll mode
		# rotate the physical bones toward the animated bones rotations using hookes law
		for b:PhysicalBone3D in physics_bones:
			if not active_arm_left and b.name.contains("LArm"): continue # only rotated the arms if its activated
			if not active_arm_right and b.name.contains("RArm"): continue # only rotated the arms if its activated
			var target_transform: Transform3D = animated_skel.global_transform * animated_skel.get_bone_global_pose(b.get_bone_id())
			var current_transform: Transform3D = physical_skel.global_transform * physical_skel.get_bone_global_pose(b.get_bone_id())
			var rotation_difference: Basis = (target_transform.basis * current_transform.basis.inverse())
			var torque = hookes_law(rotation_difference.get_euler(), b.angular_velocity, angular_spring_stiffness, angular_spring_damping)
			torque = torque.limit_length(max_angular_force)
			
			b.angular_velocity += torque * current_delta
			
func set_flippable(val: bool):
	flippable = val
	if car:
		car.flip_car_option(flippable)

var flippable: bool = false
func _on_look_area_body_entered(body: Node3D) -> void:
	if is_authority and body == Globals.player_vehicle: 
		Network.p2p_call_func(network_id, "set_flippable", [true])

func _on_look_area_body_exited(body: Node3D) -> void:
	if is_authority and body == Globals.player_vehicle and flippable:
		Network.p2p_call_func(network_id, "set_flippable", [false])
