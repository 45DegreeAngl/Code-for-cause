extends Node

var spawned_players:Dictionary[int,Node] = {}
@export var player_node:Node3D
@export var goob_packed:PackedScene
@onready var m_spawner: MultiplayerSpawner = $MultiplayerSpawner

func _ready() -> void:
	m_spawner.spawn_function = m_spawn
	BMult.player_registered.connect(_on_player_connect)
	BMult.player_disconnected.connect(_on_player_disconnect)

func _on_player_connect(id:int):
	if not spawned_players.has(id) and multiplayer.is_server():
		var data = {"type":"goober","id":id,"color":Color.ORANGE_RED,"pos":Vector3(0,0,10)}
		var new_goob = m_spawner.spawn(data)
		new_goob.global_position = data["pos"]
		new_goob.set_shirt_color.rpc(data["color"])
		#new_goob.reparent(player_node)

func _on_player_disconnect(id:int):
	if spawned_players.has(id):
		var node = spawned_players[id]
		if is_instance_valid(node):
			node.queue_free()
		spawned_players.erase(id)

func m_spawn(data:Dictionary):
	if data.has("type"):
		if data.get("type") == "goober":
			var new_goob = create_goober(data["id"])
			if not new_goob:
				return null
			#player_node.add_child(new_goob)
			
			new_goob.process_mode = Node.PROCESS_MODE_INHERIT
			
			return new_goob

##goober is going to have a couple of data points
#color : color of the shirt
#id : multiplayer id of the player
func create_goober(id:int):
	if spawned_players.has(id):
		return null
	var goob_inst: CharacterBody3D = goob_packed.instantiate()
	# Set metadata
	goob_inst.name = str(id)
	
	# Add to mapping
	spawned_players[id] = goob_inst
	
	# Set network authority so the specific peer controls this node if needed
	goob_inst.set_multiplayer_authority(id)
	
	goob_inst.process_mode = Node.PROCESS_MODE_DISABLED
	
	return goob_inst
