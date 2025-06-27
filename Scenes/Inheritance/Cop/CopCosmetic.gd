extends BaseCosmetic
class_name CopCosmetic

@export_subgroup("Nodes")
@export var siren : AudioStreamPlayer3D
@export var talk : AudioStreamPlayer3D
@export var chassis : MeshInstance3D
@export_subgroup("Vars")
@export_range(0,100,1) var talk_chance : int = 20
@export var talk_timer : Timer = null

func context_ready()->void:
	if !car_ref is BaseDriver:
		printerr("Referenced car is not a base driver, and doesnt have distance to target variables")
	if !talk_timer.timeout.is_connected(announce):
		talk_timer.timeout.connect(announce)

func context_process(_delta)->void:
	if car_ref.dist_to_target < car_ref.hunt_dist:
	#print(distance_to(self.global_position,target.global_position))
		if talk_timer.is_stopped():
			talk_timer.start()
			set_head_light_energy(7.0)
			siren.playing = true
		Globals.detected = true

var red_light = false

func toggle_colors():
	if !chassis:
		printerr("No chassis selected for lights to toggle.")
		return
	var red_mat : StandardMaterial3D = chassis.get_active_material(4)
	var blue_mat : StandardMaterial3D = chassis.get_active_material(6)
	
	if red_light:
		blue_mat.emission_enabled = false
		#$Light/BLUE.visible = false
		red_mat.emission_enabled = true
		red_mat.emission = Color.RED
		#$Light/RED.visible = true
		chassis.set_surface_override_material(4, red_mat)
	else:
		#$Light/BLUE.visible = false
		#$Light/RED.light_energy = false
		red_mat.emission_enabled = false
		#$Light/RED.visible = true
		blue_mat.emission_enabled = true
		blue_mat.emission = Color.BLUE
		chassis.set_surface_override_material(6, red_mat)
	red_light = !red_light

func announce():
	if car_ref.dist_to_target > car_ref.hunt_dist:
		if !talk_timer.is_stopped():
			set_head_light_energy(5.0)
			talk_timer.stop()
			siren.playing = false
	if randi_range(0,100)>=talk_chance:
		return
	if int(Globals.timer)%2==0:
		talk.stream = Globals.world_voice_lines["Pull Over"]
		talk.play()
	else:
		talk.stream = Globals.world_voice_lines["Best Driver"]
		talk.play()
