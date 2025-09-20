extends Node

#3076530
#480
var game_id : int = 3076530
var is_on_steam: bool = false
var is_on_steam_deck: bool = false
var is_online: bool = false
var is_owned: bool = false
var steam_id: int = 0
var steam_username: String = "[not set]"
const steam_profile_url_handle : String = "https://steamcommunity.com/profiles/"

func _init() -> void:
	_initialize_steam()

func is_steam_authority(id:int):
	return steam_id==id

func _process(_delta: float) -> void:
	if is_on_steam:
		Steam.run_callbacks()

func _ready():
	#Steam.current_stats_received.connect(_on_steam_stats_ready)
	print("HELLO ",steam_username)

func visit_profile(target_steam_id):
	OS.shell_open(steam_profile_url_handle+str(target_steam_id))

func _initialize_steam() -> void:
	if Engine.has_singleton("Steam"):
		OS.set_environment("SteamAppId", str(game_id))
		OS.set_environment("SteamGameId", str(game_id))
		
		var init_response: Dictionary = Steam.steamInitEx(false)
		# If the status isn't one, print out the possible error and quit the program
		match init_response['status']:
			0:#successful
				pass
			1:#generic fail
				printerr("[STEAM] Failed to initialize: %s" % 
				str(init_response['verbal']))
				return
				#get_tree().quit()
			2:#cant connect to steam
				printerr("[STEAM] Failed to connect to client: %s" % 
				str(init_response['verbal']))
				return
				#get_tree().quit()
			3:#outdated steam client
				printerr("[STEAM] Client seems to be out of date: %s" % 
				str(init_response['verbal']))
				return
				#get_tree().quit()

		# Is the user actually using Steam; if false, 
		# the app assumes this is a non-Steam version
		is_on_steam = true
		
		# Checking if the app is on Steam Deck to modify certain behaviors
		is_on_steam_deck = Steam.isSteamRunningOnSteamDeck()
		
		# Acquire information about the user
		is_online = Steam.loggedOn()
		steam_id = Steam.getSteamID()
		steam_username = Steam.getPersonaName()

		# Check if account owns the game
		is_owned = Steam.isSubscribed()
		
		if is_owned == false:
			printerr("[STEAM] User does not own this game")
			# Uncomment this line to close the game if the user does not own the game
			#get_tree().quit()
		
	else:
		printerr("Engine does not have the Steam Singleton! Please make sure \n
		you add GodotSteam as a GDNative / GDExtension Plug-in, or with a \n
		compiled Godot version including GodotSteam / Steamworks.\n\n
		For more information, visit https://godotsteam.com/")

func upload_win():
	if Globals.is_cheater:
		return
	match Globals.roads_to_win:
		int(INF):
			if Globals.world_node.cur_player_road>=200:
				SteamAchievements.setAchievement("BEAT ENDLESS")
		10:
			SteamAchievements.setAchievement("BEAT PRACTICE")
		25:
			SteamAchievements.setAchievement("BEAT EASY")
		50:
			SteamAchievements.setAchievement("BEAT NORMAL")
		100:
			SteamAchievements.setAchievement("BEAT HARD")
	SteamLeaderboard.upload_records()

	
