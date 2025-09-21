# Network.gd
extends Node

signal lobby_changed()
signal lobby_left()
signal image_received(image, sender_id)
signal player_left(change_id)
signal player_joined(change_id)
signal lobby_created()
signal lobby_joined()
signal change_host_fin
signal set_host_sent

const PACKET_READ_LIMIT: int = 32

var is_host: bool = false
var host_id: int = 0
@onready var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 8

func _ready():
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.p2p_session_request.connect(_on_p2p_session_request)

func _process(_delta: float):
	if lobby_id > 0:
		read_all_p2p_packets()

# --- LOBBY MANAGEMENT ---

func create_lobby():
	if lobby_id == 0:
		is_host = true
		host_id = GlobalSteam.steam_id
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_members_max)
		print("LOBBY HAS BEEN CREATED")

func _on_lobby_created(connecter: int, this_lobby_id: int):
	if connecter == 1:
		lobby_id = this_lobby_id
		host_id = GlobalSteam.steam_id
		Steam.setLobbyJoinable(lobby_id, true)
		Steam.setLobbyData(lobby_id, "name", GlobalSteam.steam_username)
		Steam.setLobbyData(lobby_id, "max_player_count", str(lobby_members_max))
		Steam.allowP2PPacketRelay(true)
		lobby_changed.emit()
	lobby_created.emit()

func join_lobby(this_lobby_id: int):
	if lobby_id != 0:
		Steam.leaveLobby(lobby_id)
	lobby_members.clear()
	Steam.joinLobby(this_lobby_id)
	lobby_changed.emit()
	lobby_joined.emit()

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: int, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		host_id = Steam.getLobbyOwner(lobby_id)
		get_lobby_members()
		make_p2p_handshake()
	else:
		printerr("Failed to join lobby. Response code: ", response)
	lobby_changed.emit()

func leave_lobby():
	if lobby_id == 0:
		return

	# If we are the host, we must pass ownership to someone else.
	if is_host and lobby_members.size() > 1:
		# Find the next available player to be the new host.
		var new_host_id = -1
		for member in lobby_members:
			if member["steam_id"] != GlobalSteam.steam_id:
				new_host_id = member["steam_id"]
				break
		
		# If a new host was found, transfer ownership.
		if new_host_id != -1:
			print("Passing host duties to: ", Steam.getFriendPersonaName(new_host_id))
			Steam.setLobbyOwner(lobby_id, new_host_id)

	# Leave the Steam lobby.
	Steam.leaveLobby(lobby_id)

	# Reset local variables.
	lobby_id = 0
	is_host = false
	host_id = 0
	lobby_members.clear()
	lobby_left.emit()

func handle_lobby_leave():
	# This function acts as a safe entry point for UI buttons.
	leave_lobby()

func change_host(new_host: int = -69):
	if is_host:
		var potential_host_id = -1
		if new_host != -69:
			potential_host_id = new_host
		else:
			for member in lobby_members:
				if member["steam_id"] != GlobalSteam.steam_id:
					potential_host_id = member["steam_id"]
					break
		
		if potential_host_id != -1:
			p2p_set_host(potential_host_id)
			await set_host_sent
	
	change_host_fin.emit()

# --- MEMBER & P2P SESSION MANAGEMENT ---

@warning_ignore("unused_parameter")
func _on_lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int):
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		player_joined.emit(change_id)
	elif chat_state in [Steam.CHAT_MEMBER_STATE_CHANGE_LEFT, Steam.CHAT_MEMBER_STATE_CHANGE_KICKED, Steam.CHAT_MEMBER_STATE_CHANGE_BANNED]:
		# Check if the person who left was the host.
		if change_id == host_id:
			# Get the new host from Steam and update our local state.
			host_id = Steam.getLobbyOwner(lobby_id)
			is_host = (host_id == GlobalSteam.steam_id)
			if is_host:
				print("The previous host left. I am the new host.")
			else:
				print("The host has changed to: ", Steam.getFriendPersonaName(host_id))
		
		player_left.emit(change_id)
	
	get_lobby_members()
	lobby_changed.emit()

func get_lobby_members():
	lobby_members.clear()
	var num_of_lobby_members: int = Steam.getNumLobbyMembers(lobby_id)
	for i in range(num_of_lobby_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, i)
		
		# --- THIS IS THE CHANGE ---
		# Fetch the name here, once, and store it with the ID.
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		
		lobby_members.append({
			"steam_id": member_steam_id,
			"steam_name": member_steam_name # Add the name to the dictionary
		})

# In Network.gd
func p2p_send_input_to_host(input_dict: Dictionary):
	if is_host:
		# If we are the host, process our own input directly
		ServerFunc.process_player_input(GlobalSteam.steam_id, input_dict)
	else:
		# If we are a client, send it to the host
		var packet = {"player_input": {"id": GlobalSteam.steam_id, "input": input_dict}}
		var data_bytes = var_to_bytes(packet)
		Steam.sendP2PPacket(host_id, data_bytes, Steam.P2P_SEND_UNRELIABLE, 0)

func _on_p2p_session_request(remote_id: int):
	Steam.acceptP2PSessionWithUser(remote_id)

# --- NEW P2P FUNCTIONS (REGISTRY-BASED) ---

func make_p2p_handshake():
	send_p2p_packet(0, {"handshake": {"id": GlobalSteam.steam_id, "name": GlobalSteam.steam_username}})

func p2p_summon(file_path: String, parent_identifier, target: int = -69):
	var packet = {"summon": {"path": file_path, "parent_id": parent_identifier}}
	send_p2p_packet(target, packet, Steam.P2P_SEND_RELIABLE)

