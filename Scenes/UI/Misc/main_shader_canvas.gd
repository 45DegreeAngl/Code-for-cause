extends CanvasLayer

@export var max_drunk_effect_multiplier = 8

##dictionary is as follows: String:Array[Control,Rectangle(ShaderA),Rectangle(ShaderB),...]
@onready var filter_dict : Dictionary = {"drunk":[$Drunk,$Drunk/WobbleShader,$Drunk/ChromaticShader,$Drunk/VingetteShader],
"BeerMeter":[$"Beer Meter"]}

func toggle_filter(key:String):
	var control:Control = filter_dict[key][0]
	control.visible = !control.visible

func set_beer_visibility(visibility:bool):
	var control : Control = filter_dict["BeerMeter"][0]
	control.visible = visibility

func get_shaders(key:String)->Array[ShaderMaterial]:
	var temp : Array[ShaderMaterial]
	for elem in filter_dict[key]:
		if elem is ColorRect:
			if elem.material is ShaderMaterial:
				temp.append(elem.material)
	return temp

func _process(delta: float) -> void:
	var drunk_percent = Globals.drunkenness / 100.0
	var shader_intensity = get_shaders("drunk")[0].get_shader_parameter("drunkScale")
	get_shaders("drunk")[0].set_shader_parameter("drunkScale", move_toward(shader_intensity, drunk_percent, delta * 0.1))

func update_drunkenness(drunkenness:float):
	if self!= MainShaderCanvas:
		print("not main shader updating")
	_update_bar(drunkenness)
	if Globals.motion_sickness:
		var shader_mats :Array[ShaderMaterial] = get_shaders("drunk")
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

func _ready():
	var shader_mats = get_shaders("drunk")[0].shader.get_shader_uniform_list()
	Globals.update_drunkenness.connect(update_drunkenness)
	print(shader_mats)

func _update_bar(value):
	$"Beer Meter/TextureProgressBar".value = value
