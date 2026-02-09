extends Control

# Mapping of PeerID -> LineEdit UI element
var mult_mapping: Dictionary[int, Control] = {}

@export var play_packed: PackedScene
@export var player_holder: VBoxContainer

@export var host_but: Button
@export var join_but: Button
@export var id_prompt: LineEdit
@export var leave_but: Button

func _ready():
	sync_lobby_ui()
	# Connect to the new BMult signals
	BMult.player_list_changed.connect(sync_lobby_ui)
	BMult.connection_failed.connect(_on_error)
	BMult.server_disconnected.connect(_on_error)
	
	$MultiplayerSpawner.spawn_function = m_spawn
	BMult.player_registered.connect(on_player_registered)
	BMult.player_disconnected.connect(remove_player_line)
	
	# Button setup
	host_but.pressed.connect(_on_host_pressed)
	join_but.pressed.connect(_on_join_pressed)


func _on_host_pressed():
	lose_focus()
	# Calling host_game from BMult (assuming a default name for debug)
	var err = BMult.host_game("Host_User")
	if err == OK:
		print("Lobby Created Successfully")

func _on_join_pressed():
	lose_focus()
	# id_prompt.text is used as the IP address or Lobby ID
	var address = id_prompt.text
	BMult.join_game(address, "Client_User")


func _on_leave_pressed() -> void:
	lose_focus()
	BMult.leave_game()
	_clear_all_ui()
	sync_lobby_ui()

func lose_focus():
	host_but.grab_focus()
	host_but.release_focus()

func on_player_registered(id:int):
	if not mult_mapping.has(id) and multiplayer.is_server():
		$MultiplayerSpawner.spawn({"name":"line","value":id})

func sync_lobby_ui():
	lose_focus()
	
	# If we aren't in a network session, just clear the UI and stop
	if multiplayer.multiplayer_peer == null:
		_clear_all_ui()

	# 1. Remove players who are no longer in the BMult.lobby_members
	#var current_ids = mult_mapping.keys()
	#for id in current_ids:
		#if not BMult.lobby_members.has(id):
			#remove_player_line(id)
	#
	## 2. Add players via Spawner (ONLY if we have authority/session)
	#for id in BMult.lobby_members:
		#if not mult_mapping.has(id):
			## Only the authority (server) should typically call spawn() 
			## unless you have configured the spawner otherwise.
			#if multiplayer.is_server():
				#$MultiplayerSpawner.spawn({"name":"line","value":id})
	
	leave_but.disabled = BMult.lobby_members.is_empty()
	host_but.disabled = not BMult.lobby_members.is_empty()

# Helper to clean up UI safely
func _clear_all_ui():
	for id in mult_mapping.keys():
		remove_player_line(id)
	mult_mapping.clear()

func m_spawn(data:Dictionary):
	if data.has("name"):
		match data["name"]:
			"line":
				return create_player_line(data["value"])

func create_player_line(id: int)->Node:
	if mult_mapping.has(id):
		return null
	var play_inst: LineEdit = play_packed.instantiate()
	# Set metadata
	play_inst.name = str(id)
	play_inst.placeholder_text = "Peer ID: " + str(id)
	
	# Add to mapping
	mult_mapping[id] = play_inst
	
	# Set network authority so the specific peer controls this node if needed
	play_inst.set_multiplayer_authority(id)
	
	return play_inst

func remove_player_line(id: int):
	if mult_mapping.has(id):
		var node = mult_mapping[id]
		if is_instance_valid(node):
			node.queue_free()
		mult_mapping.erase(id)

func _on_error():
	# Clear the UI if connection drops
	for id in mult_mapping.keys():
		remove_player_line(id)
	print("Disconnected or Connection Failed")

func _on_id_prompt_text_changed(new_text: String) -> void:
	# Keep join button disabled if no address/ID is entered
	join_but.disabled = new_text.is_empty()

func _on_ping_pressed() -> void:
	_rpc_play_test_audio.rpc(multiplayer.get_unique_id())

@rpc("any_peer","reliable")
func _rpc_play_test_audio(id:int):
	print("PINGED BY : ",str(id))
	$AudioStreamPlayer.play()
