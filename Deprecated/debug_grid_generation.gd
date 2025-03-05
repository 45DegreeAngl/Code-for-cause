extends GridMap

@onready var meshes : MeshLibrary = mesh_library
##saved in array by mesh name:Array[id,vector4,vector3]
#vector4 = logical connection mappings UP RIGHT DOWN LEFT
#vector3 = xy position offset z rotation in radians
var mesh_dict : Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for mesh_id in meshes.get_item_list():
		mesh_dict[meshes.get_item_name(mesh_id)] = [mesh_id,Vector4.ZERO,Vector3.ZERO]
	
	##raised straight
	#mesh_dict[mesh_dict.keys()[0]][1] = Vector4(1,0,1,0)
	#mesh_dict[mesh_dict.keys()[0]][2] = Vector3(0,0,0)
	#
	##raised small turn
	#mesh_dict[mesh_dict.keys()[2]][1] = Vector4(0,1,1,0)
	#mesh_dict[mesh_dict.keys()[2]][2] = Vector3(0,0,0)
	#
	##raised big turn
	#mesh_dict[mesh_dict.keys()[3]][1] = Vector4(0,1,1,0)
	#mesh_dict[mesh_dict.keys()[3]][2] = Vector3(1,0,0)
