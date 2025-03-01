extends Control


func _on_visible_debug_camera_toggled(toggled_on: bool) -> void:
	$ViewportContainer.visible = toggled_on
