extends Node

@export var game_packed : PackedScene
@export var TitleMusicPlayer :AudioStreamPlayer

func _ready()->void:
	Globals.game_lost.connect(_on_lose)
	Globals.game_won.connect(_on_win)
	$AnimationPlayer.play("Cop_Lights")
	set_sliders()

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
			$"Game Over/RichTextLabel".append_text("GAME OVER YOU'RE [color=red]SOBER")
			
		"Cops":
			$"Game Over/RichTextLabel".append_text("GAME OVER YOU'RE [color=red]HIT BY A COP")
	$"Game Over/Label".text = "YOU SURVIVED FOR: "+Globals.format_seconds_as_time(Globals.timer)
	MainShaderCanvas.visible = false
	Globals.tutorial = true
	Globals.game_paused = false
	$Options.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#$"Game World".process_mode = Node.PROCESS_MODE_DISABLED

func _on_win():
	if Globals.game_over:
		return
	$"YOU WIN".visible = true
	Globals.game_over = true
	$"YOU WIN/Label2".text = "YOUR TIME: "+Globals.format_seconds_as_time(Globals.timer)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MainShaderCanvas.visible = false
	Globals.tutorial = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#$"Game World".process_mode = Node.PROCESS_MODE_DISABLED

func _process(_delta: float) -> void:
	if Globals.game_over or $"Game Over".visible or $"YOU WIN".visible or $"Main Menu".visible:
		return
	if Input.is_action_just_pressed("Esc") or Input.is_action_just_pressed("P"):
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

func _on_start_pressed() -> void:
	Globals.drunkenness = 20
	for child in $"Game World".get_children():
		child.queue_free()
	#$"Game World".process_mode = Node.PROCESS_MODE_INHERIT
	main_menu()
	$"Main Menu".visible = false
	$Animations.visible = true
	$Animations.get_child(0).play_intro()

func _on_start_game() ->void:
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
	var temp :Control= load("res://intro_comic.tscn").instantiate()
	$Animations.add_child(temp)
	temp.find_child("GoToGame").pressed.connect(_on_start_game)
	$"Options/true options/VBoxContainer/Become Sober".visible = true

func _on_options_pressed() -> void:
	$Options.visible = true
	$"Main Menu".visible = false
	$"Options/true options/VBoxContainer/Back".visible = true
	$"Options/true options/VBoxContainer/Become Sober".visible = false


func _on_credits_pressed() -> void:
	$Credits.visible = true
	$"Main Menu".visible = false

func main_menu():
	$MenuGeometry.visible = true
	$MenuGeometry/SubViewportContainer.visible = true
	$Credits.visible = false
	$Options.visible = false
	$"Main Menu".visible = true
	$"Game Over".visible = false
	$"YOU WIN".visible = false


func on_back()->void:
	main_menu()
	for child in $"Game World".get_children():
		child.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if !TitleMusicPlayer.playing:
		TitleMusicPlayer.playing = true

###OPTIONS
@onready var master: HSlider = $Options/PanelContainer/VBoxContainer/PanelContainer/HBoxContainer/Master
@onready var voice: HSlider = $Options/PanelContainer/VBoxContainer/PanelContainer/HBoxContainer/Voice
@onready var radio: HSlider = $Options/PanelContainer/VBoxContainer/PanelContainer/HBoxContainer/Radio
@onready var world_sounds: HSlider = $"Options/PanelContainer/VBoxContainer/PanelContainer/HBoxContainer/World Sounds"

func set_sliders():
	master.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	voice.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Voice")))
	radio.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Radio")))
	world_sounds.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sound Effect")))

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
	Globals.motion_sickness = toggled_on
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

func _on_become_sober_pressed() -> void:
	Globals.game_lost.emit("Sober")
