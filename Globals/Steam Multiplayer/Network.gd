# Network.gd
extends Node

# --- SIGNALS ---
signal lobby_changed()
signal lobby_left()
signal player_left(change_id)
signal player_joined(change_id)
signal lobby_created_signal() 
signal lobby_joined_signal()

# --- VARIABLES ---
var is_host: bool = false
var is_joining:bool = false
var host_id: int = 0
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 8

const DUPLICATES:bool = true

# The Steam Multiplayer Peer instance
var peer: SteamMultiplayerPeer

func _ready():
	# Initializes Steam's networking relay system
	Steam.initRelayNetworkAccess()
	
	# Steam Signals
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	
	# High-level Multiplayer signals (Godot's internal networking)
	#multiplayer.peer_connected.connect(_on_peer_connected)
	#multiplayer.peer_disconnected.connect(_on_peer_disconnected)

# --- LOBBY MANAGEMENT ---

##creates the lobby and hosts it
func host_lobby():
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC,lobby_members_max)
	is_host = true

func _on_lobby_created(result: int, this_lobby_id: int):
	if result == Steam.Result.RESULT_OK:
		lobby_id = this_lobby_id
		
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		_on_peer_connected()
		lobby_created_signal.emit()

func join_lobby(this_lobby_id: int):
	is_joining = true
	Steam.joinLobby(this_lobby_id)

@warning_ignore("unused_parameter")
func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: int, response: int):
	if not is_joining:
		return
	
	lobby_id = this_lobby_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobby_id))
	multiplayer.multiplayer_peer = peer
	
	lobby_joined_signal.emit()
	is_joining = false

func leave_lobby():
	
	lobby_left.emit()
	pass

func handle_lobby_leave():
	pass

# --- MEMBER HELPERS ---

func _on_peer_connected(id: int = 1):
	lobby_members.append(id)
	player_joined.emit(id)
	lobby_changed.emit()

func _on_peer_disconnected(id: int):
	lobby_members.erase(id)
	player_left.emit(id)
	lobby_changed.emit()

func get_lobby_members():
	pass

@warning_ignore("unused_parameter")
func _on_lobby_chat_update(_lobby_id: int, change_id: int, _making_change_id: int, chat_state: int):
	pass
