extends GridMap
class_name RoadSegment
signal increment_player_road_counter()

var index : int
var passed : bool = false

@export var debris_node : Node3D

func _ready():
	if debris_node:
		spawn_debris()

func spawn_debris():
	for child in debris_node.get_children():
		child.spawn_debris()

func _on_exit_area_body_entered(body: Node3D) -> void:
	if passed:
		return
	
	if body == Globals.player_vehicle:
		passed = true
		increment_player_road_counter.emit()
		
