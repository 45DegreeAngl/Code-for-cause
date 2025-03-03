extends PathFollow3D

@export var speed = 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if get_parent() is Path3D:
		progress += speed * delta
		if progress_ratio >= 0.99:
			assign_to_nearest_path()
			progress = 0

func assign_to_nearest_path():
	var path = find_nearest_path()
	if path == null:
		printerr("No paths found!")
	if path == get_parent():
		printerr("Path equal to parent!")
	reparent(path)
func find_nearest_path() -> Path3D:
	var paths : Array[Node] = get_tree().get_nodes_in_group("road_path")
	var closest_path = paths[0]
	var min_dist = global_position.distance_to(paths[0].global_position)
	for i in range(2, paths.size()):
		var dist = global_position.distance_to(paths[i].global_position)
		if dist < min_dist:
			min_dist = dist
			closest_path = paths[i]
	return closest_path


func _on_segment_spawner_road_generated() -> void:
	assign_to_nearest_path()
