extends Node3D

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		var new_deg : Vector3 = $Camera3D.rotation_degrees
		match event.keycode:
			KEY_LEFT:
				new_deg.y += 90
			KEY_RIGHT:
				new_deg.y -= 90
			KEY_UP:
				new_deg.x += 90
			KEY_DOWN:
				new_deg.x -= 90
		new_deg.x = wrapf(new_deg.x,0.0,360.0)
		new_deg.y = wrapf(new_deg.y,0.0,360.0)
		$Camera3D.rotation_degrees = new_deg
		print("New rotation x:%s and y:%s"%[new_deg.x,new_deg.y])
