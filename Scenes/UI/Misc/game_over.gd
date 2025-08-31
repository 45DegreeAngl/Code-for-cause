extends Control

func _ready() -> void:
	Globals.game_lost.connect(_on_lose)

func _on_lose(reason:String):
	if Globals.game_over:
		return
	$RichTextLabel.text = ""
	MainShaderCanvas.toggle_filter("drunk")
	MainShaderCanvas.filter_dict["BeerMeter"][0].visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Globals.game_over = true
	visible = true
	match reason:
		"Sober":
			GlobalSteam.setAchievement("BECOME SOBER")
			$RichTextLabel.append_text(tr("SOBER_END_RICH"))
		"Cops":
			GlobalSteam.setAchievement("GET ARRESTED")
			$RichTextLabel.append_text(tr("ARRESTED_END_RICH"))
	$Label.text = tr("TIME_SURVIVED_LABEL").format([Globals.format_seconds_as_time(Globals.timer)])
	#print(Globals.roads_to_win)
	if Globals.roads_to_win == int(INF):
		$Label.text += str(tr("ROADS_PASSED_LABEL").format([Globals.world_node.cur_player_road]))
		GlobalSteam.upload_win()
	GlobalSteam.update_stats()
	MainShaderCanvas.visible = false
	Globals.tutorial = true
	Globals.game_paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$"Main Menu".grab_focus()
	print("DID WE CHEAT?: ", Globals.is_cheater)
	#$"Game World".process_mode = Node.PROCESS_MODE_DISABLED


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/Main Menu/main_menu.tscn")
