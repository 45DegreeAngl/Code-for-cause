extends Node3D

func _on_win_zone_body_entered(body: Node3D) -> void:
	
	if body == Globals.player_vehicle:
		print("VEHICLE")
		Globals.game_won.emit()
	elif body is PhysicalBone3D:
		print("BONES")
		if body.get_parent().get_parent().get_parent().get_parent() == Globals.player_character:
			Globals.game_won.emit()
