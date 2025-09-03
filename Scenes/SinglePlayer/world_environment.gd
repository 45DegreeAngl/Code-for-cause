extends WorldEnvironment
@onready var sky_material:ShaderMaterial = environment.sky.sky_material
@export var planet_z_distance_offset:float = 100.0

func _process(_delta: float) -> void:
	update_moon_position()

func update_moon_position():
	var player_z : float = 0.0
	if Globals.player_character:
		player_z = Globals.player_character.global_position.z
	else:
		player_z = Globals.player_vehicle.global_position.z
	sky_material.set_shader_parameter("planet_z",player_z-planet_z_distance_offset)
