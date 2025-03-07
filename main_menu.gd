extends Node

@export var game_packed : PackedScene

func _ready()->void:
	Globals.game_lost.connect(_on_lose)
	Globals.game_won.connect(_on_win)

func _on_lose(reason:String):
	if Globals.game_over:
		return
	$"Game Over/RichTextLabel".text = ""
	MainShaderCanvas.toggle_filter("drunk")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Globals.game_over = true
	$"Game Over".visible = true
	match reason:
		"Sober":
			$"Game Over/RichTextLabel".append_text("GAME OVER YOU'RE [color=red]SOBER")
			
		"Cops":
			$"Game Over/RichTextLabel".append_text("GAME OVER YOU'RE [color=red]HIT BY A COP")
	$"Game Over/Label".text = "YOU SURVIVED FOR: "+Globals.format_seconds_as_time(Globals.timer)
	MainShaderCanvas.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#$"Game World".process_mode = Node.PROCESS_MODE_DISABLED

func _on_win():
	if Globals.game_over:
		return
	$"YOU WIN".visible = true
	Globals.game_over = true
	$"YOU WIN/Label2".text = "YOUR TIME: "+Globals.format_seconds_as_time(Globals.timer)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MainShaderCanvas.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#$"Game World".process_mode = Node.PROCESS_MODE_DISABLED

func _on_start_pressed() -> void:
	Globals.drunkenness = 20
	#$"Game World".process_mode = Node.PROCESS_MODE_INHERIT
	on_back()
	$"Main Menu".visible = false
	$Animations.visible = true

func _on_start_game() ->void:
	var game_instance = game_packed.instantiate()
	$"Game World".add_child(game_instance)
	Globals.game_over = false
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
	$"YOU WIN".visible = false
	for child in $"Game World".get_children():
		child.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
