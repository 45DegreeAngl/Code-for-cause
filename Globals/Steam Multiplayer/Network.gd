extends Node

signal lobby_changed()
signal lobby_left()
signal image_received(image, sender_id)
signal player_left(change_id)
signal player_joined(change_id)
signal lobby_created_signal() # Renamed to avoid name conflict with Steam signal
signal lobby_joined_signal()

var is_host: bool = false
var host_id: int = 0
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 8

# NEW: The Steam Multiplayer Peer instance
var peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()

func _ready():
	Steam.initRelayNetworkAccess()
	# Steam Signals
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	
	# High-level Multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

# --- LOBBY MANAGEMENT ---

func create_lobby():
	if lobby_id == 0:
		Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC)
		is_host = true
		host_id = GlobalSteam.steam_id
		print("LOBBY CREATION INITIALIZED")

func _on_lobby_created(result: int, this_lobby_id: int):
	if result == 1:
		lobby_id = this_lobby_id
		
		peer = SteamMultiplayerPeer.new()
		#peer.server_relay = true
		peer.create_host()
		
		multiplayer.multiplayer_peer = peer
		
		Steam.setLobbyJoinable(lobby_id, true)
		Steam.setLobbyData(lobby_id, "name", GlobalSteam.steam_username)
		lobby_changed.emit()
	lobby_created_signal.emit()

func join_lobby(this_lobby_id: int):
	if lobby_id != 0:
		leave_lobby()
	
	# Connect as a client to a specific lobby ID
	var error = peer.connect_lobby(this_lobby_id)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		lobby_id = this_lobby_id
	else:
		printerr("Failed to initiate lobby join: ", error)

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: int, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		host_id = Steam.getLobbyOwner(lobby_id)
		get_lobby_members()
		lobby_joined_signal.emit()
	else:
		printerr("Failed to join lobby. Response code: ", response)
	lobby_changed.emit()

func leave_lobby():
	if lobby_id == 0: return
	
	peer.close() # Safely closes the peer and leaves the lobby
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	
	lobby_id = 0
	is_host = false
	lobby_members.clear()
	lobby_left.emit()

# --- HIGH-LEVEL RPC REPLACEMENTS ---

@rpc("any_peer", "call_remote", "unreliable")
func rpc_send_input(input_dict: Dictionary):
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		ServerFunc.process_player_input(sender_id, input_dict)

@rpc("authority", "call_remote", "reliable")
func rpc_summon(file_path: String, parent_id):
	ServerFunc.summon(file_path, parent_id)

@rpc("any_peer", "call_local", "reliable")
func rpc_send_image(image_data: PackedByteArray):
	var sender_id = multiplayer.get_remote_sender_id()
	var image = Image.new()
	if image.load_png_from_buffer(image_data) == OK:
		image_received.emit(image, sender_id)

# --- PEER HELPERS ---

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
	get_lobby_members()
