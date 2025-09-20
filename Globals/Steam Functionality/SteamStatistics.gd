extends Node

func _ready()->void:
	Steam.user_stats_received.connect(_on_steam_stats_ready)
	Steam.requestUserStats(GlobalSteam.steam_id)

##STATISTICS AND LEADERBOARDS
var statistics : Dictionary = {"GABE'S FAVOR":0,"DRUNK MENACE":0,"LITTER COUNT":0,"FLIP COUNT":0}

func _on_steam_stats_ready(this_game: int, this_result: int, this_user: int) -> void:
	#print("Received local player stats and achievements from Steam: %s / %s /%s" % [this_user, this_result, this game])

	# These will check against the data we pulled in the initialization tutorial
	if this_user != GlobalSteam.steam_id:
		print("These stats belong to %s instead, aborting Steam stat and achievement loading" % this_user)
		return

	if this_game != GlobalSteam.game_id:
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

func update_stats():
	if Globals.is_cheater:
		return
	statistics["DRUNK MENACE"]+=Globals.sober_drivers_hit
	statistics["LITTER COUNT"]+=Globals.litter_count
	statistics["FLIP COUNT"]+=Globals.car_flip_count
	statistics["GABE'S FAVOR"]+=Globals.total_alcohol_bought
	for statistic in statistics:
		set_statistic(statistic,statistics[statistic])
	if statistics["DRUNK MENACE"]>=50:
		SteamAchievements.setAchievement("SOBER DRIVER ENEMY NO 1")
	if statistics["LITTER COUNT"]>=100:
		SteamAchievements.setAchievement("PROFESSIONAL LITTERER")
	if statistics["FLIP COUNT"]>=100:
		SteamAchievements.setAchievement("CAR FLIPPER")
	if statistics["GABE'S FAVOR"]>=500:
		SteamAchievements.setAchievement("GABES FAVORITE")
	SteamLeaderboard.submit_leaderboard_score("RECORD SOBER HATER",statistics["DRUNK MENACE"])
