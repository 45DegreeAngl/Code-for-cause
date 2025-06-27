extends Node

signal lobby_changed()
signal lobby_left()

const PACKET_READ_LIMIT: int = 32

var is_host:bool = false
@onready var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 8

func _ready():
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.p2p_session_request.connect(_on_p2p_session_request)

func _process(_delta: float) -> void:
	if lobby_id>0:
		read_all_p2p_packets()

func create_lobby():
	if lobby_id==0:
		is_host=true
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC,lobby_members_max)
		print("LOBBY HAS BEEN CREATED")

signal lobby_created()

func _on_lobby_created(connecter:int,this_lobby_id:int):
	if connecter == 1:
		lobby_id = this_lobby_id
		print("Created a lobby: "+str(lobby_id))
	
		Steam.setLobbyJoinable(lobby_id,true)
		
		Steam.setLobbyData(lobby_id,"name",GlobalSteam.steam_username)
		Steam.setLobbyData(lobby_id,"max_player_count",str(lobby_members_max))
		
		var set_relay:bool = Steam.allowP2PPacketRelay(true)
		if set_relay:
			print("Set relay has been set")
		else:
			printerr("relay has not been set")
		lobby_changed.emit()
	lobby_created.emit()

signal player_left(change_id)
signal player_joined(change_id)

@warning_ignore("unused_parameter")
func _on_lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	# Get the user who has made the lobby change
	var changer_name: String = Steam.getFriendPersonaName(change_id)

	# If a player has joined the lobby
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("%s has joined the lobby: %s." % [changer_name,this_lobby_id])
		player_joined.emit(change_id)

	# Else if a player has left the lobby
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		print("%s has left the lobby." % changer_name)
		player_left.emit(change_id)

	# Else if a player has been kicked
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		print("%s has been kicked from the lobby." % changer_name)

	# Else if a player has been banned
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		print("%s has been banned from the lobby." % changer_name)

	# Else there was some unknown change
	else:
		print("%s did... something." % changer_name)

	# Update the lobby now that a change has occurred
	get_lobby_members()
	lobby_changed.emit()

signal lobby_joined()

func join_lobby(this_lobby_id:int):
	if lobby_id!=0:
		Steam.leaveLobby(lobby_id)
	lobby_members.clear()
	Steam.joinLobby(this_lobby_id)
	lobby_changed.emit()
	lobby_joined.emit()

func handle_lobby_leave():
	##for some reason when we go to leave, it either changes host or leaves, implement something to change this
	##change host if we leave
	change_host()
	await change_host_fin
	leave_lobby()

func leave_lobby():
	Steam.leaveLobby(lobby_id)
	lobby_id = 0
	for member in lobby_members:
		if member["steam_id"]!=GlobalSteam.steam_id:
			Steam.closeP2PSessionWithUser(member["steam_id"])
	lobby_members.clear()
	lobby_left.emit()

signal change_host_fin
func change_host(new_host:int = -69):
	if is_host:
		if new_host!=-69:
			p2p_set_host(new_host)
			await set_host_sent
			change_host_fin.emit()
			return
		else:
			for member in lobby_members:
				if member["steam_id"]!=GlobalSteam.steam_id:
					p2p_set_host(member["steam_id"])
					await set_host_sent
					change_host_fin.emit()
					return
	change_host_fin.emit()

