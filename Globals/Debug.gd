extends Node

var console_active:bool = false
var beer_meter_visible : bool = true
var debug_mode : bool = false

func _process(_delta)->void:
	if Input.is_action_just_pressed("Tilde"):
		if !Globals.is_cheater:
			Globals.is_cheater = true
		console_active = !console_active

func _input(event: InputEvent) -> void:
	if !console_active:
		return
	if event is InputEventKey and event.is_pressed():
		match event.physical_keycode:
			KEY_H:
				beer_meter_visible = !beer_meter_visible
				MainShaderCanvas.set_beer_visibility(beer_meter_visible)
			KEY_EQUAL:
				Globals.drunkenness += 10
			KEY_MINUS:
				Globals.drunkenness -= 10
			KEY_G:
				if Globals.player_vehicle:
					debug_mode = !debug_mode
					Globals.player_vehicle.DEBUG_MODE = debug_mode
