extends Node3D
class_name DebrisLocation

@export var accepts_large : bool = true
@export var accepts_small : bool = true
@export var small_debris : Array[PackedScene]
@export var large_debris : Array[PackedScene]

@export_subgroup("Settings")
@export_range(0,1,0.01) var spawn_chance : float = 1
@export_range(0,1,0.01) var small_spawn_chance : float = 0.70

@export var use_same_debris_type : bool = true
@export var small_spawn_count : Vector2i = Vector2i.ONE
@export var large_spawn_count : Vector2i = Vector2i.ONE

@export_subgroup("Spawn Markers")
@export var small_locations : Array[Marker3D]
@export var large_locations : Array[Marker3D]

func _ready():
	if accepts_small && !accepts_large:
		small_spawn_chance = 1
	elif accepts_large && !accepts_small:
		small_spawn_chance = 0


func spawn_debris():
	if randf() <= 1-spawn_chance:
		return
	if randf() <= small_spawn_chance:
		var count = randi_range(small_spawn_count.x, small_spawn_count.y)
		var temp_list = small_locations.duplicate()
		if use_same_debris_type:
			var type = small_debris.pick_random()
			for i in range(count):
				var loc = temp_list.pick_random()
				loc.add_child(type.instantiate())
				temp_list.erase(loc)
		else:
			for i in range(count):
				var loc = temp_list.pick_random()
				loc.add_child(small_debris.pick_random().instantiate())
				temp_list.erase(loc)
	else:
		var count = randi_range(large_spawn_count.x, large_spawn_count.y)
		var temp_list = large_locations.duplicate()
		if use_same_debris_type:
			var type = large_debris.pick_random()
			for i in range(count):
				var loc = temp_list.pick_random()
				loc.add_child(type.instantiate())
				temp_list.erase(loc)
		else:
			for i in range(count):
				var loc = temp_list.pick_random()
				loc.add_child(large_debris.pick_random().instantiate())
				temp_list.erase(loc)
