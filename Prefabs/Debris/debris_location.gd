extends Node3D
class_name DebrisLocation

@export var accepts_large : bool = true
@export var accepts_small : bool = true
@export var small_debris : Array[DebrisGroup]
@export var large_debris : Array[DebrisGroup]

@export_subgroup("Settings")
@export_range(0,1,0.01) var small_spawn_chance : float = 0.70

@export var use_same_debris_type : bool = true
@export var small_spawn_count : Vector2i = Vector2i.ONE
@export var large_spawn_count : Vector2i = Vector2i.ONE

func spawn_debris():
	if randf() <= small_spawn_chance:
		pass
	else:
		pass
