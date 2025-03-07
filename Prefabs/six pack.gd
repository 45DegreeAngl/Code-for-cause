extends RigidBody3D

@onready var drinks:Dictionary = {"Jaeger":$Milk_Crate/Bottles/Jaeger,"Sake":$Milk_Crate/Bottles/Sake,"Beer":$Milk_Crate/Bottles/Beer}
#@onready var content:Dictionary = {"Beer":3,"Sake":2,"Jaeger":1}
@onready var alchohol_count:int = 6
var randomize_array:Array[String] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_bottles()

const bottle_step_count : float = 1
var x = 0
var z = 0

func update_bottles():
	var chosen_beverage : String = drinks.keys().pick_random()
	set_meta("Bottle_Type",chosen_beverage)
	for i in alchohol_count:
		#print(i)
		randomize_array.append(chosen_beverage)
	##add keys to this temp array to remove them one by one
	#print(randomize_array)
	var bottle_type = ""
	for instance in $Milk_Crate/instances.get_children():
		instance.queue_free()
	for balls in randomize_array.size():
		bottle_type = randomize_array.pick_random()
		#print(str(randomize_array),bottle_type)
		randomize_array.erase(bottle_type)
		#print(bottle_type)
		#var cur_multimesh_instance : MultiMeshInstance3D = multimeshes[bottle_type]
		#print(multimeshes[bottle_type].name)
		
		var beg_marker_pos : Vector3 = $Milk_Crate/Beginning.position
		var end_marker_pos : Vector3 = $Milk_Crate/End.position
		var bottle_y_pos : float = drinks[bottle_type].position.y
		
		
		var new_mesh : MeshInstance3D = MeshInstance3D.new()
		$Milk_Crate/instances.add_child(new_mesh)
		new_mesh.mesh = drinks[bottle_type].mesh
		
		if beg_marker_pos.x+x*bottle_step_count>end_marker_pos.x:
			z+=1
			x=0
		if beg_marker_pos.z+z*bottle_step_count>end_marker_pos.z:
			z=0
		new_mesh.position = Vector3(beg_marker_pos.x+x*bottle_step_count,bottle_y_pos,beg_marker_pos.z+z*bottle_step_count)
		x+=1
