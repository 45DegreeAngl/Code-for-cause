extends Node3D

@export var num_of_buyables : int = 1
@export var buyable : Array[PackedScene] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in num_of_buyables:
		var bottle_instance : Node3D = buyable.pick_random().instantiate()
		add_child(bottle_instance)
		bottle_instance.global_position = $Spawns.get_children().pick_random().global_position
