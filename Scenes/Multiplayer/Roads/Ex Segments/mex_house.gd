extends Node3D

var is_multiplayer: bool = false
var network_id = -1
var game_won_by_player: int = 0 # Steam ID of the winner

func _ready():
	network_id = Globals.generate_network_id()
	Globals.register_node(self, network_id)
	
	var game_mode_manager = Globals.get_static_node("game_mode_manager")
	if game_mode_manager:
		game_mode_manager.set_exes_house_position(global_position)

func _on_win_zone_body_entered(body: Node3D) -> void:
	if is_multiplayer:
		if game_won_by_player != 0: return # Someone already won

		var winning_player_id = 0
		if body.has_method("get_owner_steam_id"): # Covers both car and character
			winning_player_id = body.get_owner_steam_id()
		
		if winning_player_id != 0:
			# The first player to enter triggers the win condition for everyone.
			# The host is responsible for broadcasting this.
			if Network.is_host:
				Network.p2p_call_func(network_id, "announce_winner", [winning_player_id])
				announce_winner(winning_player_id)
	else:
		# Original single-player logic
		if body == Globals.player_vehicle or (body is PhysicalBone3D and body.get_parent().get_parent().get_parent().get_parent() == Globals.player_character):
			Globals.game_won.emit()

func announce_winner(steam_id: int):
	if game_won_by_player != 0: return # Ensure it only runs once
	
	game_won_by_player = steam_id
	var winner_name = GlobalSteam.get_friend_persona_name(steam_id)
	print("Player %s (%s) has won the game!" % [winner_name, steam_id])
	
	# Now you can emit the game_won signal, perhaps with the winner's info
	Globals.game_won.emit() # You might want to modify game_won to pass the winner's ID/name
