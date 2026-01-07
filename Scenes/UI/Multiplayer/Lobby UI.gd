extends Control

@export var lobbies_elem_container:VBoxContainer
@export var current_lobby_elem_container:VBoxContainer
@onready var lobbies_count: Label = $"HSplitContainer/Lobbies Container/Lobbies count"
@onready var member_count: Label = $"HSplitContainer/Current Lobby Container/Members count"

func _ready() -> void:
	# Connect to the updated signal names from our Network script
	Network.lobby_left.connect(_on_leave)
	Network.lobby_changed.connect(update_players)
	Network.lobby_created_signal.connect(_on_lobby_created_success)
	Network.lobby_joined_signal.connect(_on_lobby_joined)
	
	# Steam search result signal
	Steam.lobby_match_list.connect(create_lobby_entries)

# --- HOSTING ---

func _on_host_pressed() -> void:
	# Network.create_lobby now triggers peer initialization
	Network.create_lobby()

func _on_lobby_created_success() -> void:
	
	# UI updates once we know the lobby actually exists
	$"HSplitContainer/Current Lobby Container/Leave Lobby".disabled = false
	$"HSplitContainer/Current Lobby Container/Host".disabled = true
	update_players()
	# Set initial visibility/type
	_on_lobby_options_item_selected($"HSplitContainer/Current Lobby Container/Lobby Options".selected)

# --- JOINING ---

func _on_lobby_joined():
	# UI updates for clients
	$"HSplitContainer/Current Lobby Container/Host".disabled = true
	$"HSplitContainer/Current Lobby Container/Lobby Options".disabled = true
	$"HSplitContainer/Current Lobby Container/Leave Lobby".disabled = false
	update_players()

# --- LOBBY SETTINGS ---

func _on_lobby_options_item_selected(index: int) -> void:
	# Steam.setLobbyType still works the same with the Peer class
	match index:
		0: Steam.setLobbyType(Network.lobby_id, Steam.LOBBY_TYPE_FRIENDS_ONLY)
		1: Steam.setLobbyType(Network.lobby_id, Steam.LOBBY_TYPE_PRIVATE)
		2: Steam.setLobbyType(Network.lobby_id, Steam.LOBBY_TYPE_PUBLIC)

func _on_leave_lobby_pressed() -> void:
	Network.leave_lobby()

func _on_leave() -> void:
	$"HSplitContainer/Current Lobby Container/Leave Lobby".disabled = true
	$"HSplitContainer/Current Lobby Container/Host".disabled = false
	$"HSplitContainer/Current Lobby Container/Lobby Options".disabled = false
	update_players()

# --- BROWSER LOGIC ---

func _on_reload_lobbies_pressed() -> void:
	update_lobby_browser()

func update_lobby_browser():
	for child in lobbies_elem_container.get_children():
		child.queue_free()
		
	#var lobby_filter = Steam.LOBBY_DISTANCE_FILTER_DEFAULT
	#match $"HSplitContainer/Lobbies Container/Region".selected:
		#1: lobby_filter = Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE
		#2: lobby_filter = Steam.LOBBY_DISTANCE_FILTER_CLOSE
		#3: lobby_filter = Steam.LOBBY_DISTANCE_FILTER_FAR
		
	#var search_text : String = $"HSplitContainer/Lobbies Container/SearchEdit".text
	#if !search_text.is_empty():
		#Steam.addRequestLobbyListStringFilter("name", search_text, Steam.LOBBY_COMPARISON_EQUAL_TO_OR_LESS_THAN)
	
	#Steam.addRequestLobbyListDistanceFilter(lobby_filter)
	Steam.requestLobbyList()

func update_players():
	# Clear old entries
	for child in current_lobby_elem_container.get_children():
		child.queue_free()
	
	# Network.lobby_members is updated via Steam signals automatically now
	member_count.text = "Members: %d / %d" % [Network.lobby_members.size(), Network.lobby_members_max]
	
	for member in Network.lobby_members:
		current_lobby_elem_container.add_child(create_player_entry(member))

# --- ELEMENT CREATION ---

func create_lobby_entries(lobbies: Array):
	print(lobbies)
	for lobby in lobbies:
		if Steam.getLobbyOwner(lobby) == GlobalSteam.steam_id:
			print("Found my own lobby in the list!")
		lobbies_elem_container.add_child(create_lobby_entry(lobby))
	lobbies_count.text = "Total Lobbies: %d" % lobbies.size()

func create_lobby_entry(lobby_id_in: int) -> Node:
	var lobby_name = Steam.getLobbyData(lobby_id_in, "name")
	var lobby_max = Steam.getLobbyData(lobby_id_in, "max_player_count")
	var memb_count = Steam.getNumLobbyMembers(lobby_id_in)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var lobby_label = Label.new()
	lobby_label.text = "%s | Players: %d / %s" % [lobby_name, memb_count, lobby_max]
	lobby_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var but = Button.new()
	but.text = "Join"
	# Connect to Network.join_lobby which now handles the Peer setup
	but.pressed.connect(Network.join_lobby.bind(lobby_id_in))
	
	hbox.add_child(lobby_label)
	hbox.add_child(but)
	return hbox

func create_player_entry(playerData: Dictionary) -> Node:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var user_label = Label.new()
	user_label.text = playerData["steam_name"]
	user_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var profile_button = Button.new()
	profile_button.text = "Profile"
	profile_button.pressed.connect(GlobalSteam.visit_profile.bind(playerData["steam_id"]))
	
	hbox.add_child(user_label)
	hbox.add_child(profile_button)
	return hbox


func _on_join_code_pressed() -> void:
	Network.join_lobby(int($"HSplitContainer/Lobbies Container/LineEdit".text))

func ping_pressed():
	print_members.rpc()

@rpc("any_peer")
func print_members():
	print(multiplayer.get_unique_id())
	print(Network.lobby_members)
