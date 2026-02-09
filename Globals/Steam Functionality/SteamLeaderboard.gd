extends Node

func _ready()->void:
	Steam.leaderboard_find_result.connect(leaderboard_result)
	Steam.leaderboard_scores_downloaded.connect(leaderboard_scores)
	set_up_leaderboards()

##LEADERBOARDS
var boardhandles:Dictionary = {}
func set_up_leaderboards():
	if not GlobalSteam.is_on_steam:
		return
	Steam.findLeaderboard("RECORD TIME PRACTICE")
	await leaderboard_update
	Steam.findLeaderboard("RECORD TIME EASY")
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
	if not GlobalSteam.is_online:
		return
	print("SETTING LEADERBOARD : ",leaderboard_name," TO : ", value)
	Steam.uploadLeaderboardScore(value,true,PackedInt32Array(),boardhandles[leaderboard_name][0])

func leaderboard_scores(message,handle,result):
	for r in result:
		var score_holder = Steam.getFriendPersonaName(r["steam_id"])
		var score = r["score"]
		print(score_holder," ",score)
	leaderboard_download.emit([message,handle,result])

func upload_records():
	if Globals.is_cheater:
		return
	match Globals.roads_to_win:
		int(INF):
			submit_leaderboard_score("RECORD TIME ENDLESS",Globals.world_node.cur_player_road)
		10:
			submit_leaderboard_score("RECORD TIME PRACTICE",Globals.timer)
		25:
			submit_leaderboard_score("RECORD TIME EASY",Globals.timer)
		50:
			submit_leaderboard_score("RECORD TIME NORMAL",Globals.timer)
		100:
			submit_leaderboard_score("RECORD TIME HARD",Globals.timer)
