extends Node3D

@onready var car_node : VehicleBody3D

func _on_buy_area_body_entered(body: Node3D) -> void:
	if body.has_meta("Bottle"):
		print("PURCHASED: "+ str(body.get_meta("Bottle")))
		if body.get_meta("Bottle") == ("Sake"):
			Globals.car_contents["Sake"] +=1
		elif body.get_meta("Bottle") == ("Beer"):
			Globals.car_contents["Beer"] +=1
		elif body.get_meta("Bottle")==("Jaeger"):
			Globals.car_contents["Jaeger"] +=1
		elif body.get_meta("Bottle")==("Crate"):
			GlobalSteam.setAchievement("BULK BUYER")
			Globals.car_contents[body.get_meta("Bottle_Type")] += 6
			Globals.total_alcohol_bought+=5
		body.queue_free()
		Globals.total_alcohol_bought+=1
		Globals.update_bottles.emit()

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
