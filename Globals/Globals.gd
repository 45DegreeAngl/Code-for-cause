extends Node
@warning_ignore("unused_signal")
signal game_lost()
@warning_ignore("unused_signal")
signal game_won()

@onready var player_packed : PackedScene = preload("res://Prefabs/Player/test character.tscn")
@onready var player_voice_lines:Array = [
	preload("res://Assets/Sounds/Voice Lines/MoreBeer_Sad.mp3"),
	preload("res://Assets/Sounds/Voice Lines/MoreBeer_Angry.mp3"),
	preload("res://Assets/Sounds/Voice Lines/gluggluglug.mp3"),
	preload("res://Assets/Sounds/Voice Lines/ilovebeer.mp3")
]
@onready var world_voice_lines:Dictionary = {
"Pull Over":preload("res://Assets/Sounds/Voice Lines/Pull_Over.mp3"),
"Thank you come again":preload("res://Assets/Sounds/Voice Lines/Ty_Come_Again.mp3"),
"Best Driver":preload("res://Assets/Sounds/Voice Lines/Best_Driver.mp3")
}

@onready var crash_sounds:Dictionary = {
	"Crash 1":preload("res://Assets/Sounds/Crashes/CarCrash.mp3"),
	"Crash 2":preload("res://Assets/Sounds/Crashes/Crash2.mp3"),
	"Crash 3":preload("res://Assets/Sounds/Crashes/Crash3.mp3"),
	"Crash 4":preload("res://Assets/Sounds/Crashes/NewCrash1.mp3"),
	"Crash 5":preload("res://Assets/Sounds/Crashes/NewCrash2.mp3")
}

func _ready()->void:
	load_songs_from_folder()

signal controls_key_changed
@onready var current_controls_key:String = "KEYBOARD":
	set(value):
		current_controls_key = value
		controls_key_changed.emit()

@onready var controls_dictionary:Dictionary = {
"KEYBOARD":{"MOVE":"WASD","INTERACT":"E","ALTERNATIVE_INTERACT":"Q","GRAB":tr("KEYBOARD_MOUSE"),"JUMP":tr("KEYBOARD_SPACE")},
"CONTROLLER":{"MOVE":tr("JOYPAD_LEFT_STICK"),"INTERACT":tr("JOYPAD_LEFT_BUTTON"),"ALTERNATIVE_INTERACT":tr("JOYPAD_TOP_BUTTON"),"GRAB":tr("JOYPAD_TRIGGERS"),"JUMP":tr("JOYPAD_BOTTOM_BUTTON")}
}

func update_controls_text(event:InputEvent):
	if current_controls_key!="KEYBOARD" and (event is InputEventMouse or event is InputEventKey):
		current_controls_key = "KEYBOARD"
	elif current_controls_key!="CONTROLLER" and (event is InputEventJoypadMotion or event is InputEventJoypadButton):
		current_controls_key = "CONTROLLER"

func _input(event: InputEvent) -> void:
	update_controls_text(event)

@onready var debug_console_file : FileAccess
const MAX_SONGS_LOADED:int = 5
var load_fails : int = 0
func load_songs_from_folder():
	debug_console_file = FileAccess.open(GlobalWorkshop.user_paths["base"]+"CONSOLE.txt",FileAccess.WRITE)
	debug_console_file.store_string(str(Time.get_datetime_string_from_system(),"\n"))
	radio = {}
	radio_to_load = {}
	var file_array : Array = get_exported_files("res://Assets/Sounds/Music")#GlobalWorkshop.get_files_in_directory_unbounded_iterative("res://Assets/Sounds/Music")
	file_array.append_array(GlobalWorkshop.get_files_in_directory_unbounded_iterative(GlobalWorkshop.user_paths["workshop_music"]))
	#now file_array is a list of file paths, 
	#check each and every single one of them to then fill radio to load
	for file:String in file_array:
		if file.contains(".import"):
			#print("skipping import")
			continue
		
		var audio_stream = proper_audio_load(file)
		if audio_stream and audio_stream is AudioStream:
			debug_console_file.store_string(str("Successfully loaded: ",file,"\n"))
			print("Successfully loaded: ",file)
			var nickname:String = file.substr(file.rfind("/")+1)
			nickname = nickname.substr(0,nickname.find("."))
			radio_to_load[nickname] = file
		else:
			print("Failed to load, not adding : ",file," to radio_to_load")
			debug_console_file.store_string(str("Failed to load, not adding : ",file," to radio_to_load","\n"))
	load_fails = 0
	
	while radio.size()<MAX_SONGS_LOADED && radio.size()<radio_to_load.size() && load_fails<MAX_SONGS_LOADED:
		load_random_song()
	
	debug_console_file.close()

