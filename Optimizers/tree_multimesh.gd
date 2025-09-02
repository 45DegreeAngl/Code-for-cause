@tool
extends MultiMeshInstance3D

@export var tree_mesh : ArrayMesh
@export var tree_parent : Node3D
@export var generate : bool :
	set(val):
		replace_meshes()
		generate = false

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		pass

func replace_meshes():
	if !tree_parent:
		printerr("NO TREE PARENT SELECTED")
		return

	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.use_colors = true
	
	var instance_count = tree_parent.get_child_count()
	multimesh.instance_count = instance_count
	multimesh.mesh = tree_mesh
	
	# Place the MultiMeshInstance node at the same location as the parent.
	# All instance transforms will be relative to this position.
	global_transform = tree_parent.global_transform
	
	# We need this to convert from world space to the MultiMesh's local space.
	var parent_inverse_transform = tree_parent.global_transform.affine_inverse()

	for i in range(instance_count):
		var child = tree_parent.get_child(i)
		# It's safer to check if the child is a Node3D and has children
		if not child is Node3D or child.get_child_count() == 0:
			continue # Skip this child if it's not what we expect

		var child_mesh = child.get_child(0)
		
		# --- CORRECTED TRANSFORM LOGIC ---
		# 1. Get the final global transform of the visible mesh. This single
		#    transform already includes the position of 'child' and the scale of 'child_mesh'.
		var mesh_global_transform = child_mesh.global_transform
		
		# 2. Convert that global transform into a local transform relative to our
		#    MultiMeshInstance node's position. This is the correct value to set.
		var instance_transform = parent_inverse_transform * mesh_global_transform
		
		multimesh.set_instance_transform(i, instance_transform)
		# -----------------------------------
		
		# Set the random value for the wind shader.
		var custom_data = Color(randf(), 0.0, 0.0, 0.0)
		multimesh.set_instance_custom_data(i, custom_data)
