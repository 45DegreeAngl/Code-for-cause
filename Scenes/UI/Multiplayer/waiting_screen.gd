extends Control

@onready var is_host_label: Label = $PanelContainer/VBoxContainer/IsHostLabel
@onready var player_container: VBoxContainer = $"PanelContainer/VBoxContainer/ScrollContainer/Player Container"
@onready var start_button: Button = $PanelContainer/VBoxContainer/Start

signal start_pressed()

# --- GODOT FUNCTIONS ---

func _ready()->void:
	# Register this UI with the static registry using a clear, reliable name.
	Globals.register_static_node("waiting_screen", self)

	# Connect to network signals to update the player list and host status dynamically.
	Network.player_joined.connect(add_player_entry)
	Network.player_left.connect(remove_player_entry)
	Network.lobby_changed.connect(update_host_status)

	# Set the initial state of the UI.
	update_host_status()

	# Populate the list with players who are already in the lobby.
	for member in Network.lobby_members:
		add_player_entry(member["steam_id"])

func _exit_tree() -> void:
	# Unregister when the node is removed.
	Globals.unregister_static_node("waiting_screen")

# --- UI FUNCTIONS ---

func update_host_status():
	# This function is called whenever the lobby changes to update host-specific UI.
	if Network.is_host:
		is_host_label.text = "You are the host."
		start_button.visible = true
	else:
		is_host_label.text = "You are not the host. Please wait for the host to start."
		start_button.visible = false

func add_player_entry(steam_id:int):
	# Prevents adding a duplicate entry if a signal fires for an existing player.
	if player_container.find_child(str(steam_id), false):
		return

	var hcon := HBoxContainer.new()
	hcon.name = str(steam_id) # Name the container by the ID for easy removal later.

	var pfp_rect := TextureRect.new()
	pfp_rect.custom_minimum_size = Vector2(64, 64)
	pfp_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pfp_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Fetch and display the Steam avatar.
	var avatar_handle: int = Steam.getMediumFriendAvatar(steam_id)
	if avatar_handle > 0:
		var image_size: Dictionary = Steam.getImageSize(avatar_handle)
		var image_rgba: Dictionary = Steam.getImageRGBA(avatar_handle)
		if image_rgba["success"]:
			var img = Image.create_from_data(image_size.width, image_size.height, false, Image.FORMAT_RGBA8, image_rgba["buffer"])
			var texture = ImageTexture.create_from_image(img)
			pfp_rect.texture = texture

	var name_label := Label.new()
	name_label.text = Steam.getFriendPersonaName(steam_id)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = SIZE_EXPAND_FILL

	if steam_id == GlobalSteam.steam_id:
		hcon.modulate = Color(0.7, 0.9, 1.0, 0.5)

	hcon.add_child(pfp_rect)
	hcon.add_child(name_label)
	player_container.add_child(hcon)

func remove_player_entry(steam_id: int):
	var player_entry = player_container.find_child(str(steam_id), false)
	if player_entry:
		player_entry.queue_free()

# --- SIGNAL HANDLERS & NETWORK FUNCTIONS ---

func _on_start_pressed() -> void:
	# The host sends a command to all clients (including itself)
	# to call the 'hide_and_start' function on the node registered as "waiting_screen".
	if Network.is_host:
		Network.p2p_call_func("waiting_screen", "hide_and_start")

# This function is now reliably called on all clients by the host.
func hide_and_start():
	self.visible = false
	
	# Only the host should actually start the game logic.
	if Network.is_host:
		start_pressed.emit()