func p2p_delete(victim_identifier, target: int = -69):
	var packet = {"delete": {"id": victim_identifier}}
	send_p2p_packet(target, packet, Steam.P2P_SEND_RELIABLE)

func p2p_call_func(object_identifier, func_name: String, params: Array = [], target: int = -69, send_type: int = Steam.P2P_SEND_RELIABLE):
	var packet = {"call_func": {"id": object_identifier, "func": func_name, "params": params}}
	send_p2p_packet(target, packet, send_type)

func p2p_change_value(object_id, var_name, new_val):
	var packet = {"change_value": {"id": object_id, "var": var_name, "val": new_val}}
	# This packet would be processed by _process_gameplay_packet and call ServerFunc.change_value
	send_p2p_packet(-69, packet, Steam.P2P_SEND_RELIABLE) 

func p2p_set_host(_host_id: int):
	send_p2p_packet(-69, {"new_host": _host_id}, Steam.P2P_SEND_RELIABLE)

func p2p_send_image(image: Image, target: int = 0):
	var packet_data = {"image_data": image.save_png_to_buffer()}
	send_p2p_packet(target, packet_data, Steam.P2P_SEND_RELIABLE)

func p2p_send_voice_data(voice_data: Dictionary, target: int = 0):
	send_p2p_packet(target, {"voice": voice_data}, Steam.P2P_SEND_UNRELIABLE)

func p2p_send_lobby_voice_data(voice_data: Dictionary):
	# We wrap it in a "lobby_voice" key to distinguish it from other packets.
	# Target 0 sends to everyone except ourselves.
	send_p2p_packet(0, {"lobby_voice": voice_data}, Steam.P2P_SEND_UNRELIABLE)

func p2p_print(message:String,target:int=-69):
	send_p2p_packet(target,{"print_message":message},Steam.P2P_SEND_RELIABLE)

func p2p_direct_state_update(object_identifier: int, func_name: String, params: Array = []):
	var packet = {"direct_update": {"id": object_identifier, "func": func_name, "params": params}}
	# Target 0 sends to everyone except self.
	send_p2p_packet(0, packet, Steam.P2P_SEND_UNRELIABLE)

func p2p_broadcast_game_state(state_dict: Dictionary):
	if not is_host: return # Only the host can do this
	
	var packet = {"game_state": state_dict}
	# Target 0 sends to everyone except self (the host).
	send_p2p_packet(0, packet, Steam.P2P_SEND_UNRELIABLE)

# --- P2P PACKET SENDING & READING ---

func send_p2p_packet(target: int, packet_data: Dictionary, send_type: int = Steam.P2P_SEND_UNRELIABLE):
	var data_bytes = var_to_bytes(packet_data)
	var targets = []
	if target == 0: # Everyone except self
		for member in lobby_members:
			if member["steam_id"] != GlobalSteam.steam_id:
				targets.append(member["steam_id"])
	elif target == -69: # Everyone including self
		for member in lobby_members:
			targets.append(member["steam_id"])
	else: # Specific person
		targets.append(target)

	for steam_id in targets:
		Steam.sendP2PPacket(steam_id, data_bytes, send_type, 0)
	
	if packet_data.has("new_host"):
		set_host_sent.emit()

func read_all_p2p_packets(read_count: int = 0):
	if read_count >= PACKET_READ_LIMIT: return
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_p2p_packet()
		read_all_p2p_packets(read_count + 1)

func read_p2p_packet():
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	if packet_size == 0: return
		
	var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 0)
	var packet_sender: int = this_packet["remote_steam_id"]
	var data: Dictionary = bytes_to_var(this_packet["data"])

	if data.has("direct_update"):
		var d = data["direct_update"]
		# Directly call the function without host validation.
		# This is for non-authoritative state like movement interpolation.
		ServerFunc.call_function(d["id"], d["func"], d["params"])
		return # Packet handled, we are done.

	var is_gameplay_packet = data.has("summon") or data.has("delete") or data.has("call_func")

	if is_gameplay_packet:
		# If I am the host, I am the authority and can process any gameplay packet.
		if is_host:
			_process_gameplay_packet(data)
		# If I am a client, I ONLY obey gameplay packets sent FROM the host.
		elif packet_sender == host_id:
			_process_gameplay_packet(data)
	else:
		_process_non_gameplay_packet(packet_sender, data)

func _process_gameplay_packet(data: Dictionary):
	if data.has("summon"):
		var d = data["summon"]
		ServerFunc.summon(d["path"], d["parent_id"])
	elif data.has("delete"):
		var d = data["delete"]
		ServerFunc.delete(d["id"])
	elif data.has("call_func"):
		var d = data["call_func"]
		ServerFunc.call_function(d["id"], d["func"], d["params"])

func _process_non_gameplay_packet(sender: int, data: Dictionary):
	if data.has("handshake"):
		print("Handshake from: ", data["handshake"]["name"])
		get_lobby_members()
	elif data.has("new_host"):
		host_id = data["new_host"]
		is_host = (GlobalSteam.steam_id == host_id)
		if is_host: print("I am the new host.")
	elif data.has("image_data"):
		var image = Image.new()
		if image.load_png_from_buffer(data["image_data"]) == OK:
			image_received.emit(image, sender)
	elif data.has("voice"):
		# This logic assumes you have a singleton named SteamMic.
		# Adjust if your voice manager has a different name.
		if Globals.has("steam_mic") and is_instance_valid(Globals.steam_mic):
			Globals.steam_mic.process_voice_data(data["voice"], "network")
