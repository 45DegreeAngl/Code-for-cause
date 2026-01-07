extends Control

var mult_mapping:Dictionary[int,Control] = {}

@export var play_packed:PackedScene
@export var player_holder:VBoxContainer

@export var host_but:Button
@export var join_but:Button
@export var id_prompt:LineEdit

func _ready():
	Network.player_joined.connect(create_player_line)
	Network.player_left.connect(remove_player_line)
	Network.lobby_created_signal.connect(lobby_created)
	host_but.pressed.connect(Network.host_lobby)
	join_but.pressed.connect(join_lobby)

func lobby_created():
	print("Created a new lobby, heres the ID: ",Network.lobby_id)

func join_lobby():
	Network.join_lobby(int(id_prompt.text))

func create_player_line(id:int = 1):
	var play_inst:LineEdit = play_packed.instantiate()
	play_inst.name = str(id)
	mult_mapping.set(id,play_inst)
	player_holder.add_child(play_inst)
	play_inst.set_multiplayer_authority(id)
	play_inst.placeholder_text = str(id)

func remove_player_line(id:int = 1):
	if mult_mapping.get(id):
		mult_mapping.get(id).queue_free()
		mult_mapping.erase(id)


func _on_id_prompt_text_changed(new_text: String) -> void:
	join_but.disabled = new_text.is_empty()
