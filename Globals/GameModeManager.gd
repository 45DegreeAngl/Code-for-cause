extends Node

var player_drunkenness: Dictionary = {}
var players_sobered_up: Array = []
var exes_house_position: Vector3 = Vector3.ZERO
var game_has_winner: bool = false

func _ready():
	Globals.register_static_node("game_mode_manager", self)
	Globals.game_won.connect(_on_game_won)

func start_game(lobby_members: Array):
	player_drunkenness.clear()
	players_sobered_up.clear()
	game_has_winner = false
	for member_id in lobby_members:
		player_drunkenness[member_id] = 20.0 # Starting drunkenness

func set_exes_house_position(pos: Vector3):
	exes_house_position = pos

func update_player_drunkenness(player_id: int, value: float):
	if player_drunkenness.has(player_id):
		player_drunkenness[player_id] = value
		if value <= 0 and not players_sobered_up.has(player_id):
			player_sobered_up(player_id)

func get_player_drunkenness(player_id: int) -> float:
	return player_drunkenness.get(player_id, 0.0)

func player_sobered_up(player_id: int):
	if not players_sobered_up.has(player_id):
		players_sobered_up.append(player_id)
		print("Player %s has sobered up!" % GlobalSteam.get_friend_persona_name(player_id))
		
		var player_manager = Globals.get_static_node("player_manager")
		if player_manager:
			player_manager.remove_player_car(player_id)

		# Check if all players have sobered up
		if players_sobered_up.size() >= player_drunkenness.size():
			end_game_as_tie()

func _on_game_won():
	game_has_winner = true
	end_game_with_winner()

func end_game_with_winner():
	var player_distances = []
	for node_id in Globals.network_registry:
		var node = Globals.get_node_by_id(node_id)
		if node and node.has_method("get_owner_steam_id"):
			var owner_id = node.get_owner_steam_id()
			if owner_id != 0 and player_drunkenness.has(owner_id):
				var distance = node.global_position.distance_to(exes_house_position)
				player_distances.append({"id": owner_id, "distance": distance})

	player_distances.sort_custom(func(a, b): return a.distance < b.distance)
	
	print("--- GAME OVER: RANKING ---")
	for i in range(player_distances.size()):
		var player_info = player_distances[i]
		var player_name = GlobalSteam.get_friend_persona_name(player_info.id)
		print("#%d: %s (Distance: %d m)" % [i + 1, player_name, player_info.distance])
	
	# You can now display this information on a UI screen.

func end_game_as_tie():
	print("--- GAME OVER: TIE ---")
	print("All players have sobered up!")
	# You can now display a tie screen.

