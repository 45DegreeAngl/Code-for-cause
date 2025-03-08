extends GridMap
class_name RoadSegment
signal increment_player_road_counter()

var index : int
var passed : bool = false

@export var debris_node : Node3D

func _ready():
	if debris_node:
		spawn_debris()
	spawn_driver()

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
#$Pedestrians $Cops
func spawn_driver():
	if !driver_spawns or randi_range(0,2)==0:
		print("not spawning driver")
		return
	var driver_instance : Node3D
	print(Globals.world_node)
	print(Globals.world_node.get_node("Cops"))
	print(Globals.world_node.get_node("Pedestrians"))
	if randi_range(0,3) == 0:#Cop Spawn
		driver_instance = Globals.cop_packed.instantiate()
		Globals.world_node.get_node("Cops").add_child(driver_instance)
	else:#Pedestrian Spawn
		driver_instance = Globals.pedestrian_packed.instantiate()
		Globals.world_node.get_node("Pedestrians").add_child(driver_instance)
	
	driver_instance.target = Globals.player_vehicle
	driver_instance.process_mode = Node.PROCESS_MODE_DISABLED
	driver_instance.global_position = driver_spawns.get_children().pick_random().global_position
	driver_instance.process_mode = Node.PROCESS_MODE_INHERIT
