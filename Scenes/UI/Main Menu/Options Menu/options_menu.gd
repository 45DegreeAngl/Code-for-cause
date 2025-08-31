extends Control

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

@export_subgroup("WINDOW_OPTIONS")
@export var resolution: OptionButton
@export var quality: OptionButton
@export var window: OptionButton
@export var language: OptionButton

@export_subgroup("MISC_OPTIONS")
@export var controller_settings: Control

@onready var default_options :Save_Options = preload("res://Resources/Save Resources/Default Options.tres")

func _ready()->void:
	set_sliders()
	load_options()

func open_options(in_game:bool=false):
	visible = true
	if in_game:
		$"true options/VBoxContainer/Become Sober".visible = true
	else:
		$"true options/VBoxContainer/Become Sober".visible = false
	$"true options/VBoxContainer/Back".grab_focus()

signal back_pressed()

func _on_back_pressed():
	visible = false
	back_pressed.emit()

func _on_become_sober_pressed() -> void:
	Globals.game_lost.emit("Sober")

func _on_controls_pressed() -> void:
	if !controller_settings:
		return
	controller_settings.load_all_actions()
	controller_settings.visible = true
	controller_settings.back_button.grab_focus()

func _on_return_from_controls():
	$PanelContainer/VBoxContainer/HBoxContainer/Controls.grab_focus()

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
	temp_options.res_options = resolution.selected
	temp_options.quality_options = quality.selected
	temp_options.window_options = window.selected
	temp_options.language_options = language.selected

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
	resolution.selected = temp_options.res_options
	resolution.item_selected.emit(temp_options.res_options)
	quality.selected = temp_options.quality_options
	quality.item_selected.emit(temp_options.quality_options)
	window.selected = temp_options.window_options
	window.item_selected.emit(temp_options.window_options)

	language.selected = temp_options.language_options
	language.item_selected.emit(temp_options.language_options)

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
