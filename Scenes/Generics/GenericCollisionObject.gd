@tool
##this script allows for simple convex objects be scaled with their model in a casual way
extends CollisionObject3D
class_name GenericCollisionObject

var _collision_shape_node: CollisionShape3D

## The object's visual and physical mesh.
@export var object_mesh: Mesh:
	set(value):
		if object_mesh == value:
			return
		object_mesh = value
		if not is_node_ready():
			await ready
		_update_visuals()
		_update_collision()

## The scale of the object's visual mesh and collision shape.
@export var generic_scale: Vector3 = Vector3.ONE:
	set(value):
		if generic_scale == value:
			return
		generic_scale = value
		if not is_node_ready():
			await ready
		_update_visuals()
		_update_collision()


func _ready() -> void:
	_update_visuals()
	_update_collision()

func _update_visuals() -> void:
	var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance")
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance"
		add_child(mesh_instance)
		if Engine.is_editor_hint():
			mesh_instance.owner = get_tree().edited_scene_root
			mesh_instance.set_meta("_edit_lock_",true)
			
	mesh_instance.mesh = object_mesh
	mesh_instance.scale = generic_scale
	
	# Ensure the mesh instance is always locked in the editor.
	if Engine.is_editor_hint():
		mesh_instance.set_meta("_edit_lock_", true)

func _update_collision() -> void:
	# Remove and delete the old collision shape immediately.
	for child in get_children():
		if child is CollisionShape3D:
			remove_child(child)
			child.free()

	if not object_mesh:
		return

	# Create a temporary mesh with the scale applied to its vertices.
	var scaled_mesh := ArrayMesh.new()
	for i in range(object_mesh.get_surface_count()):
		var surface_arrays = object_mesh.surface_get_arrays(i)
		var vertex_array: PackedVector3Array = surface_arrays[ArrayMesh.ARRAY_VERTEX]
		
		for j in range(vertex_array.size()):
			vertex_array[j] *= generic_scale
			
		surface_arrays[ArrayMesh.ARRAY_VERTEX] = vertex_array
		
		scaled_mesh.add_surface_from_arrays(
			object_mesh.surface_get_primitive_type(i),
			surface_arrays
		)

	var new_collision_shape := CollisionShape3D.new()
	new_collision_shape.name = "CollisionShape3D"
	new_collision_shape.shape = scaled_mesh.create_convex_shape()
	new_collision_shape.scale = Vector3.ONE
	
	add_child(new_collision_shape)
	if Engine.is_editor_hint():
		new_collision_shape.owner = get_tree().edited_scene_root
		# Lock the node in the editor to prevent accidental selection.
		new_collision_shape.set_meta("_edit_lock_", true)

	_collision_shape_node = new_collision_shape
