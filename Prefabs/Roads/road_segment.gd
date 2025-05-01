extends Node3D
class_name RoadSegment
signal increment_player_road_counter()

var index : int
var passed : bool = false

@export var nav_region : NavigationRegion3D
@export var nav_curve : Path3D

@export var debris_node : Node3D

func _ready():
	if debris_node:
		spawn_debris()

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
	if randi_range(0,3) == 0:#Cop Spawn
		driver_spawned.emit(spawn_individual_driver(Globals.cop_packed,Globals.world_node.get_node("Cops")))
	if randi_range(0,3)!=0:#Pedestrian Spawn
		driver_spawned.emit(spawn_individual_driver(Globals.pedestrian_packed,Globals.world_node.get_node("Pedestrians")))

func spawn_individual_driver(packed:PackedScene,driver_type_node:Node3D)->VehicleBody3D:
	var chosen_marker:Marker3D = driver_spawns.get_children().pick_random()
	var driver_instance : VehicleBody3D = packed.instantiate()
	driver_type_node.add_child(driver_instance)
	driver_instance.target = Globals.player_vehicle
	driver_instance.process_mode = Node.PROCESS_MODE_DISABLED
	driver_instance.global_position = chosen_marker.global_position
	driver_instance.process_mode = Node.PROCESS_MODE_INHERIT
	chosen_marker.reparent(self)
	chosen_marker.queue_free()
	return driver_instance