func _on_lobby_joined(this_lobby_id:int,_permissions:int,_locked:int,response:int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		#print("Going from : "+str(lobby_id)+" to this: "+str(this_lobby_id))
		lobby_id = this_lobby_id
		
		get_lobby_members()
		
		make_p2p_handshake()
	else:
		printerr("Failed to join lobby. Response code: ",response)
	lobby_changed.emit()

func get_lobby_members():
	lobby_members.clear()
	
	var num_of_lobby_members:int = Steam.getNumLobbyMembers(lobby_id)
	
	for member in range(0,num_of_lobby_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id,member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)

		lobby_members.append({"steam_id":member_steam_id,"steam_name":member_steam_name})

func _on_p2p_session_request(remote_id:int):
	var _this_requester:String = Steam.getFriendPersonaName(remote_id)
	if lobby_members.has(remote_id):
		return
	#print(this_requester)

	Steam.acceptP2PSessionWithUser(remote_id)

func make_p2p_handshake():
	send_p2p_packet(0,{"message":"handshake","steam_id":GlobalSteam.steam_id,"username":GlobalSteam.steam_username})

func p2p_update_transform(objPath:NodePath,objPos,objRot,objScale):
	send_p2p_packet(0,{"transform":objPath,"position":objPos,"rotation":objRot,"scale":objScale},2)
##instantiate a node from file file_path:as a child of the pathDest:NodePath
##set no target to call the function for everyone, set target 0 to call function on everyone but yourself
func p2p_summon(filePath:String,pathDest:NodePath,target:int = -69):
	send_p2p_packet(target,{"summon":filePath,"destination":pathDest},2)
##set no target to call the function for everyone, set target 0 to call function on everyone but yourself
func p2p_summon_controller(filePath:String,pathDest:NodePath,multiplayer_authority,target:int = -69):
	send_p2p_packet(target,{"summon":filePath,"destination":pathDest,"multiplayer_authority":multiplayer_authority},2)

##set no target to call the function for everyone, set target 0 to call function on everyone but yourself
func p2p_reparent(pathDest:NodePath,pathObj:NodePath,keep_global:bool=false,target:int = -69):
	send_p2p_packet(target,{"destination":pathDest,"new_parent":pathObj,"kglobal":keep_global},2)
##calls function funcName:String on the node given by path funcHolder:NodePath with parameters with the callv function
##set no target to call the function for everyone, set target 0 to call function on everyone but yourself
func p2p_call_func(funcHolder:NodePath,funcName:String,parameters:Array=[],target:int = -69):
	send_p2p_packet(target,{"holder":funcHolder,"name":funcName,"parameters":parameters},2)
##set no target to call the function for everyone, set target 0 to call function on everyone but yourself
func p2p_change_value(varHolder:NodePath,varName:String,newVal,target:int = -69):
	send_p2p_packet(target,{"holder":varHolder,"name":varName,"value":newVal},2)

func p2p_send_voice_data(voice_data:Dictionary,target:int = 0):
	send_p2p_packet(target,{"voice":voice_data},2)

##set no target to call the function for everyone, set target 0 to call function on everyone but yourself
func p2p_delete(victPath:NodePath,target:int = -69):
	send_p2p_packet(target,{"victim":victPath},2)

func p2p_set_host(host_id:int):
	send_p2p_packet(-69,{"new_host":host_id},2)

func p2p_print(message:String,target:int=-69):
	send_p2p_packet(target,{"print_message":message},2)

func read_all_p2p_packets(read_count:int = 0):
	if read_count >= PACKET_READ_LIMIT:
		return

	if Steam.getAvailableP2PPacketSize(0)>0:
		read_p2p_packet()
		read_all_p2p_packets(read_count+1)

signal set_host_sent()

func send_p2p_packet(this_target:int,packet_data:Dictionary,send_type:int = 0):
	var channel:int = 0
	var this_data: PackedByteArray
	this_data.append_array(var_to_bytes(packet_data))
	
	if this_target == 0:#send to everyone except yourself
		if lobby_members.size()>1:
			for member in lobby_members:
				if member["steam_id"]!=GlobalSteam.steam_id:
					Steam.sendP2PPacket(member["steam_id"],this_data,send_type,channel)
	elif this_target == -69:#send to everyone including yourself (WIP)
		for member in lobby_members:
			Steam.sendP2PPacket(member["steam_id"],this_data,send_type,channel)
	else:#send to one person
		Steam.sendP2PPacket(this_target,this_data,send_type,channel)
	
	if packet_data.has("new_host"):
		set_host_sent.emit()

func read_p2p_packet():
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	
	if packet_size>0:
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size,0)
		
		var _packet_sender: int = this_packet["remote_steam_id"]
		
		var packet_code: PackedByteArray = this_packet["data"]
		var readable_data: Dictionary = bytes_to_var(packet_code)
		
		if readable_data.has("message"):
			match readable_data["message"]:
				"handshake":
					print("PLAYER: ",readable_data["username"]," HAS JOINED!!! From ",readable_data["steam_id"])
					get_lobby_members()
		elif readable_data.has("print_message"):
			print(readable_data["print_message"])
		elif readable_data.has("new_host"):
			is_host = GlobalSteam.steam_id == readable_data["new_host"]
			if is_host:
				p2p_print(str("I ",GlobalSteam.steam_username," am the host now"))
		elif readable_data.has("voice"):
			#pass
			print("Decompressed ",_packet_sender," voice: %s" % readable_data["voice"])
			SteamMic.process_voice_data(readable_data["voice"],"network")
			if SteamMic.lobby_voice_gens.has(int(_packet_sender)):
				print(SteamMic.lobby_voice_gens[_packet_sender])
				for prox_player in  SteamMic.lobby_voice_gens[_packet_sender]:
					#print("voice received")
					prox_player.process_voice_data(readable_data["voice"])
		elif readable_data.has("kick"):
			print("You were kicked from the lobby for ",readable_data["kick"])
			
		elif readable_data.has("destination"):
			if readable_data.has("summon"):
				var instanced : Node = ServerFunc.summon(readable_data["summon"],readable_data["destination"])
				if instanced and readable_data.has("multiplayer_authority"):
					instanced.steam_id = (int(readable_data["multiplayer_authority"]))
					if instanced.has_method("get_prox_player"):
						if !SteamMic.lobby_voice_gens.has(int(readable_data["multiplayer_authority"])):
							SteamMic.lobby_voice_gens[int(readable_data["multiplayer_authority"])] = []
						SteamMic.lobby_voice_gens[int(readable_data["multiplayer_authority"])].append(instanced.get_prox_player())
					if instanced.has_method("get_persona_name"):
						instanced.persona_name = Steam.getFriendPersonaName(instanced.steam_id)
				ServerFunc.summon_finish.emit()
			elif readable_data.has("new_parent"):
				ServerFunc.relocate(readable_data["destination"],readable_data["new_parent"],readable_data["kglobal"])
		elif readable_data.has("victim"):
			ServerFunc.delete(readable_data["victim"])
		##is node with variables and functions
		elif readable_data.has("holder"):
			if readable_data.has("value"):#call change_value
				ServerFunc.change_value(readable_data["holder"],readable_data["name"],readable_data["value"])
			elif readable_data.has("parameters"):#call call_function
				ServerFunc.call_function(readable_data["holder"],readable_data["name"],readable_data["parameters"])
