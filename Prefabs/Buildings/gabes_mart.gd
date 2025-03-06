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
		body.queue_free()
		Globals.update_bottles.emit()


func _on_buy_area_body_exited(_body: Node3D) -> void:
	pass # Replace with function body.
