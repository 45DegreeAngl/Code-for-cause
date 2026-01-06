# RoadSpawner.gd
extends Node

## Instantiates, places, connects, and removes road segments in the scene.
## Does not contain any game logic for *which* road to spawn.

const MAX_ACTIVE_ROADS: int = 9

@export var road_node: Node3D
@export var glob_path: Path3D

@export var previous_road: Node3D

func _ready():
	Globals.driving_path = glob_path
	# The first road is special, it needs a "previous_road" to connect to.
	# We can create a dummy starting point.
	#var start_node = Node3D.new()
	#start_node.name = "StartPoint"
	#road_node.add_child(start_node)
	#var exit_marker = Marker3D.new()
	#start_node.add_child(exit_marker)
	#exit_marker.name = "Exit"
	#previous_road = start_node

##this script needs to be redone, takes 60 ms at a point(a lot)
func append_segment(segment_scene: PackedScene):
	if not segment_scene:
		printerr("Spawner received an invalid scene to append.")
		return
	var instanced_segment = segment_scene.instantiate()
	await get_tree().physics_frame
	instanced_segment.visible = false
	road_node.add_child(instanced_segment)
	instanced_segment.global_position = previous_road.find_child("Exit").global_position
	#instanced_segment.ready_road()
	# Connect to the manager's increment function
	if instanced_segment.has_signal("increment_player_road_counter"):
		# Assumes RoadManager is this node's parent
		var road_manager = get_parent() 
		instanced_segment.increment_player_road_counter.connect(road_manager.increment_player_road)
	previous_road = instanced_segment
	_stitch_nav_path(instanced_segment)
	
	instanced_segment.visible = true
	if instanced_segment.has_method("spawn_drivers"):
		instanced_segment.spawn_drivers()

func _stitch_nav_path(segment: Node3D):
	if "nav_curve" in segment and segment.nav_curve is Path3D:
		var local_path: Path3D = segment.nav_curve
		var local_curve: Curve3D = local_path.curve
		if local_curve:
			var start_index = 1 if glob_path.curve.get_point_count() > 0 else 0
			for i in range(start_index, local_curve.get_point_count()):
				var local_pos = local_curve.get_point_position(i)
				var local_in = local_curve.get_point_in(i)
				var local_out = local_curve.get_point_out(i)
				
				var world_pos = local_path.to_global(local_pos)
				var world_in = local_path.to_global(local_in + local_pos) - world_pos
				var world_out = local_path.to_global(local_out + local_pos) - world_pos
				
				glob_path.curve.add_point(world_pos, world_in, world_out)
	else:
		print("Warning: Road segment '", segment.name, "' script is missing 'nav_curve' variable.")


func remove_oldest_segment_if_needed():
	# We subtract 1 because our dummy "StartPoint" is also a child
	if road_node.get_child_count() - 1 > MAX_ACTIVE_ROADS:
		var road_to_remove: Node3D = road_node.get_child(1) # Child 0 is the dummy start point
		
		# Remove nav points
		if "nav_curve" in road_to_remove and road_to_remove.nav_curve is Path3D:
			var path_to_remove: Path3D = road_to_remove.nav_curve
			# The -1 is to avoid removing the connecting point to the next segment
			var points_to_remove = path_to_remove.curve.get_point_count() - 1 
			points_to_remove = max(0, points_to_remove)
			for _i in range(points_to_remove):
				if glob_path.curve.get_point_count() > 0:
					glob_path.curve.remove_point(0)
		
		# Remove associated NPCs
		var world_node = Globals.world_node
		for cop: Node3D in world_node.find_child("Cops").get_children():
			if cop.global_position.z > road_to_remove.global_position.z:
				cop.queue_free()
		for pedestrian: Node3D in world_node.find_child("Pedestrians").get_children():
			if pedestrian.global_position.z > road_to_remove.global_position.z:
				pedestrian.queue_free()

		road_to_remove.queue_free()

# --- UTILITY FUNCTIONS ---
func get_road_at_pos(glob_pos: Vector3) -> Node:
	var last_road: Node = road_node.get_children().back()
	for index in range(road_node.get_child_count()):
		var cur_road = road_node.get_child(index)
		# Skip the dummy StartPoint
		if index == 0:
			continue
		if glob_pos.z > cur_road.global_position.z:
			var prev_road_index = max(1, index - 1)
			return road_node.get_child(prev_road_index)
	return last_road

func get_next_road(cur: Node, reverse: bool = false) -> Node:
	var road_array: Array = road_node.get_children()
	var result_index = road_array.find(cur)
	
	if result_index == -1: # Not found
		return null
	
	if reverse:
		result_index = maxi(1, result_index - 1) # Min index is 1 to avoid StartPoint
	else:
		result_index = mini(road_array.size() - 1, result_index + 1)
	
	return road_array[result_index]
