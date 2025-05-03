extends RigidBody3D
class_name Debris

func rescale_children(scalar : float):
	for child in get_children():
		if child is MeshInstance3D or child is CollisionShape3D:
			child.scale = child.scale*scalar
			if child.is_in_group("Please Move"):
				child.position *= scalar
