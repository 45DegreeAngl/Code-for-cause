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

func _process(_delta: float) -> void:
	if is_on_steam:
		Steam.run_callbacks()

func _ready():
	set_up_leaderboards()
	print("HELLO ",steam_username)

func visit_profile(target_steam_id):
	OS.shell_open(steam_profile_url_handle+str(target_steam_id))

func _initialize_steam() -> void:
	if Engine.has_singleton("Steam"):
		OS.set_environment("SteamAppId", str(game_id))
		OS.set_environment("SteamGameId", str(game_id))
		
		var init_response: Dictionary = Steam.steamInit(false)
		# If the status isn't one, print out the possible error and quit the program
		if init_response['status'] != 1:
			printerr("[STEAM] Failed to initialize: %s Shutting down..." % 
				str(init_response['verbal']))
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
		
		Steam.leaderboard_find_result.connect(leaderboard_result)
		Steam.leaderboard_scores_downloaded.connect(leaderboard_scores)
		
	else:
		printerr("Engine does not have the Steam Singleton! Please make sure \n
		you add GodotSteam as a GDNative / GDExtension Plug-in, or with a \n
		compiled Godot version including GodotSteam / Steamworks.\n\n
		For more information, visit https://godotsteam.com/")

##LEADERBOARDS
var boardhandles:Dictionary = {}
func set_up_leaderboards():
	Steam.findLeaderboard("RECORD TIME EASY")
	await leaderboard_update
	Steam.findLeaderboard("RECORD TIME PRACTICE")
	await leaderboard_update
	Steam.findLeaderboard("RECORD TIME NORMAL")
	await leaderboard_update
	Steam.findLeaderboard("RECORD TIME HARD")
	await leaderboard_update
	Steam.findLeaderboard("RECORD TIME ENDLESS")
	await leaderboard_update
	Steam.findLeaderboard("RECORD SOBER HATER")
	await leaderboard_update

signal leaderboard_update
func leaderboard_result(handle,found):
	if found:
		var leaderboard_name = Steam.getLeaderboardName(handle)
		boardhandles[leaderboard_name] = [handle]
		
		print("LEADERBOARD ",leaderboard_name," FOUND")
	else:
		print("LEADERBOARD NOT FOUND")
	leaderboard_update.emit()

func download_leaderboard_entries(start:int=1,end:int=10):
	Steam.downloadLeaderboardEntries(start,end)

func submit_leaderboard_score(leaderboard_name:String,value):
	Steam.uploadLeaderboardScore(value,true,PackedInt32Array(),boardhandles[leaderboard_name][0])

func leaderboard_scores(message,handle,result):
	for r in result:
		var score_holder = Steam.getFriendPersonaName(r["steam_id"])
		var score = r["score"]
		print(score_holder," ",score)

func setAchievement(ach:String):
	var status = Steam.getAchievement(ach)
	if status["achieved"]:
		print("Already Unlocked")
		return
	Steam.setAchievement(ach)
	print("Unlocked achievement: ",ach)
