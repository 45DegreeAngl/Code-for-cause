extends Node

@export var game_packed : PackedScene
@export var TitleMusicPlayer :AudioStreamPlayer

func _ready()->void:
	Steam.getCurrentGameLanguage()
	print(OS.get_locale_language())
	TranslationServer.set_locale(OS.get_locale_language())
	Globals.game_lost.connect(_on_lose)
	Globals.game_won.connect(_on_win)
	GlobalSteam.leaderboard_download.connect(choose_leaderboard_entries)
	$AnimationPlayer.play("Cop_Lights")
	set_sliders()
	$"Main Menu/PanelContainer/VBoxContainer/Start".grab_focus()
	#save_options()
	load_options()

func _on_lose(reason:String):
	if Globals.game_over:
		return
	$"Game Over/RichTextLabel".text = ""
	MainShaderCanvas.toggle_filter("drunk")
	MainShaderCanvas.filter_dict["BeerMeter"][0].visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Globals.game_over = true
	$"Game Over".visible = true
	match reason:
		"Sober":
			GlobalSteam.setAchievement("BECOME SOBER")
			$"Game Over/RichTextLabel".append_text(tr("SOBER_END_RICH"))
		"Cops":
			GlobalSteam.setAchievement("GET ARRESTED")
			$"Game Over/RichTextLabel".append_text(tr("ARRESTED_END_RICH"))
	$"Game Over/Label".text = tr("TIME_SURVIVED_LABEL").format([Globals.format_seconds_as_time(Globals.timer)])
	#print(Globals.roads_to_win)
	if Globals.roads_to_win == int(INF):
		$"Game Over/Label".text += str(tr("ROADS_PASSED_LABEL").format([Globals.world_node.cur_player_road]))
		upload_win()
	update_stats()
	MainShaderCanvas.visible = false
	Globals.tutorial = true
	Globals.game_paused = false
	$Options.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$"Game Over/Main Menu".grab_focus()
	print("DID WE CHEAT?: ", Globals.is_cheater)
	#$"Game World".process_mode = Node.PROCESS_MODE_DISABLED

#func _on_difficulty_options_item_selected(index: int) -> void:
	#Globals.roads_to_win = Globals.roads_to_win_options[index]

func upload_win():
	if Globals.is_cheater:
		return
	match Globals.roads_to_win:
		int(INF):
			if Globals.world_node.cur_player_road>=200:
				GlobalSteam.setAchievement("BEAT ENDLESS")
			upload_records()
		10:
			GlobalSteam.setAchievement("BEAT PRACTICE")
			upload_records()
		25:
			GlobalSteam.setAchievement("BEAT EASY")
			upload_records()
		50:
			GlobalSteam.setAchievement("BEAT NORMAL")
			upload_records()
		100:
			GlobalSteam.setAchievement("BEAT HARD")
			upload_records()

func upload_records():
	if Globals.is_cheater:
		return
	match Globals.roads_to_win:
		int(INF):
			GlobalSteam.submit_leaderboard_score("RECORD TIME ENDLESS",Globals.world_node.cur_player_road)
		10:
			GlobalSteam.submit_leaderboard_score("RECORD TIME PRACTICE",Globals.timer)
		25:
			GlobalSteam.submit_leaderboard_score("RECORD TIME EASY",Globals.timer)
		50:
			GlobalSteam.submit_leaderboard_score("RECORD TIME NORMAL",Globals.timer)
		100:
			GlobalSteam.submit_leaderboard_score("RECORD TIME HARD",Globals.timer)
	

