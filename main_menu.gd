extends Node

@export var game_packed : PackedScene

func _ready()->void:
	Globals.game_lost.connect(_on_lose)

func _on_lose():
	MainShaderCanvas.toggle_filter("drunk")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$"Game Over".visible = true
	MainShaderCanvas.visible = false
	$"Game World".process_mode = Node.PROCESS_MODE_DISABLED

func _on_start_pressed() -> void:
	Globals.drunkenness = 20
	$"Game World".process_mode = Node.PROCESS_MODE_INHERIT
	on_back()
	$"Main Menu".visible = false
	$Animations.visible = true

func _on_start_game() ->void:
	var game_instance = game_packed.instantiate()
	$"Game World".add_child(game_instance)
	Globals.world_node = game_instance
	$Animations.visible = false
	MainShaderCanvas.visible = true

func _on_options_pressed() -> void:
	$Options.visible = true
	$"Main Menu".visible = false


func _on_credits_pressed() -> void:
	$Credits.visible = true
	$"Main Menu".visible = false

func on_back()->void:
	$Credits.visible = false
	$Options.visible = false
	$"Main Menu".visible = true
	$"Game Over".visible = false
	for child in $"Game World".get_children():
		child.queue_free()
	
