@tool
extends MeshInstance3D

# --- GROUP: SETUP ---
@export_group("Setup")
@export var static_body_col_shape: CollisionShape3D
@export var tree_multimesh: MultiMeshInstance3D
@export var tree_mesh: Mesh

# --- GROUP: PARAMETERS ---
@export_group("Parameters")
@export_range(0.0, 5.0) var forest_density: float = 0.5
@export_range(0.0, 0.5) var tree_tilt: float = 0.1
@export_range(1.0, 3.0) var tree_scale_randomness: float = 1.5

# --- GROUP ACTIONS ---
@export_tool_button("Generate Forest") var gen_for_but = generate_forest
@export_tool_button("Clear Forest") var clr_for_but = clear_forest


#func _ready():
	#if not Engine.is_editor_hint():
		#generate_forest()

func clear_forest():
	# Guard for editor-only execution
	if not Engine.is_editor_hint():
		printerr("This function is intended for editor use only.")
		return

	if tree_multimesh:
		print("Clearing forest instances.")
		# Create a new, empty multimesh to replace the old one.
		var new_multimesh = MultiMesh.new()
		new_multimesh.mesh = tree_mesh # Keep the tree mesh reference
		# FIX: Mark the new resource to be saved with the scene
		new_multimesh.resource_local_to_scene = true
		tree_multimesh.multimesh = new_multimesh
		if Engine.is_editor_hint():
			EditorInterface.mark_scene_as_unsaved()

func generate_forest():
	if not static_body_col_shape or not tree_multimesh or not mesh or not tree_mesh:
		printerr("Required nodes or resources are not assigned.")
		return

	print("Generating forest...")

	var aabb = mesh.get_aabb()
	var box_shape = BoxShape3D.new()
	# FIX: Mark the resource to be saved with the scene
	box_shape.resource_local_to_scene = true
	box_shape.size = Vector3(aabb.size.x, aabb.size.y * 2.0 + 200, aabb.size.z)
	static_body_col_shape.shape = box_shape
	
	var multimesh = MultiMesh.new()
	# FIX: Mark the resource to be saved with the scene
	multimesh.resource_local_to_scene = true
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = tree_mesh

	var surface_area = aabb.size.x * aabb.size.z
	var initial_instance_count = int(surface_area * forest_density)
	multimesh.instance_count = initial_instance_count
	
	if initial_instance_count == 0:
		tree_multimesh.multimesh = multimesh
		return

	# --- OPTIMIZATION ---
	var is_plane_mesh = (mesh is PlaneMesh)
	var surface_data_cache = null
	if not is_plane_mesh:
		surface_data_cache = mesh.surface_get_arrays(0)

	var valid_instances = 0
	for i in range(initial_instance_count):
		var rand_x = randf_range(aabb.position.x, aabb.position.x + aabb.size.x)
		var rand_z = randf_range(aabb.position.z, aabb.position.z + aabb.size.z)
		
		var surface_position: Vector3
		var surface_normal: Vector3
		var is_valid_point = false

		if is_plane_mesh:
			surface_position = Vector3(rand_x, 0, rand_z)
			surface_normal = Vector3.UP
			is_valid_point = true
		else:
			var result = get_surface_data_at_point(surface_data_cache, Vector3(rand_x, 0, rand_z))
			if result:
				surface_position = result.position
				surface_normal = result.normal
				is_valid_point = true

		if is_valid_point:
			var instance_basis = Basis.looking_at(Vector3.FORWARD, surface_normal).orthonormalized()
			
			instance_basis = instance_basis.rotated(surface_normal, randf_range(0, TAU))
			instance_basis = instance_basis.rotated(instance_basis.x, randf_range(-tree_tilt, tree_tilt))
			instance_basis = instance_basis.rotated(instance_basis.z, randf_range(-tree_tilt, tree_tilt))
			
			var rand_scale = randf_range(1.0, tree_scale_randomness)
			instance_basis = instance_basis.scaled(Vector3.ONE * rand_scale)
			
			var instance_transform = Transform3D(instance_basis, surface_position)
			multimesh.set_instance_transform(valid_instances, instance_transform)
			valid_instances += 1
	
	multimesh.instance_count = valid_instances
	tree_multimesh.multimesh = multimesh
	tree_multimesh.custom_aabb = aabb
	
	print("Generated a forest with %d trees." % valid_instances)
	if Engine.is_editor_hint():
		EditorInterface.mark_scene_as_unsaved()

func get_surface_data_at_point(surface_arrays: Array, point: Vector3) -> Dictionary:
	var vertices = surface_arrays[Mesh.ARRAY_VERTEX]
	var indices = surface_arrays[Mesh.ARRAY_INDEX]
	
	var ray_origin = point + Vector3.UP * 1000.0
	var ray_dir = Vector3.DOWN
	
	if indices:
		for i in range(0, indices.size(), 3):
			var v0 = vertices[indices[i]]
			var v1 = vertices[indices[i+1]]
			var v2 = vertices[indices[i+2]]
			
			var intersection = Geometry3D.ray_intersects_triangle(ray_origin, ray_dir, v0, v1, v2)
			if intersection:
				var normal = (v2 - v0).cross(v1 - v0).normalized()
				return {"position": intersection, "normal": normal}
	else:
		for i in range(0, vertices.size(), 3):
			var v0 = vertices[i]
			var v1 = vertices[i+1]
			var v2 = vertices[i+2]

			var intersection = Geometry3D.ray_intersects_triangle(ray_origin, ray_dir, v0, v1, v2)
			if intersection:
				var normal = (v2 - v0).cross(v1 - v0).normalized()
				return {"position": intersection, "normal": normal}

	return {}
