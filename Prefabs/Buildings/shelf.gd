extends Node3D

@export var min_buyables : int = 3
@export var max_buyables : int = 9
@export var buyable : Array[PackedScene] = []
@export var beer_crate : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in randi_range(min_buyables,max_buyables):
		if randi_range(0,9) != 0:
			spawn_bottle(buyable.pick_random().instantiate())
		else:
			spawn_bottle(beer_crate.instantiate())
	spawn_bottle(beer_crate.instantiate())

func spawn_bottle(bottle_instance:Node3D):
	add_child(bottle_instance)
	bottle_instance.scale = Vector3(0.3,0.6,0.3)
	bottle_instance.global_position = $Spawns.get_children().pick_random().global_position