func update_stats():
	if Globals.is_cheater:
		return
	GlobalSteam.statistics["DRUNK MENACE"]+=Globals.sober_drivers_hit
	GlobalSteam.statistics["LITTER COUNT"]+=Globals.litter_count
	GlobalSteam.statistics["FLIP COUNT"]+=Globals.car_flip_count
	GlobalSteam.statistics["GABE'S FAVOR"]+=Globals.total_alcohol_bought
	for statistic in GlobalSteam.statistics:
		GlobalSteam.set_statistic(statistic,GlobalSteam.statistics[statistic])
	if GlobalSteam.statistics["DRUNK MENACE"]>=50:
		GlobalSteam.setAchievement("SOBER DRIVER ENEMY NO 1")
	if GlobalSteam.statistics["LITTER COUNT"]>=100:
		GlobalSteam.setAchievement("PROFESSIONAL LITTERER")
	if GlobalSteam.statistics["FLIP COUNT"]>=100:
		GlobalSteam.setAchievement("CAR FLIPPER")
	if GlobalSteam.statistics["GABE'S FAVOR"]>=500:
		GlobalSteam.setAchievement("GABES FAVORITE")
	GlobalSteam.submit_leaderboard_score("RECORD SOBER HATER",GlobalSteam.statistics["DRUNK MENACE"])

func _on_win():
	if Globals.game_over:
		return
	if !Globals.detected:
		GlobalSteam.setAchievement("SILENT DRIVER")
	$"YOU WIN".visible = true
	Globals.game_over = true
	$"YOU WIN/Label2".text = tr("YOUR_TIME_LABEL").format([Globals.format_seconds_as_time(Globals.timer)])
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MainShaderCanvas.visible = false
	Globals.tutorial = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	upload_win()
	upload_records()
	update_stats()
	$"YOU WIN/Main Menu".grab_focus()
	#$"Game World".process_mode = Node.PROCESS_MODE_DISABLED

func _process(_delta: float) -> void:
	if Globals.game_over or $"Game Over".visible or $"YOU WIN".visible or $"Main Menu".visible:
		return
	if Input.is_action_just_pressed("KEYWORD_PAUSE"):
		if $Options.visible:
			Globals.game_paused = false
			$Options.visible = false
			MainShaderCanvas.filter_dict["BeerMeter"][0].visible = true
			MainShaderCanvas.filter_dict["drunk"][0].visible = true
			#$"Game World".process_mode = Node.PROCESS_MODE_INHERIT
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Globals.game_paused = true
			$Options.visible = true
			MainShaderCanvas.filter_dict["BeerMeter"][0].visible = false
			MainShaderCanvas.filter_dict["drunk"][0].visible = false
			#$"Game World".process_mode = Node.PROCESS_MODE_DISABLED
			$"Options/true options/VBoxContainer/Back".visible = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			$"Options/true options/VBoxContainer/Become Sober".grab_focus()


func _on_start_pressed() -> void:
	Globals.tutorial = false
	Globals.drunkenness = 20
	Globals.tutorial = true
	for child in $"Game World".get_children():
		child.queue_free()
	#$"Game World".process_mode = Node.PROCESS_MODE_INHERIT
	main_menu()
	$"Main Menu".visible = false
	$Animations.visible = true
	$Animations.get_child(0).play_intro()
	$Animations.get_child(0).get_child(6).grab_focus()

func _on_start_game() ->void:
	Globals.is_cheater = false
	Debug.console_active = false
	Globals.reset_stats()
	TitleMusicPlayer.playing = false
	$MenuGeometry/SubViewportContainer.visible = false
	$MenuGeometry.visible = false
	var game_instance = game_packed.instantiate()
	$"Game World".add_child(game_instance)
	Globals.game_over = false
	Globals.world_node = game_instance
	$Animations.visible = false
	MainShaderCanvas.visible = true
	$Animations.get_child(0).queue_free()
	var temp :Control= load("res://Scenes/UI/Misc/intro_comic.tscn").instantiate()
	$Animations.add_child(temp)
	temp.find_child("GoToGame").pressed.connect(_on_start_game)
	$"Options/true options/VBoxContainer/Become Sober".visible = true
	Globals.detected = false

func _on_options_pressed() -> void:
	$Options.visible = true
	$"Main Menu".visible = false
	$"Options/true options/VBoxContainer/Back".visible = true
	$"Options/true options/VBoxContainer/Become Sober".visible = false
	$"Options/true options/VBoxContainer/Back".grab_focus()

func _on_radio_workshop_pressed() ->void:
	$"Radio Workshop".load_radio_entries()
	$"Radio Workshop".visible = true
	$"Main Menu".visible = false
	$"Radio Workshop/Back".grab_focus()


