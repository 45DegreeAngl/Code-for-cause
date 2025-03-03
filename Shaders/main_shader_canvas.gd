extends CanvasLayer

##dictionary is as follows: String:Array[Control,Rectangle(ShaderA),Rectangle(ShaderB),...]
@onready var filter_dict : Dictionary = {"drunk":[$Drunk,$Drunk/WobbleShader,$Drunk/ChromaticShader]}

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

func _ready():
	var shader_mats = get_shaders("drunk")[0].shader.get_shader_uniform_list()
	print(shader_mats)
