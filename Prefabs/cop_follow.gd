extends PathFollow3D

@export var speed: float = 1 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $RayCast3D.is_colliding():
		$Mesh.global_position = $RayCast3D.get_collision_point()
		align_with_ground()
		$Mesh.rotation.y = rotation.y
	if get_parent() is Path3D:
		progress += speed * delta
		if progress_ratio >= 0.99:
			assign_to_nearest_path()
			progress = 0

func align_with_ground():
	var normalized_target = $RayCast3D.get_collision_normal().normalized()
	var current_y = $Mesh.transform.basis.y
	if current_y.is_equal_approx(normalized_target):
		return
	var rotation_axis = current_y.cross(normalized_target).normalized()
	if rotation_axis != Vector3.ZERO:
		var angle = current_y.angle_to(normalized_target)
		$Mesh.rotate(rotation_axis.normalized(), angle)
	

func assign_to_nearest_path():
	var path = find_nearest_path()
	if path == null:
		printerr("No paths found!")
	if path == get_parent():
		printerr("Path equal to parent!")
	reparent(path)
func find_nearest_path() -> Path3D:
	var paths : Array[Node] = get_tree().get_nodes_in_group("road_path")
	var closest_path = null
	var min_dist = INF
	for path in paths:
		var dist = global_position.distance_to(path.global_position)
		if dist < min_dist:
			min_dist = dist
			closest_path = path
	return closest_path


func _on_segment_spawner_road_generated() -> void:
	assign_to_nearest_path()
