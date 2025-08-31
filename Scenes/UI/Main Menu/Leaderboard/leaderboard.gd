extends Control
@onready var entry_range:Label = $Leaderboard/HBoxContainer/PanelContainer/Numbers
var leaderboard_entries : Array
var prev_tab : int = 0
var cur_range_min:int = 1
var cur_range_max:int = 25

func _ready() -> void:
	GlobalSteam.set_up_leaderboards()
	GlobalSteam.leaderboard_download.connect(choose_leaderboard_entries)
	
	_on_leaderboard_container_tab_selected($"Leaderboard/Leaderboard Container".current_tab)


func choose_leaderboard_entries(arr:Array)->void:
	leaderboard_entries = arr
	return

func _on_leaderboard_container_tab_selected(tab: int) -> void:
	if!(GlobalSteam.boardhandles.get("RECORD TIME PRACTICE",null)):
		return
	match tab:
		0:#Practice
			GlobalSteam.download_leaderboard_entries(GlobalSteam.boardhandles["RECORD TIME PRACTICE"][0],cur_range_min,cur_range_max)
		1:#Easy
			GlobalSteam.download_leaderboard_entries(GlobalSteam.boardhandles["RECORD TIME EASY"][0],cur_range_min,cur_range_max)
		2:#Normal
			GlobalSteam.download_leaderboard_entries(GlobalSteam.boardhandles["RECORD TIME NORMAL"][0],cur_range_min,cur_range_max)
		3:#Hard
			GlobalSteam.download_leaderboard_entries(GlobalSteam.boardhandles["RECORD TIME HARD"][0],cur_range_min,cur_range_max)
		4:#Endless
			GlobalSteam.download_leaderboard_entries(GlobalSteam.boardhandles["RECORD TIME ENDLESS"][0],cur_range_min,cur_range_max)
		5:#Sober Hater
			GlobalSteam.download_leaderboard_entries(GlobalSteam.boardhandles["RECORD SOBER HATER"][0],cur_range_min,cur_range_max)
	await GlobalSteam.leaderboard_download
	
	for child in $"Leaderboard/Leaderboard Container".get_child(prev_tab).get_child(0).get_children():
		#print(child)
		child.queue_free()
	prev_tab = tab
	
	var container:VBoxContainer = $"Leaderboard/Leaderboard Container".get_child(tab).get_child(0)
	for r in leaderboard_entries[2]:
		#print("create entry")
		var entry : Control = create_leaderboard_entry(r["global_rank"],r["steam_id"],r["score"])
		container.add_child(entry)

func create_leaderboard_entry(rank:int,steam_id:int,score)->Control:
	var container : HBoxContainer = HBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.size_flags_horizontal = true
	var rank_label : Label = Label.new()
	rank_label.text = str("Rank: ",rank)
	container.add_child(rank_label)
	var username_label : Label = Label.new()
	username_label.text = Steam.getFriendPersonaName(steam_id)
	username_label.size_flags_horizontal = true
	container.add_child(username_label)
	var score_label : Label = Label.new()
	var temp_string : String = Globals.format_seconds_as_time(score)
	if prev_tab == 4||prev_tab==5:
		temp_string = str(score)
	score_label.text = str("\t",temp_string,"\t")
	container.add_child(score_label)
	var button : Button = Button.new()
	button.text = tr("PROFILE_BUTTON")
	button.pressed.connect(GlobalSteam.visit_profile.bind(steam_id))
	container.add_child(button)
	return container

func _on_left_pressed() -> void:
	cur_range_min-=25
	if cur_range_min<1:
		cur_range_min = 1
	cur_range_max-=25
	if cur_range_max<25:
		cur_range_max = 25
	entry_range.text = str(cur_range_min,"-",cur_range_max)
	_on_leaderboard_container_tab_selected(prev_tab)


func _on_right_pressed() -> void:
	cur_range_min+=25
	cur_range_max+=25
	entry_range.text = str(cur_range_min,"-",cur_range_max)
	_on_leaderboard_container_tab_selected(prev_tab)

signal back_pressed()
func _on_back_pressed() -> void:
	back_pressed.emit()
