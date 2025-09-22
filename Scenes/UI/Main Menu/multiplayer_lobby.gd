extends Control

signal back_pressed()

func _on_back_pressed():
	visible = false
	back_pressed.emit()

func _ready():
	Globals.register_static_node("scene_manager",self)

func _exit_tree():
	# It's good practice to unregister when the node is removed.
	Globals.unregister_static_node("scene_manager")

func _on_start_pressed() -> void:
	Network.p2p_call_func("scene_manager", "start")

func start()->void:
	get_tree().change_scene_to_file("res://Scenes/Multiplayer/MGame.tscn")