##remove songs that appear in radio, but not in radio_to_load
func clear_impossible_queues():
	for nickname in radio.keys():
		print(nickname)
		if !radio_to_load.has(nickname):
			print("Balls Removing: ",nickname)
			radio.erase(nickname)

func proper_audio_load(file_path:String)->AudioStream:
	var stream : AudioStream
	#if file_path.contains(".remap"):
		#pass
	if file_path.contains("res://"):
		stream = ResourceLoader.load(file_path)
	elif file_path.contains("user://"):
		if file_path.contains(".mp3"):
			stream = AudioStreamMP3.load_from_file(file_path)
		elif file_path.contains(".ogg"):
			stream = AudioStreamOggVorbis.load_from_file(file_path)
		elif file_path.contains(".wav"):
			stream = AudioStreamWAV.load_from_file(file_path)
		else:
			stream = null

	return stream

func load_random_song():
	if radio_to_load.is_empty():
		load_songs_from_folder()
	var chosen_key:String = radio_to_load.keys().pick_random()
	var audio_stream = proper_audio_load(radio_to_load[chosen_key])
	if audio_stream and audio_stream is AudioStream:
		print("Successfully loaded song nicknamed: ",chosen_key)
		radio[chosen_key] = audio_stream
	elif(load_fails<MAX_SONGS_LOADED):
		load_fails+=1
		#print("Failed to load: ",chosen_key)
		#attempt to load again
		load_random_song()

@onready var radio_to_load:Dictionary={
}

@onready var radio : Dictionary = {
}

@onready var car_colors:Dictionary = {
	#Color(1,1,1,1):"Pure White",
	Color.ALICE_BLUE: "Alice Blue",
	Color.ANTIQUE_WHITE: "Antique White",
	Color.AQUA: "Aqua",
	Color.AQUAMARINE: "Aquamarine",
	Color.AZURE: "Azure",
	Color.BEIGE: "Beige",
	Color.BISQUE: "Bisque",
	Color.BLACK: "Black",
	Color.BLANCHED_ALMOND: "Blanched Almond",
	Color.BROWN: "Brown",
	Color.BURLYWOOD: "Burlywood",
	Color.CHARTREUSE: "Chartreuse",
	Color.CHOCOLATE: "Chocolate",
	Color.CORAL: "Coral",
	Color.CORNSILK: "Cornsilk",
	Color.CRIMSON: "Crimson",
	Color.DARK_GOLDENROD: "Dark Goldenrod",
	Color.DARK_GRAY: "Dark Gray",
	Color.DARK_GREEN: "Dark Green",
	Color.DARK_KHAKI: "Dark Khaki",
	Color.DARK_MAGENTA: "Dark Magenta",
	Color.DARK_OLIVE_GREEN: "Dark Olive Green",
	Color.DARK_ORANGE: "Dark Orange",
	Color.DARK_ORCHID: "Dark Orchid",
	Color.DARK_RED: "Dark Red",
	Color.DARK_SALMON: "Dark Salmon",
	Color.DARK_SEA_GREEN: "Dark Sea Green",
	Color.DARK_SLATE_GRAY: "Dark Slate Gray",
	Color.DARK_VIOLET: "Dark Violet",
	Color.DEEP_PINK: "Deep Pink",
	Color.DIM_GRAY: "Dim Gray",
	Color.FIREBRICK: "Firebrick",
	Color.FLORAL_WHITE: "Floral White",
	Color.FOREST_GREEN: "Forest Green",
	Color.FUCHSIA: "Fuchsia",
	Color.GAINSBORO: "Gainsboro",
	Color.GHOST_WHITE: "Ghost White",
	Color.GOLD: "Gold"
}


@onready var pedestrian_packed:PackedScene = preload("res://Prefabs/Car/Average Sober Driver.tscn")
@onready var cop_packed:PackedScene = preload("res://Prefabs/the_cop.tscn")

var timer:float = 0
var is_cheater : bool = false

signal update_bottles
var car_contents:Dictionary = {"Beer":1,"Sake":0,"Jaeger":0}:
	set(value):
		car_contents = value
		update_bottles.emit()