func _on_credits_pressed() -> void:
	$Credits.visible = true
	$"Main Menu".visible = false
	$Credits/Close.grab_focus()

func main_menu():
	$MenuGeometry.visible = true
	$MenuGeometry/SubViewportContainer.visible = true
	$Credits.visible = false
	$Options.visible = false
	$"Main Menu".visible = true
	$"Game Over".visible = false
	$"YOU WIN".visible = false
	$Leaderboard.visible = false
	$"Radio Workshop".visible = false
	$"Main Menu/PanelContainer/VBoxContainer/Start".grab_focus()


func on_back()->void:
	main_menu()
	for child in $"Game World".get_children():
		child.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if !TitleMusicPlayer.playing:
		TitleMusicPlayer.playing = true

###OPTIONS
@export_subgroup("BOOLEAN_SETTINGS")
@export var motion_check : CheckBox
@export var spider_fear_check : CheckBox
@export var spider_love_check : CheckBox

@export_subgroup("SENSITIVITY_OPTIONS")
@export var controller : HSlider
@export var mouse : HSlider

@export_subgroup("AUDIO_OPTIONS")
@export var master: HSlider
@export var voice: HSlider 
@export var radio: HSlider 
@export var world_sounds: HSlider 
@export var controller_settings: Control 


@onready var default_options :Save_Options = preload("res://Resources/Save Resources/Default Options.tres")

func _on_controls_pressed() -> void:
	controller_settings.load_all_actions()
	controller_settings.visible = true
	controller_settings.back_button.grab_focus()
	

func _on_controller_settings_back_pressed() -> void:
	controller_settings.visible = false
	$Options/PanelContainer/VBoxContainer/HBoxContainer/Controls.grab_focus()

func _on_reset_pressed() -> void:
	var save_result = ResourceSaver.save(default_options, GlobalWorkshop.user_paths["save"] + "SAVE.tres")  # Save the resource to file.
	
	if save_result == OK:
		load_options()
	else:
		print("ERROR WITH RESET, RESULT : %s",save_result)
var game_actions : Array = ["KEYWORD_FORWARD","KEYWORD_BACKWARD","KEYWORD_LEFT",
"KEYWORD_RIGHT","KEYWORD_JUMP","KEYWORD_MISC_INTERACT","KEYWORD_INTERACT",
"KEYWORD_ALT_INTERACT","KEYWORD_PAUSE","KEYWORD_LEFT_HAND","KEYWORD_RIGHT_HAND"]

# Save options, including controls.
func save_options():
	var temp_options : Save_Options = Save_Options.new()

	# Save boolean settings.
	temp_options.motion_sickness = motion_check.button_pressed
	temp_options.aracnophobia = spider_fear_check.button_pressed
	temp_options.aracnophilia = spider_love_check.button_pressed

	# Save window options.
	temp_options.res_options = $"Options/Resolution holder/VBoxContainer/Resolution options".selected
	temp_options.quality_options = $"Options/Resolution holder/VBoxContainer/Quality Options".selected
	temp_options.window_options = $"Options/Resolution holder/VBoxContainer/Window Options".selected
	temp_options.language_options = $"Options/Resolution holder/VBoxContainer/Language Options".selected

	#save sensitivity
	temp_options.mouse_sense_mult = controller.value
	temp_options.contr_sense_mult = mouse.value

	# Save volume settings.
	temp_options.master_vol = master.value
	temp_options.voice_vol = voice.value
	temp_options.music_vol = radio.value
	temp_options.world_vol = world_sounds.value
	
	var control_mapping = {}
	for action in InputMap.get_actions():
		if !game_actions.has(action):
			continue
		var action_events = InputMap.action_get_events(action)
		var event_list = []
		for event in action_events:
			if event is InputEventKey:
				event_list.append({"type": "key", "scancode": event.physical_keycode, "shift": event.shift_pressed, "alt": event.alt_pressed, "ctrl": event.ctrl_pressed})
			elif event is InputEventMouseButton:
				event_list.append({"type": "mouse_button", "button_index": event.button_index})
			elif event is InputEventJoypadButton:
				event_list.append({"type": "joypad_button", "button_index": event.button_index})
			elif event is InputEventJoypadMotion:
				event_list.append({"type": "joypad_motion", "axis": event.axis, "value": event.axis_value})
			# Add more event types as needed.
		control_mapping[action] = event_list
	temp_options.controls = control_mapping
	
	
	ResourceSaver.save(temp_options, GlobalWorkshop.user_paths["save"] + "SAVE.tres")  # Save the resource to file.

