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
	"Crash 4":preload("res://Assets/Sounds/Crashes/Crash4.mp3"),
}

@onready var radio : Dictionary = {
	"8Rounds":preload("res://Assets/Sounds/Music/8RoundsFixed.mp3"),
	"Firearm":preload("res://Assets/Sounds/Music/FirearmFixed.mp3"),
	"Fish2":preload("res://Assets/Sounds/Music/Fish2Fixed.mp3"),
	"FishForgotten":preload("res://Assets/Sounds/Music/ForgetfulFixed.mp3"),
	"MoleInHole":preload("res://Assets/Sounds/Music/MoleFixed.mp3"),
	"NightcoreAHA":preload("res://Assets/Sounds/Music/NightcoreAhaFixed.mp3"),
	"Cat Ranch":preload("res://Assets/Sounds/Music/Cat Ranch Song.mp3"),
	"Underwater":preload("res://Assets/Sounds/Music/Underwater.mp3"),
	"GabesProstateObliteration":preload("res://Assets/Sounds/Music/My Lovely Obliteration.mp3")
}

@onready var pedestrian_packed:PackedScene = preload("res://Prefabs/Car/Average Sober Driver.tscn")
@onready var cop_packed:PackedScene = preload("res://Prefabs/the_cop.tscn")

var timer:float = 0

signal update_bottles
var car_contents:Dictionary = {"Beer":3,"Sake":2,"Jaeger":1}:
	set(value):
		car_contents = value
		update_bottles.emit()

const starting_amplitude = 0.04
const starting_frequency = 0.02
const starting_scale = 1.1
#const max_freq_amp = 0.2
##this is a float of 6% to 100%
@onready var zahness : float = 0:
	set(value):
		zahness = value
		var shader_mats :Array[ShaderMaterial] = MainShaderCanvas.get_shaders("drunk")
		for shader_mat in shader_mats:
			for shader_params:Dictionary in shader_mat.shader.get_shader_uniform_list():
				if shader_params["name"]=="red_mult":
					#3 red
					var green = 3 + 3*zahness/10.0
					shader_mat.set_shader_parameter("green_shift",green)
					#2 red
					var blue = 2 + 2*zahness/10.0
					shader_mat.set_shader_parameter("blue_shift",blue)
					#1 red
					var red = 1+zahness/10.0
					shader_mat.set_shader_parameter("red_shift",red)
@onready var game_over : bool = true
@onready var game_paused : bool = false
##change this boolean when tutorial ends
@onready var tutorial:bool = true
@onready var drunkenness : float = 20:
	set(value):
		if tutorial and value<20:
			value = 20
		MainShaderCanvas._update_bar(value)
		drunkenness = value

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

func format_seconds_as_time(seconds:float)->String:
	var hours = int(seconds / 3600)
	
	@warning_ignore("integer_division")
	var minutes = int((int(seconds)%3600)/60)
	
	var secs = int(seconds)%60
	
	var deciseconds = int((seconds-int(seconds))*10)
	return "%02d:%02d:%02d.%01d"%[hours, minutes, secs, deciseconds]