const starting_amplitude = 0.04
const starting_frequency = 0.02
const starting_scale = 1.1
#const max_freq_amp = 0.2
##this is a float of 6% to 100%
@onready var game_over : bool = true
@onready var game_paused : bool = false
##change this boolean when tutorial ends
@onready var tutorial:bool = true
@onready var motion_sickness:bool = false
@onready var drunkenness : float = 20:
	set(value):
		if tutorial and value<drunkenness:
			value = drunkenness
		MainShaderCanvas._update_bar(value)
		drunkenness = value
		
		if motion_sickness:
			var shader_mats :Array[ShaderMaterial] = MainShaderCanvas.get_shaders("drunk")
			for shader_mat in shader_mats:
				for shader_params:Dictionary in shader_mat.shader.get_shader_uniform_list():
					if shader_params["name"]=="red_mult":
						#3 red
						var green = 3 + 3*drunkenness/10.0
						shader_mat.set_shader_parameter("green_shift",green)
						#2 red
						var blue = 2 + 2*drunkenness/10.0
						shader_mat.set_shader_parameter("blue_shift",blue)
						#1 red
						var red = 1+drunkenness/10.0
						shader_mat.set_shader_parameter("red_shift",red)
		else:
			var shader_mats :Array[ShaderMaterial] = MainShaderCanvas.get_shaders("drunk")
			for shader_mat in shader_mats:
				for shader_params:Dictionary in shader_mat.shader.get_shader_uniform_list():
					if shader_params["name"]=="red_mult":
						#3 red
						var green = 3
						shader_mat.set_shader_parameter("green_shift",green)
						#2 red
						var blue = 2
						shader_mat.set_shader_parameter("blue_shift",blue)
						#1 red
						var red = 1
						shader_mat.set_shader_parameter("red_shift",red)

func reset_stats():
	sober_drivers_hit = 0
	total_alcohol_bought = 0
	litter_count = 0
	car_flip_count = 0
@onready var sober_drivers_hit : int = 0
@onready var total_alcohol_bought : int = 0
@onready var litter_count : int = 0
@onready var car_flip_count : int = 0
@onready var detected:bool = false

@onready var world_node : Node

@onready var filter_canvas : CanvasLayer
@onready var player_vehicle : VehicleBody3D
@onready var player_character : Node3D

func _process(_delta: float) -> void:
	var shader_mats :Array[ShaderMaterial] = MainShaderCanvas.get_shaders("drunk")
	for shader_mat in shader_mats:
		for shader_params:Dictionary in shader_mat.shader.get_shader_uniform_list():
			#if shader_params["name"]=="amplitude":
				#print("Changing amplitude to: ",str(minf(0.04+drunkenness*0.008,0.2))," From: ",str(shader_mat.get_shader_parameter("amplitude")))
				#var current_amplitude = shader_mat.get_shader_parameter("amplitude")
				#var interp_amplitude = minf(0.04+drunkenness*0.008,0.2)#move_toward(current_amplitude, minf(0.04+drunkenness*0.008,0.2), delta/100)
				##print(interp_amplitude)
				#shader_mat.set_shader_parameter("amplitude",interp_amplitude)
			#if shader_params["name"]=="frequency":
				##print("Changing frequency")
				#var current_frequency = shader_mat.get_shader_parameter("frequency")
				#var interp_frequency = minf(0.04+drunkenness*0.008,0.2)#move_toward(current_frequency, minf(0.04+drunkenness*0.008,0.2), delta/100)
				#shader_mat.set_shader_parameter("freqency",interp_frequency)
			if shader_params["name"]=="red_mult":
				var anger = 1+drunkenness/100.0
				shader_mat.set_shader_parameter("red_mult",anger)

const roads_to_win_options : Array[int]=[10,25,50,100,int(INF)]

const CAR_CONT_SENS : float = 0.1
const PER_CONT_SENS : float = 4.0
const CAR_MOUS_SENS : float = 0.001
const PER_MOUS_SENS : float = 0.1

var car_cont_sens : float = 0.1
var per_cont_sens : float = 4
var car_mous_sens : float = 0.001
var per_mous_sens : float = 0.1

@onready var roads_to_win : int = 50

func format_seconds_as_time(seconds:float)->String:
	var hours = int(seconds / 3600)
	
	@warning_ignore("integer_division")
	var minutes = int((int(seconds)%3600)/60)
	
	var secs = int(seconds)%60
	
	var deciseconds = int((seconds-int(seconds))*10)
	return "%02d:%02d:%02d.%01d"%[hours, minutes, secs, deciseconds]

func get_exported_files(directory:String)->Array:
	var files = []
	var resources = ResourceLoader.list_directory(directory)
	for res in resources:
		if !res.ends_with("/"):
			files.append(directory+"/"+res)
	return files
