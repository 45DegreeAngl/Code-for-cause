extends Node3D

@export var min_buyables : int = 3
@export var max_buyables : int = 9
@export var buyable : Array[PackedScene] = []
@export var beer_crate : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in randi_range(min_buyables,max_buyables):
		var bottle_instance : Node3D 
		if randi_range(0,9) != 0:
			bottle_instance = buyable.pick_random().instantiate()
		else:
			bottle_instance = beer_crate.instantiate()
		
		add_child(bottle_instance)
		bottle_instance.global_position = $Spawns.get_children().pick_random().global_position
