extends Node3D

@onready var car_node : VehicleBody3D
var can_exit : bool = false

var exit_counter : int = 0
func _on_voice_line_area_exited(area: Area3D) -> void:
	print(area.get_parent())
	print(area)
	if area.get_parent().get_parent().get_parent().get_parent().get_parent().has_method("set_car_door"):
		if exit_counter>0 or !can_exit:
			return
		$"Interactibles/Thank you".play()
		exit_counter +=1

func _on_voice_line_area_entered(area: Area3D) -> void:
	if area.get_parent().get_parent().get_parent().get_parent().get_parent().has_method("set_car_door"):
		if !can_exit:
			await get_tree().create_timer(0.3).timeout
			can_exit = true
