extends MeshInstance3D
@export var key:Node3D

func set_key(node:Node3D):
	if node and is_instance_valid(node):
		if !key:
			if key.tree_exited.is_connected(free_key):
				key.tree_exited.disconnect(free_key)
		key = node
		key.tree_exited.connect(free_key)

func _ready() -> void:
	set_key(key)

func free_key():
	call_deferred("queue_free")
