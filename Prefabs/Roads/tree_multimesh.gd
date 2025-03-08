@tool
extends MultiMeshInstance3D

@export var tree_mesh : ArrayMesh
@export var tree_parent : Node3D
@export var generate : bool :
	set(val):
		replace_meshes()
		generate = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		pass

func replace_meshes():
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.instance_count = tree_parent.get_child_count()
	multimesh.mesh = tree_mesh
	global_transform = tree_parent.global_transform
	for i in range(tree_parent.get_child_count()):
		multimesh.set_instance_transform(i, tree_parent.get_child(i).global_transform)
	
