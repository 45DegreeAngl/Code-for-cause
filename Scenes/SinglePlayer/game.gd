extends Node

func _process(_delta: float) -> void:
	if Globals.game_over or $"Game Over".visible or $"YOU WIN".visible:
		return
	if Input.is_action_just_pressed("KEYWORD_PAUSE"):
		if $Options.visible:
			Globals.game_paused = false
			$Options.visible = false
			MainShaderCanvas.filter_dict["BeerMeter"][0].visible = true
			MainShaderCanvas.filter_dict["drunk"][0].visible = true
			#$"Game World".process_mode = Node.PROCESS_MODE_INHERIT
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Globals.game_paused = true
			$Options.open_options(true)
			MainShaderCanvas.filter_dict["BeerMeter"][0].visible = false
			MainShaderCanvas.filter_dict["drunk"][0].visible = false
			#$"Game World".process_mode = Node.PROCESS_MODE_DISABLED
			
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
