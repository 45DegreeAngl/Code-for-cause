extends Node

@export var spawn_points: Array[Node3D]
@export var player_car_scene: PackedScene

var player_cars: Dictionary = {} # { steam_id: car_node }

func _ready():
	Globals.register_static_node("player_manager", self)
	Network.player_left.connect(_on_player_left)

func spawn_players_for_lobby(lobby_members: Array):
	if not Network.is_host: return

	for i in range(min(lobby_members.size(), spawn_points.size())):
		var player_id = lobby_members[i]["steam_id"]
		var spawn_transform = spawn_points[i].global_transform
		
		# This function will be executed on the host and broadcast to all clients.
		# There is no need to call spawn_player_car_rpc directly on the host.
		Network.p2p_call_func("player_manager", "spawn_player_car_rpc", [player_id, spawn_transform])

func spawn_player_car_rpc(player_id: int, spawn_transform: Transform3D):
	# Prevent spawning a car for a player who already has one.
	if player_cars.has(player_id):
		return

	if not is_instance_valid(player_car_scene):
		printerr("Player car scene is not set in PlayerManager!")
		return

	var car = player_car_scene.instantiate()
	get_tree().root.add_child(car)
	car.global_transform = spawn_transform
	
	car.is_multiplayer = true
	car.set_steam_owner(player_id)
	
	player_cars[player_id] = car
	print("Spawned car for player %s" % Steam.getFriendPersonaName(player_id))

func remove_player_car(player_id: int):
	if Network.is_host:
		# The host calls the RPC for itself and all clients.
		Network.p2p_call_func("player_manager", "remove_player_car_rpc", [player_id])

func remove_player_car_rpc(player_id: int):
	if player_cars.has(player_id):
		var car = player_cars[player_id]
		if is_instance_valid(car):
			car.queue_free()
		player_cars.erase(player_id)
		print("Removed car for player %s" % Steam.getFriendPersonaName(player_id))

func _on_player_left(player_id: int):
	if Network.is_host:
		remove_player_car(player_id)
