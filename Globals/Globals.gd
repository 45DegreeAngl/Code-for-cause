extends Node
signal game_lost()

@onready var player_packed : PackedScene = preload("res://Prefabs/Player/test character.tscn")
const starting_amplitude = 0.04
const starting_frequency = 0.02
const starting_scale = 1.1
#const max_freq_amp = 0.2
##this is a float of 0% to 100%
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
@onready var drunkenness : float = 10:
	set(value):
		drunkenness = value
		
@onready var world_node : Node
@onready var filter_canvas : CanvasLayer

func _process(delta: float) -> void:
	var shader_mats :Array[ShaderMaterial] = MainShaderCanvas.get_shaders("drunk")
	for shader_mat in shader_mats:
		for shader_params:Dictionary in shader_mat.shader.get_shader_uniform_list():
			if shader_params["name"]=="amplitude":
				print("Changing amplitude to: ",str(drunkenness*0.008)," From: ",str(shader_mat.get_shader_parameter("amplitude")))
				var current_amplitude = shader_mat.get_shader_parameter("amplitude")
				var interp_amplitude = move_toward(current_amplitude, minf(0.04+drunkenness*0.008,0.2), delta/100)
				shader_mat.set_shader_parameter("amplitude",interp_amplitude)
			if shader_params["name"]=="frequency":
				print("Changing frequency")
				var current_frequency = shader_mat.get_shader_parameter("frequency")
				var interp_frequency = move_toward(current_frequency, minf(0.04+drunkenness*0.008,0.2), delta/100)
				shader_mat.set_shader_parameter("freqency",interp_frequency)
			if shader_params["name"]=="red_mult":
				var anger = 1+drunkenness/100.0
				shader_mat.set_shader_parameter("red_mult",anger)
