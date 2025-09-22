#shelf
extends Node3D

@export var min_buyables : int = 3
@export var max_buyables : int = 9
@export var buyable : Array[PackedScene] = []
@export var crate_chance_onein:int = 10:
	set(value):
		crate_chance_onein = max(1,value)
@export var beer_crate : PackedScene
@export var is_multiplayer: bool = false

var network_id = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	network_id = Globals.generate_network_id()
	Globals.register_node(self, network_id)
	
	if is_multiplayer and not Network.is_host:
		return # Only the host should spawn items in multiplayer

	crate_chance_onein = crate_chance_onein
	var items_to_spawn = []
	for i in randi_range(min_buyables,max_buyables):
		var scene_path
		if randi_range(0,crate_chance_onein-1) != 0:
			scene_path = buyable.pick_random().resource_path
		else:
			scene_path = beer_crate.resource_path
		
		var spawn_transform = $Spawns.get_children().pick_random().global_transform
		items_to_spawn.append({"path": scene_path, "transform": spawn_transform})

	# Host spawns items for itself and tells clients to do the same
	for item_data in items_to_spawn:
		spawn_bottle_rpc(item_data.path, item_data.transform)
		if is_multiplayer:
			Network.p2p_call_func(network_id, "spawn_bottle_rpc", [item_data.path, item_data.transform])

func spawn_bottle(bottle_instance:Node3D):
	add_child(bottle_instance)
	#bottle_instance.scale = Vector3(0.3,0.6,0.3)
	bottle_instance.global_position = $Spawns.get_children().pick_random().global_position

func spawn_bottle_rpc(scene_path: String, spawn_transform: Transform3D):
	var packed_scene = load(scene_path)
	if packed_scene:
		var bottle_instance = packed_scene.instantiate()
		add_child(bottle_instance)
		bottle_instance.global_transform = spawn_transform
