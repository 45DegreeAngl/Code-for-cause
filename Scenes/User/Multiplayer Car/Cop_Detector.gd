extends Node3D

class_name DistanceGadget

@export_subgroup("COPS NODE")
var closest : VehicleBody3D = null
@onready var label_3d: Label3D = $Cop_Detector/Label3D
@export var candidates_node: Node3D

func update():
	if !candidates_node:
		return
	if candidates_node.get_child_count()<1:
		label_3d.text = tr("NONE_DETECTED_TEXT")
		closest = null
		return
	var cur_distance = INF
	for candidate in candidates_node.get_children():
		if !closest:
			closest = candidate
			cur_distance = self.global_position.distance_to(candidate.global_position)
		if cur_distance>self.global_position.distance_to(candidate.global_position):
			closest = candidate
			cur_distance = self.global_position.distance_to(candidate.global_position)
	label_3d.text = str(roundi(cur_distance)) + "m"
	if cur_distance<=100:
		$Cop_Detector/Green/OmniLight3D.light_energy = 0
		$Cop_Detector/Red/OmniLight3D.light_energy = 0.2
	else:
		$Cop_Detector/Green/OmniLight3D.light_energy = 0.1
		$Cop_Detector/Red/OmniLight3D.light_energy = 0
