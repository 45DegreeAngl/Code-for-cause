extends Node
class_name BaseCosmetic
@export var car_ref : VehicleBody3D

@export_category("Color")
@export var randomize_color_meshes: Array[MeshInstance3D] = []
@export var head_lights : Array[SpotLight3D] = []
@export var back_lights : Array[SpotLight3D] = []
@export_category("Sound")
@export var engine_player : AudioStreamPlayer3D
@export var ENGINE_SOUND_MAX_SPEED : float = 75
@export var crash_player : AudioStreamPlayer3D

func randomize_mesh_colors(mesh: MeshInstance3D):
	if Globals.car_colors.size() == 0 or mesh == null or mesh.mesh == null:
		return
	
	var original_mesh := mesh.mesh
	var sel_mesh := original_mesh.duplicate()
	
	if sel_mesh.get_surface_count() == 0:
		return
	
	var material :StandardMaterial3D= sel_mesh.surface_get_material(0)
	if material == null or not material is StandardMaterial3D:
		return
	
	var chosen_color = Globals.car_colors[Globals.car_colors.keys().pick_random()]
	var sel_material := material.duplicate()
	sel_material.albedo_color = chosen_color
	sel_mesh.surface_set_material(0, sel_material)
	mesh.mesh = sel_mesh

func change_engine_pitch():
	if (not engine_player.playing) and engine_player.pitch_scale > 0.01:
		engine_player.play()
	var pitch = min(1, car_ref.linear_velocity.length()/ENGINE_SOUND_MAX_SPEED)
	if pitch <= 0.01:
		engine_player.stop()
	if pitch>0.0:
		engine_player.pitch_scale = pitch

func set_head_light_energy(intensity:float):
	for light:SpotLight3D in head_lights:
		light.light_energy = intensity

func toggle_head_lights():
	for light:SpotLight3D in head_lights:
		light.visible = !light.visible

func toggle_rear_lights():
	for light:SpotLight3D in back_lights:
		light.visible = !light.visible

func _ready()->void:
	for mesh in randomize_color_meshes:
		randomize_mesh_colors(mesh)
	if !car_ref.body_entered.is_connected(_on_collide):
		car_ref.body_entered.connect(_on_collide)
	context_ready()

func context_ready()->void:
	pass

func _process(delta: float) -> void:
	change_engine_pitch()
	context_process(delta)

func context_process(_delta:float)->void:
	pass


func _on_collide(_body):
	if abs(car_ref.linear_velocity.length() - car_ref.cur_lin_vel.length()) > 1 and !crash_player.playing:
		crash_player.stream = Globals.crash_sounds[Globals.crash_sounds.keys().pick_random()]
		crash_player.play()
