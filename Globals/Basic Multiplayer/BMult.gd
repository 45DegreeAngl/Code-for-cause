extends Node

# Signals for UI to connect to
signal player_list_changed
signal player_connected(id)
signal player_disconnected(id)
signal player_registered(id)
signal connection_failed
signal connection_succeeded
signal server_disconnected

const DEFAULT_PORT = 7000
const MAX_CLIENTS = 8

# Tracks all connected players: { peer_id: { "name": string, "score": int, ... } }
var lobby_members = {}
var local_player_data = {"name": "Player"}

func _ready():
	# Connect Godot's internal multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

## --- LOBBY ACTIONS ---

func host_game(player_name: String):
	local_player_data["name"] = player_name
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(DEFAULT_PORT, MAX_CLIENTS)
	
	if error != OK:
		print("Failed to host: ", error)
		return error
		
	multiplayer.multiplayer_peer = peer
	# The server is also a player (ID 1)
	_register_player(1, local_player_data)
	print("Hosting on port ", DEFAULT_PORT)
	return OK

func join_game(address: String, player_name: String):
	local_player_data["name"] = player_name
	if address.is_empty(): address = "127.0.0.1"
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, DEFAULT_PORT)
	
	if error != OK:
		return error
		
	multiplayer.multiplayer_peer = peer
	return OK

func leave_game():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	lobby_members.clear()
	player_list_changed.emit()

## --- INTERNAL CALLBACKS ---

# Called on everyone when a new peer connects
func _on_peer_connected(id: int):
	print("Peer connected: ", id)
	player_connected.emit(id)
	# If we are the server, we don't have the new player's data yet.
	# The client will "register" themselves via RPC shortly.

# Called on everyone when a peer leaves
func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)
	if lobby_members.has(id):
		lobby_members.erase(id)
		player_disconnected.emit(id)
		player_list_changed.emit()

# Called only on the client that just joined successfully
func _on_connected_to_server():
	print("Successfully connected to server!")
	connection_succeeded.emit()
	# Tell the server (and others) our info
	_register_player.rpc(multiplayer.get_unique_id(), local_player_data)

func _on_connection_failed():
	multiplayer.multiplayer_peer = null
	connection_failed.emit()

func _on_server_disconnected():
	lobby_members.clear()
	player_list_changed.emit() # UI updates while peer might still exist
	multiplayer.multiplayer_peer = null # Finally kill the connection
	server_disconnected.emit()

## --- DATA SYNCHRONIZATION ---

@rpc("any_peer", "call_local", "reliable")
func _register_player(id: int, data: Dictionary):
	lobby_members[id] = data
	player_registered.emit(id)
	player_list_changed.emit()
	
	# If I am the server, I need to make sure the NEW player 
	# knows about all the OLD players who were already here.
	if multiplayer.is_server():
		for existing_id in lobby_members:
			if existing_id != id: # Don't send the new guy his own data again
				_register_player.rpc_id(id, existing_id, lobby_members[existing_id])