# Load options, including controls.
func load_options():
	var temp_options : Save_Options

	# Check if saved options exist.
	if GlobalWorkshop.get_files_in_directory_unbounded_iterative(GlobalWorkshop.user_paths["save"]).is_empty():
		temp_options = default_options  # Use default options if no saved file exists.
	else:
		temp_options = ResourceLoader.load(GlobalWorkshop.get_files_in_directory_unbounded_iterative(GlobalWorkshop.user_paths["save"])[0])
	
	# Load boolean settings.
	motion_check.toggled.emit(temp_options.motion_sickness)
	motion_check.button_pressed = temp_options.motion_sickness
	spider_fear_check.toggled.emit(temp_options.aracnophobia)
	spider_fear_check.button_pressed = temp_options.aracnophobia
	spider_love_check.toggled.emit(temp_options.aracnophilia)
	spider_love_check.button_pressed = temp_options.aracnophilia

	# Load window options.
	$"Options/Resolution holder/VBoxContainer/Resolution options".selected = temp_options.res_options
	$"Options/Resolution holder/VBoxContainer/Resolution options".item_selected.emit(temp_options.res_options)
	$"Options/Resolution holder/VBoxContainer/Quality Options".selected = temp_options.quality_options
	$"Options/Resolution holder/VBoxContainer/Quality Options".item_selected.emit(temp_options.quality_options)
	$"Options/Resolution holder/VBoxContainer/Window Options".selected = temp_options.window_options
	$"Options/Resolution holder/VBoxContainer/Window Options".item_selected.emit(temp_options.window_options)

	$"Options/Resolution holder/VBoxContainer/Language Options".selected = temp_options.language_options
	$"Options/Resolution holder/VBoxContainer/Language Options".item_selected.emit(temp_options.language_options)

	#load sensitivity
	controller.value = temp_options.contr_sense_mult
	mouse.value = temp_options.mouse_sense_mult

	# Load volume settings.
	master.value = temp_options.master_vol
	voice.value = temp_options.voice_vol
	radio.value = temp_options.music_vol
	world_sounds.value = temp_options.world_vol
	#load control data
	if !temp_options.controls:
		save_options()
	for action in temp_options.controls.keys():
		InputMap.action_erase_events(action) # Clear existing mappings
		for event_data in temp_options.controls[action]:
			var new_event : InputEvent = null
			match event_data["type"]:
				"key":
					new_event = InputEventKey.new()
					new_event.physical_keycode = event_data["scancode"]
					new_event.shift_pressed = event_data["shift"]
					new_event.alt_pressed = event_data["alt"]
					new_event.ctrl_pressed = event_data["ctrl"]
				"mouse_button":
					new_event = InputEventMouseButton.new()
					new_event.button_index = event_data["button_index"]
				"joypad_button":
					new_event = InputEventJoypadButton.new()
					new_event.button_index = event_data["button_index"]
				"joypad_motion":
					new_event = InputEventJoypadMotion.new()
					new_event.axis = event_data["axis"]
					new_event.axis_value = event_data["value"]
				# Add more cases for different types
			if new_event:
				InputMap.action_add_event(action, new_event)
	
	controller_settings.load_all_actions()


func set_sliders():
	master.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	voice.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Voice")))
	radio.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Radio")))
	world_sounds.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sound Effect")))

func _on_controller_value_changed(value: float) -> void:
	Globals.car_cont_sens = Globals.CAR_CONT_SENS * value
	Globals.per_cont_sens = Globals.PER_CONT_SENS * value

