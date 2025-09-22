# NetworkManager.gd
extends Node

func _ready():
	# Connect to the network tick signal from the Globals node.
	# This assumes you have a global signal defined like: signal network_tick()
	Globals.network_tick.connect(_on_network_tick)
	Network.game_state_received.connect(on_game_state_received)

func _on_network_tick():
	# This function is called automatically on every network tick (e.g., 20 times per second).
	
	# Only the host is responsible for managing and broadcasting the game state.
	if Network.is_host:
		# 1. Collect the state from all registered network objects.
		var game_state = {}
		for id in Globals.network_registry:
			var node = Globals.get_node_by_id(id)
			# Ensure the node is valid and has the state function before calling it.
			if is_instance_valid(node) and node.has_method("get_network_state"):
				game_state[id] = node.get_network_state()

		# 2. Broadcast the collected state to all clients.
		# The Network.p2p_broadcast_game_state function will automatically send this
		# to everyone in the lobby except for the host itself.
		if not game_state.is_empty():
			Network.p2p_broadcast_game_state(game_state)

# This function will be called on clients when they receive a game state update from the host.
# We need to connect this to a signal from the Network.gd script.
func on_game_state_received(game_state: Dictionary):
	# Ensure we are not the host, as the host should not apply incoming state to itself.
	if not Network.is_host:
		for id_str in game_state:
			var id = int(id_str)
			var node = Globals.get_node_by_id(id)
			# Find the corresponding node in the client's world and apply the state.
			if is_instance_valid(node) and node.has_method("set_network_state"):
				node.set_network_state(game_state[id_str])
