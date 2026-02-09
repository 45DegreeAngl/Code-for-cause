extends StaticBody3D

signal im_dead(balls)

func destroy_self():
	print("WOAID")
	$GPUParticles3D.emitting = true

func _on_gpu_particles_3d_finished() -> void:
	im_dead.emit(get_index())
	call_deferred("queue_free")
