#Alchohol crate, this will be picked up

extends Node3D

@onready var drinks:Dictionary = {"Jaeger":$Bottles/Jaeger,"Sake":$Bottles/Sake,"Beer":$Bottles/Beer}

#@onready var content:Dictionary = {"Beer":3,"Sake":2,"Jaeger":1}
@onready var alchohol_count:int = 0
var randomize_array:Array[String] = []

@export var is_multiplayer: bool = false
var network_id = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	network_id = Globals.generate_network_id()
	Globals.register_node(self, network_id)
	Globals.update_bottles.connect(update_bottles)

const bottle_step_count : float = 2
var x = 0
var z = 0

func update_bottles_directly(dict:Dictionary):
	alchohol_count=0
	##add keys to this temp array to remove them one by one
	for i:String in dict.keys():
		#print(i)
		randomize_array.append(i)
	#print(randomize_array)
	var bottle_type = ""
	for instance in $instances.get_children():
		instance.queue_free()
	for balls in randomize_array.size():
		bottle_type = randomize_array.pick_random()
		#print(str(randomize_array),bottle_type)
		randomize_array.erase(bottle_type)
		
		var beg_marker_pos : Vector3 = $Beginning.position
		var end_marker_pos : Vector3 = $End.position
		var bottle_y_pos : float = drinks[bottle_type].position.y
		
		for b in dict[bottle_type]:
			alchohol_count+=1
			var new_mesh : MeshInstance3D = MeshInstance3D.new()
			$instances.add_child(new_mesh)
			new_mesh.mesh = drinks[bottle_type].mesh
			
			if beg_marker_pos.x+x*bottle_step_count>end_marker_pos.x:
				z+=1
				x=0
			if beg_marker_pos.z+z*bottle_step_count>end_marker_pos.z:
				z=0
			new_mesh.position = Vector3(beg_marker_pos.x+x*bottle_step_count,bottle_y_pos,beg_marker_pos.z+z*bottle_step_count)
			x+=1
	$Label3D.text = str(alchohol_count)

func update_bottles():
	if is_multiplayer and not Network.is_host:
		return # Clients will be updated by the host.

	# Host updates from global state and tells clients
	update_bottles_directly(Globals.car_contents)
	if is_multiplayer:
		Network.p2p_call_func(network_id, "update_bottles_directly", [Globals.car_contents])

func update_bottles_from_host(dict: Dictionary):
	# This function is called on clients via P2P
	if Network.is_host: return
	update_bottles_directly(dict)
