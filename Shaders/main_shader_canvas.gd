extends CanvasLayer

@export var max_drunk_effect_multiplier = 8

##dictionary is as follows: String:Array[Control,Rectangle(ShaderA),Rectangle(ShaderB),...]
@onready var filter_dict : Dictionary = {"drunk":[$Drunk,$Drunk/WobbleShader,$Drunk/ChromaticShader],
"BeerMeter":[$"Beer Meter"]}

func toggle_filter(key:String):
	var control:Control = filter_dict[key][0]
	control.visible = !control.visible


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

func _ready():
	var shader_mats = get_shaders("drunk")[0].shader.get_shader_uniform_list()
	print(shader_mats)

func _update_bar(value):
	$"Beer Meter/TextureProgressBar".value = value
