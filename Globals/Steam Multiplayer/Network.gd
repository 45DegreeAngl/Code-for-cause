# Network.gd
extends Node

# --- SIGNALS ---
signal lobby_changed()
signal lobby_left()
signal image_received(image, sender_id)
signal player_left(change_id)
signal player_joined(change_id)
signal lobby_created_signal() 
signal lobby_joined_signal()

# --- VARIABLES ---
var is_host: bool = false
var host_id: int = 0
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 8

const DUPLICATES:bool = true

# The Steam Multiplayer Peer instance
var peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()

func _ready():
	# Initializes Steam's networking relay system
	Steam.initRelayNetworkAccess()
	
	# Steam Signals
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	
	# High-level Multiplayer signals (Godot's internal networking)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

# --- LOBBY MANAGEMENT ---

func create_lobby():
	if lobby_id == 0:
		# Step 1: Use the Steam singleton to create the social room
		Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, lobby_members_max)
		is_host = true
		print("LOBBY CREATION INITIALIZED")

func _on_lobby_created(result: int, this_lobby_id: int):
	# result == 1 is SUCCESS for Steam
	if result == Steam.Result.RESULT_OK:
		lobby_id = this_lobby_id
		
		
		# Step 2: Initialize the Peer as a Host
		# This binds the Godot Multiplayer API to the Steam Relay
		var error = peer.create_host()
		if error != OK:
			printerr("Failed to create host peer: ", error)
			return
			
		multiplayer.multiplayer_peer = peer
		
		is_host = true
		host_id = GlobalSteam.steam_id
		
		# Step 3: Set metadata so the Lobby Browser script can find this lobby
		Steam.setLobbyJoinable(lobby_id, true)
		Steam.setLobbyData(lobby_id, "name", str(GlobalSteam.steam_username) + "'s Lobby")
		Steam.setLobbyData(lobby_id, "max_player_count", str(lobby_members_max))
		
		print("Lobby created and Hosting. ID: ", lobby_id)
		lobby_changed.emit()
	else:
		printerr("Steam failed to create lobby. Result code: ", result)
		
	lobby_created_signal.emit()

func join_lobby(this_lobby_id: int):
	if lobby_id != 0:
		leave_lobby()
	
	# Step 4: Clients use connect_lobby to join the data stream
	var error = peer.connect_to_lobby(this_lobby_id)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		lobby_id = this_lobby_id
		is_host = false
		print("Peer connecting to lobby: ", this_lobby_id)
	else:
		printerr("Failed to initiate connect_lobby: ", error)

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: int, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		host_id = Steam.getLobbyOwner(lobby_id)
		get_lobby_members()
		lobby_joined_signal.emit()
		print("Successfully joined Steam lobby.")
	else:
		printerr("Failed to join lobby. Response code: ", response)
	
	lobby_changed.emit()

func leave_lobby():
	if lobby_id == 0: return
	
	peer.close() # Closes P2P sessions and leaves the Steam lobby
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	
	lobby_id = 0
	is_host = false
	host_id = 0
	lobby_members.clear()
	lobby_left.emit()

func handle_lobby_leave():
	leave_lobby()

# --- HIGH-LEVEL RPCs ---
# Call these using .rpc() from other scripts

@rpc("any_peer", "call_remote", "unreliable")
func rpc_send_input(input_dict: Dictionary):
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		if has_node("/root/ServerFunc"):
			get_node("/root/ServerFunc").process_player_input(sender_id, input_dict)

@rpc("authority", "call_remote", "reliable")
func rpc_summon(file_path: String, parent_id):
	if has_node("/root/ServerFunc"):
		get_node("/root/ServerFunc").summon(file_path, parent_id)

@rpc("any_peer", "call_local", "reliable")
func rpc_send_image(image_data: PackedByteArray):
	var sender_id = multiplayer.get_remote_sender_id()
	var image = Image.new()
	if image.load_png_from_buffer(image_data) == OK:
		image_received.emit(image, sender_id)

# --- MEMBER HELPERS ---

func _on_peer_connected(id: int):
	print("Peer connected to Godot Multiplayer: ", id)
	get_lobby_members()

func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)
	player_left.emit(id)
	get_lobby_members()

func get_lobby_members():
	lobby_members.clear()
	var num_of_lobby_members: int = Steam.getNumLobbyMembers(lobby_id)
	for i in range(num_of_lobby_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, i)
		lobby_members.append({
			"steam_id": member_steam_id,
			"steam_name": Steam.getFriendPersonaName(member_steam_id)
		})
	lobby_changed.emit()

func _on_lobby_chat_update(_lobby_id: int, change_id: int, _making_change_id: int, chat_state: int):
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		player_joined.emit(change_id)
	elif chat_state in [Steam.CHAT_MEMBER_STATE_CHANGE_LEFT, Steam.CHAT_MEMBER_STATE_CHANGE_KICKED]:
		player_left.emit(change_id)
	
	get_lobby_members()
