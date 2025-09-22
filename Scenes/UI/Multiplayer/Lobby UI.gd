extends Control

@export var lobbies_elem_container:VBoxContainer
@export var current_lobby_elem_container:VBoxContainer
@onready var lobbies_count: Label = $"HSplitContainer/Lobbies Container/Lobbies count"
@onready var member_count: Label = $"HSplitContainer/Current Lobby Container/Members count"

func _ready()->void:
	Network.lobby_left.connect(_on_leave)
	Network.lobby_changed.connect(update_players)
	Steam.lobby_match_list.connect(create_lobby_entries)

func _on_host_pressed() -> void:
	Network.create_lobby()
	$"HSplitContainer/Current Lobby Container/Leave Lobby".disabled = false
	$"HSplitContainer/Current Lobby Container/Host".disabled = true
	update_players()
	_on_lobby_options_item_selected($"HSplitContainer/Current Lobby Container/Lobby Options".selected)

func _on_lobby_joined():
	$"HSplitContainer/Current Lobby Container/Host".disabled = true
	$"HSplitContainer/Current Lobby Container/Lobby Options".disabled = true
	$"HSplitContainer/Current Lobby Container/Leave Lobby".disabled = false
	update_players()

func _on_lobby_options_item_selected(index: int) -> void:
	match index:
		0:#friends only lobby
			Steam.setLobbyType(Network.lobby_id,Steam.LOBBY_TYPE_FRIENDS_ONLY)
		1:#invite only lobby
			Steam.setLobbyType(Network.lobby_id,Steam.LOBBY_TYPE_PRIVATE)
		2:#public lobby
			Steam.setLobbyType(Network.lobby_id,Steam.LOBBY_TYPE_PUBLIC)

func _on_leave_lobby_pressed() -> void:
	Network.handle_lobby_leave()

func _on_leave()->void:
	$"HSplitContainer/Current Lobby Container/Leave Lobby".disabled = true
	$"HSplitContainer/Current Lobby Container/Host".disabled = false
	$"HSplitContainer/Current Lobby Container/Lobby Options".disabled = false
	update_players()

func _on_reload_lobbies_pressed() -> void:
	update_lobby_browser()

func update_lobby_browser():
	for child in lobbies_elem_container.get_children():
		child.queue_free()
	var lobby_filter
	match $"HSplitContainer/Lobbies Container/Region".selected:
		0:#default
			lobby_filter = Steam.LOBBY_DISTANCE_FILTER_DEFAULT
		1:#worldwide
			lobby_filter = Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE
		2:#near
			lobby_filter = Steam.LOBBY_DISTANCE_FILTER_CLOSE
		3:#far
			lobby_filter = Steam.LOBBY_DISTANCE_FILTER_FAR
	var search_text : String = $"HSplitContainer/Lobbies Container/SearchEdit".text
	if !search_text.is_empty():
		Steam.addRequestLobbyListStringFilter("name",search_text,Steam.LOBBY_COMPARISON_EQUAL_TO_OR_LESS_THAN)
	Steam.addRequestLobbyListDistanceFilter(lobby_filter)
	Steam.requestLobbyList()

func update_players():
	for child in current_lobby_elem_container.get_children():
		child.queue_free()
	Network.get_lobby_members()
	
	member_count.text = "Members: {0}/{1}".format([str(Network.lobby_members.size()),str(Network.lobby_members_max)])
	for member in Network.lobby_members:
		current_lobby_elem_container.add_child(create_player_entry(member))

func create_lobby_entries(lobbies):
	for lobby in lobbies:
		lobbies_elem_container.add_child(create_lobby_entry(lobby))
	lobbies_count.text = "Total Lobbies: {0}".format([str(lobbies.size())])

func create_lobby_entry(lobby)->Node:
	var lobby_name = Steam.getLobbyData(lobby,"name")
	var lobby_max = Steam.getLobbyData(lobby,"max_player_count")
	var memb_count = Steam.getNumLobbyMembers(lobby)
	var hbox : HBoxContainer = HBoxContainer.new()
	hbox.size_flags_horizontal = true
	var lobby_label : Label = Label.new()
	lobby_label.text = "{0} | Players: {1} / {2}".format([str(lobby_name),str(memb_count),str(lobby_max)])
	var but : Button = Button.new()
	but.set_text("Join")
	but.connect("pressed",Network.join_lobby.bind(lobby))
	#but.connect("pressed",_on_lobby_joined)
	#but.connect("pressed",update_players)
	hbox.add_child(lobby_label)
	hbox.add_child(but)
	return hbox

func create_player_entry(playerData:Dictionary)->Node:
	var hbox : HBoxContainer = HBoxContainer.new()
	hbox.size_flags_horizontal = true
	var user_label : Label = Label.new()
	user_label.text = playerData["steam_name"]
	var profile_button : Button = Button.new()
	profile_button.text = "Profile"
	
	user_label.custom_minimum_size.x = hbox.size.x - profile_button.size.x
	hbox.add_child(user_label)
	hbox.add_child(profile_button)
	
	profile_button.connect("pressed",GlobalSteam.visit_profile.bind(playerData["steam_id"]))
	
	return hbox
