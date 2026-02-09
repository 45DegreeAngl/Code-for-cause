extends BaseCar

var spawned_passengers:Dictionary[int,Node3D] = {}

@export var players_node:Node3D
@export var pass_packed:PackedScene
@export var m_spawner:MultiplayerSpawner
##The First element of the array is the node to reference here
##The Second is the marker where the player goes
##The Third is the exit area
##The Fourth is the exit marker
#@export var car_contents:Dictionary[String,Array] ={
	#"Driver":[null,$"",$"",$""],
	#"Passenger":[null,$"",$"",$""],
	#"Back Seat 1":[null,$"",$"",$""],
	#"Back Seat 2":[null,$"",$"",$""],
	#"Back Seat 3":[null,$"",$"",$""],
	#"Trunk 1":[null,$"",$"",$""],
	#"Trunk 2":[null,$"",$"",$""],
	#"Trunk 3":[null,$"",$"",$""]
#}
@export var seat_node:Node3D
##first child is the driver, then passenger, seats, trunk
var seat_markers:Array[Marker3D]
@export var exit_seat_node:Node3D
var exit_markers:Array[Marker3D]

func _ready() -> void:
	for child:Marker3D in seat_node.get_children():
		seat_markers.append(child)
	m_spawner.spawn_function = m_spawn
	BMult.player_disconnected.connect(_on_player_disconnect)

var driver:Node
func update_steer(delta):
	if driver and driver.is_multiplayer_authority():
		steering = move_toward(steering,Input.get_axis("KEYWORD_RIGHT","KEYWORD_LEFT") * get_max_steer(),delta*2.5)
		var forward_axis = Input.get_axis("KEYWORD_BACKWARD","KEYWORD_FORWARD")
		engine_force = max(forward_axis * ENGINE_POWER,-ENGINE_POWER/1.5)

func attempt_enter(node:Node):
	enter_car.rpc(node.get_multiplayer_authority())
	
	# Important: The original player node is removed
	node.queue_free()

@rpc("any_peer","call_local","reliable",1)
func enter_car(id:int):
	var seat_index: int = -1
	# Find the first empty seat and get its index
	for i in range(seat_markers.size()):
		if seat_markers[i].get_child_count() == 0:
			seat_index = i
			break
	
	if seat_index == -1:
		print("Car is full!")
		return

	var spawn_data: Dictionary = {
		"type": "passenger",
		"id": id,
		"seat_idx": seat_index
	}
	
	# The spawner handles the creation across the network
	var new_pass: Node3D = m_spawner.spawn(spawn_data)
	
	if new_pass:
		if spawn_data["seat_idx"] == 0:
			driver = new_pass
		
		if seat_markers.get(seat_index):
			new_pass.global_position = seat_markers.get(seat_index).global_position
	
	

func m_spawn(data: Dictionary) -> Node:
	if data.get("type") == "passenger":
		var id = data["id"]
		var seat_idx = data["seat_idx"]
		
		var new_goob = create_passenger(id)
		
		# Put the passenger in the seat BEFORE returning it
		# This ensures the transform is synced relative to the seat
		#var seat_node = seat_markers[seat_idx]
		#seat_node.add_child(new_goob)
		
		if seat_idx == 0:
			driver = new_goob
			
		return new_goob
	return null

func create_passenger(id: int) -> Node3D:
	var pass_inst: Node3D = pass_packed.instantiate()
	pass_inst.name = str(id)
	spawned_passengers[id] = pass_inst
	
	# Set authority so the specific player can still move their head/talk
	pass_inst.set_multiplayer_authority(id)
	
	# Enable process if it's the authority so they can look around
	if id == multiplayer.get_unique_id():
		pass_inst.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		pass_inst.process_mode = Node.PROCESS_MODE_INHERIT # Or keep custom logic
		
	return pass_inst

func _on_player_disconnect(id:int):
	if spawned_passengers.has(id):
		var node = spawned_passengers[id]
		if is_instance_valid(node):
			node.queue_free()
		spawned_passengers.erase(id)
