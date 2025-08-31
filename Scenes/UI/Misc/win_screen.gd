extends Control

func _ready() -> void:
	Globals.game_won.connect(_on_win)

func _on_win():
	if Globals.game_over:
		return
	if !Globals.detected:
		GlobalSteam.setAchievement("SILENT DRIVER")
	visible = true
	Globals.game_over = true
	$Label2.text = tr("YOUR_TIME_LABEL").format([Globals.format_seconds_as_time(Globals.timer)])
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MainShaderCanvas.visible = false
	Globals.tutorial = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GlobalSteam.upload_win()
	GlobalSteam.upload_records()
	GlobalSteam.update_stats()
	$"Main Menu".grab_focus()
	#$"Game World".process_mode = Node.PROCESS_MODE_DISABLED


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/Main Menu/main_menu.tscn")
