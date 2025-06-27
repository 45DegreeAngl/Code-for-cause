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
	set_up_leaderboards()
	#Steam.current_stats_received.connect(_on_steam_stats_ready)
	Steam.user_stats_received.connect(_on_steam_stats_ready)
	Steam.requestUserStats(steam_id)
	print("HELLO ",steam_username)

func visit_profile(target_steam_id):
	OS.shell_open(steam_profile_url_handle+str(target_steam_id))

func _initialize_steam() -> void:
	if Engine.has_singleton("Steam"):
		OS.set_environment("SteamAppId", str(game_id))
		OS.set_environment("SteamGameId", str(game_id))
		
		var init_response: Dictionary = Steam.steamInitEx(false)
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

##STATISTICS AND LEADERBOARDS
var statistics : Dictionary = {"GABE'S FAVOR":0,"DRUNK MENACE":0,"LITTER COUNT":0,"FLIP COUNT":0}

func _on_steam_stats_ready(this_game: int, this_result: int, this_user: int) -> void:
	#print("Received local player stats and achievements from Steam: %s / %s /%s" % [this_user, this_result, this game])

	# These will check against the data we pulled in the initialization tutorial
	if this_user != steam_id:
		print("These stats belong to %s instead, aborting Steam stat and achievement loading" % this_user)
		return

	if this_game != game_id:
		print("Stats are for a different app ID: %s" % this_game)
		return

	if this_result != Steam.RESULT_OK:
		print("Failed to get stats and achievements from Steam: %s" % this_result)
		return
	#Steam.requestUserStats(steam_id)
	#Steam.requestCurrentStats()
	load_steam_stats()

func load_steam_stats() -> void:
	for this_stat in statistics.keys():
		var steam_stat: int = Steam.getStatInt(this_stat)
		
		print(this_stat," : ", steam_stat)
		# The set_statistic function below in the Setting Statistics section
		if statistics[this_stat] > steam_stat:
			print("Stat mismatch; local value is higher (%s), replacing Steam value (%s)" % [statistics[this_stat], steam_stat])
			set_statistic(this_stat, statistics[this_stat])

		elif statistics[this_stat] < steam_stat:
			print("Stat mismatch; local value is lower (%s), replacing with Steam value (%s)" % [(statistics[this_stat]), steam_stat])
			set_statistic(this_stat, steam_stat)

		else:
			print("Steam stat matches local file: %s" % this_stat)

	print("Steam statistics loaded")

func set_statistic(this_stat: String, new_value: int = 0) -> void:
	#Steam.requestCurrentStats()
	if not Steam.setStatInt(this_stat, new_value):
		print("Failed to set stat %s to: %s" % [this_stat, new_value])
		return
	
	statistics[this_stat] = new_value
	print("Set statistics %s succesfully: %s" % [this_stat, new_value])


	# Pass the value to Steam then fire it
	if not Steam.storeStats():
		print("Failed to store data on Steam, should be stored locally")
		return

	print("Data successfully sent to Steam")



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
signal leaderboard_download
func leaderboard_result(handle,found):
	if found:
		var leaderboard_name = Steam.getLeaderboardName(handle)
		boardhandles[leaderboard_name] = [handle]
		print("LEADERBOARD ",leaderboard_name," FOUND")
	else:
		print("LEADERBOARD NOT FOUND")
	leaderboard_update.emit()

func download_leaderboard_entries(handle:int=0 ,start:int=1,end:int=10):
	Steam.downloadLeaderboardEntries(start,end,Steam.LEADERBOARD_DATA_REQUEST_GLOBAL,handle)

func submit_leaderboard_score(leaderboard_name:String,value):
	print("SETTING LEADERBOARD : ",leaderboard_name," TO : ", value)
	Steam.uploadLeaderboardScore(value,true,PackedInt32Array(),boardhandles[leaderboard_name][0])

func leaderboard_scores(message,handle,result):
	for r in result:
		var score_holder = Steam.getFriendPersonaName(r["steam_id"])
		var score = r["score"]
		print(score_holder," ",score)
	leaderboard_download.emit([message,handle,result])
	

func setAchievement(ach:String):
	var status = Steam.getAchievement(ach)
	if !status:
		return
	if status["achieved"]:
		print("Already Unlocked")
		return
	Steam.setAchievement(ach)
	print("Unlocked achievement: ",ach)
	if not Steam.storeStats():
		print("Balls")
