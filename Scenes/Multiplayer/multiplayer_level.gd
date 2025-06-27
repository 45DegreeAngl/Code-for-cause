extends Node3D

@onready var multiplayer_car_string : String = "res://Scenes/User/Multiplayer Car/Multiplayer Car.tscn"
var teams_dictionary:Dictionary = {}
@onready var players_node:Node = $Players

func _ready():
	Network.player_left.connect(on_player_leave)

func start():
	if Network.is_host:
		spawn_players()

func spawn_players():
	for player in Network.lobby_members:
		var player_id = int(player["steam_id"])
		Network.p2p_summon_controller(multiplayer_car_string,players_node.get_path(),player_id)
		await ServerFunc.summon_finish
		
		var cur_player_object = get_playerByID(player_id)
		if cur_player_object.has_signal("i_die"):
			cur_player_object.connect("i_die",on_player_die)
		
		if player_id == GlobalSteam.steam_id:
			if cur_player_object.has_method("update_is_talking"):
				SteamMic.is_talking.connect(cur_player_object.update_is_talking)
		
		var chosen_spawn_marker:Marker3D = $Spawns.get_children().pick_random()
		Network.p2p_call_func(cur_player_object.get_path(),"set_location",[chosen_spawn_marker.global_position])
		await ServerFunc.call_function_finished


func on_player_die(id:int):
	print("OH NO I DIED\t {0} ( {1} )".format([id,Steam.getFriendPersonaName(id)]))
	#move player to proper location

func on_player_leave(id:int):
	print("removing: {0} ( {1} )".format([id,Steam.getFriendPersonaName(id)]))
	for player in players_node.get_children():
		var id_owner : Node3D = get_playerByID(id)
		print(id_owner)
		if id_owner:
			if id_owner.has_method("die"):
				id_owner.die()
			id_owner.call_deferred("queue_free")

func get_playerByID(id:int)->Node:
	var return_player:Node
	for player in players_node.get_children():
		if player.steam_id == id:
			return_player = player
			return return_player
	return null
