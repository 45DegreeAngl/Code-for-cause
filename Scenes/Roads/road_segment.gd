extends Node3D
class_name RoadSegment
signal increment_player_road_counter()

var index : int
var passed : bool = false

@export var nav_region : NavigationRegion3D
@export var nav_curve : Path3D

@export var debris_node : Node3D
@onready var spawn_driver_timer : Timer

func _ready():
	spawn_driver_timer =  Timer.new()
	if debris_node:
		spawn_debris()
	add_child(spawn_driver_timer)
	spawn_driver_timer.autostart = false
	spawn_driver_timer.one_shot = true
	spawn_driver_timer.wait_time = randf_range(3.0,10.0)
	spawn_driver_timer.timeout.connect(spawn_timer_timeout)
	#for child in get_children():
		#if child is NavigationRegion3D:
			#if child.is_baking():
				#print("awaiting to bake :",child)
				##await child.bake_finished
				#for grand_child in child.get_children():
					#if grand_child is GridMap:
						#nav_region.bake_navigation_mesh()
						##if grand_child.has_meta("Road") and grand_child.get_meta("Road"):
							##nav_region.bake_navigation_mesh(false)#bake off of thread
						##else:
							##nav_region.bake_navigation_mesh(true)#bake on thread
			#else:
				#print("baking :",child)
				#for grand_child in child.get_children():
					#if grand_child is GridMap:
						#nav_region.bake_navigation_mesh()
						#if grand_child.has_meta("Road") and grand_child.get_meta("Road"):
							#nav_region.bake_navigation_mesh(false)#bake off of thread
						#else:
							#nav_region.bake_navigation_mesh(true)#bake on thread


func spawn_debris():
	for child in debris_node.get_children():
		if not child.has_method("spawn_debris"):
			continue
		child.spawn_debris()

func _on_exit_area_body_entered(body: Node3D) -> void:
	if passed:
		return
	if body == Globals.player_vehicle:
		passed = true
		increment_player_road_counter.emit()
		spawn_driver_timer.start()
 
func disable_tutorial(body:Node3D):
	if body == Globals.player_vehicle:
		if Globals.tutorial:
			print("TUTORIAL END")
			Globals.tutorial = false

@export var driver_spawns : Node3D = null
signal driver_spawned(driver:VehicleBody3D)
#$Pedestrians $Cops
func spawn_drivers():
	if !driver_spawns or randi_range(0,9)==0:
		print("not spawning driver")
		return
	if randi_range(0,2) == 0:#Cop Spawn
		var result = spawn_individual_driver(Globals.cop_array.pick_random(),Globals.world_node.get_node("Cops"))
		if result:
			driver_spawned.emit(result)
	if randi_range(0,3)!=0:#Pedestrian Spawn
		var result = spawn_individual_driver(Globals.pedestrian_array.pick_random(),Globals.world_node.get_node("Pedestrians"))
		if result:
			driver_spawned.emit(result)

func spawn_individual_driver(packed:PackedScene,driver_type_node:Node3D)->VehicleBody3D:
	var chosen_marker:Marker3D = driver_spawns.get_children().pick_random()
	if chosen_marker == null:
		return null
	var driver_instance : VehicleBody3D = packed.instantiate()
	driver_type_node.add_child(driver_instance)
	driver_instance.target = Globals.player_vehicle
	driver_instance.process_mode = Node.PROCESS_MODE_DISABLED
	driver_instance.backwards = [true,false,false].pick_random()
	driver_instance.global_position = chosen_marker.global_position
	driver_instance.process_mode = Node.PROCESS_MODE_INHERIT
	
	if driver_instance.backwards:
		print("Spawning backwards")
	chosen_marker.reparent(self)
	chosen_marker.queue_free()
	return driver_instance

func spawn_timer_timeout():
	if !driver_spawns or randi_range(0,9)==0:
		print("not spawning driver")
		return
	print("SPAWNING RESIDUAL DRIVERS")
	if randi_range(0,1) == 0:#Cop Spawn
		var result = spawn_residual_driver(Globals.cop_array.pick_random(),Globals.world_node.get_node("Cops"))
		if result:
			driver_spawned.emit(result)
	if randi_range(0,3)!=0:#Pedestrian Spawn
		var result = spawn_residual_driver(Globals.pedestrian_array.pick_random(),Globals.world_node.get_node("Pedestrians"))
		if result:
			driver_spawned.emit(result)

func spawn_residual_driver(packed:PackedScene,driver_type_node:Node3D)->VehicleBody3D:
	if driver_spawns.get_child_count()<1:
		return null
	var chosen_marker:Marker3D = driver_spawns.get_children().pick_random()
	if chosen_marker == null:
		return null
	var driver_instance : VehicleBody3D = packed.instantiate()
	driver_type_node.add_child(driver_instance)
	driver_instance.target = Globals.player_vehicle
	driver_instance.process_mode = Node.PROCESS_MODE_DISABLED
	driver_instance.backwards = false
	driver_instance.global_position = chosen_marker.global_position
	driver_instance.process_mode = Node.PROCESS_MODE_INHERIT
	chosen_marker.reparent(self)
	chosen_marker.queue_free()
	return driver_instance
