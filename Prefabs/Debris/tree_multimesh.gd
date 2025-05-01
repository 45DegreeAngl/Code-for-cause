@tool
extends MultiMeshInstance3D

@export var tree_mesh : ArrayMesh
@export var tree_parent : Node3D
@export var generate : bool :
	set(val):
		replace_meshes()
		generate = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		pass

func replace_meshes():
	if !tree_parent:
		printerr("NO TREE PARENT SELECTED")
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.instance_count = tree_parent.get_child_count()
	multimesh.mesh = tree_mesh
	global_transform = tree_parent.global_transform
	for i in range(tree_parent.get_child_count()):
		var child = tree_parent.get_child(i)
		var child_mesh = child.get_child(0)
		
		var end_transform : Transform3D = child.global_transform
		
		var end_transform_origin = end_transform.origin
		
		var end_scale = child_mesh.scale
		
		end_transform = end_transform.scaled(end_scale)
		
		end_transform.origin = end_transform_origin
		
		multimesh.set_instance_transform(i, end_transform)
	