func _on_mouse_value_changed(value: float) -> void:
	Globals.car_mous_sens = Globals.CAR_MOUS_SENS * value
	Globals.per_mous_sens = Globals.PER_MOUS_SENS * value

func _on_master_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),linear_to_db(value))


func _on_voice_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Voice"),linear_to_db(value))


func _on_radio_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Radio"),linear_to_db(value))


func _on_world_sounds_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound Effect"),linear_to_db(value))


func _on_motion_sickness_check_toggled(toggled_on: bool) -> void:
	MainShaderCanvas.filter_dict["drunk"][1].visible = !toggled_on
	#Globals.motion_sickness = toggled_on
	#MainShaderCanvas.filter_dict["drunk"][3].visible = toggled_on

func _on_resolution_options_item_selected(index: int) -> void:
	match index:
		0:#1152x648
			DisplayServer.window_set_size(Vector2i(1152,648))
		1:#576x324
			DisplayServer.window_set_size(Vector2i(576,324))
		2:#1920x1080
			DisplayServer.window_set_size(Vector2i(1920,1080))

func on_quality_changed(index:int):
	match index:
		0:
			get_viewport().set_scaling_3d_scale(1)
		1:
			get_viewport().set_scaling_3d_scale(0.75)
		2:
			get_viewport().set_scaling_3d_scale(0.5)
		3:
			get_viewport().set_scaling_3d_scale(0.25)

func _on_window_options_item_selected(index: int) -> void:
	match index:
		0:#Windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:#Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:#Exclusive Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func _on_language_options_item_selected(index: int) -> void:
	match index:
		0:
			TranslationServer.set_locale("en")
		1:
			TranslationServer.set_locale("ita")
		2:
			TranslationServer.set_locale("chi")
		3:
			TranslationServer.set_locale("rus")
		4:
			TranslationServer.set_locale("jpn")
		5:
			TranslationServer.set_locale("kor")
		6:
			TranslationServer.set_locale("vie")
		7:
			TranslationServer.set_locale("por")
		8:
			TranslationServer.set_locale("spa")


func _on_become_sober_pressed() -> void:
	Globals.game_lost.emit("Sober")

##Practice,Easy,Medium,Hard,Endless
#[10,25,50,100,INF]
func _on_difficulty_options_item_selected(index: int) -> void:
	Globals.roads_to_win = Globals.roads_to_win_options[index]

func _on_leaderboards_pressed() -> void:
	$"Main Menu".visible = false
	$Leaderboard.visible = true
	$Leaderboard/Back.grab_focus()
	_on_leaderboard_container_tab_selected($"Leaderboard/Leaderboard/Leaderboard Container".current_tab)

var leaderboard_entries : Array
var prev_tab : int = 0
var cur_range_min:int = 1
var cur_range_max:int = 50

func _on_leaderboard_container_tab_selected(tab: int) -> void:
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
	
	for child in $"Leaderboard/Leaderboard/Leaderboard Container".get_child(prev_tab).get_children():
		print(child)
		child.queue_free()
	prev_tab = tab
	
	var container:VBoxContainer = $"Leaderboard/Leaderboard/Leaderboard Container".get_child(tab)
	for r in leaderboard_entries[2]:
		print("create entry")
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

func choose_leaderboard_entries(arr:Array)->void:
	leaderboard_entries = arr
	return

func _on_left_pressed() -> void:
	cur_range_min-=50
	if cur_range_min<1:
		cur_range_min = 1
	cur_range_max-=50
	if cur_range_max<50:
		cur_range_max = 50
	$Leaderboard/Leaderboard/HBoxContainer/PanelContainer/Numbers.text = str(cur_range_min,"-",cur_range_max)
	_on_leaderboard_container_tab_selected(prev_tab)


func _on_right_pressed() -> void:
	cur_range_min+=50
	cur_range_max+=50
	$Leaderboard/Leaderboard/HBoxContainer/PanelContainer/Numbers.text = str(cur_range_min,"-",cur_range_max)
	_on_leaderboard_container_tab_selected(prev_tab)


func _on_quit_pressed() -> void:
	get_tree().quit()
