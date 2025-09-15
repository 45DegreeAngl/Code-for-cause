@tool
extends MeshInstance3D

@export var subviewport : SubViewport

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !subviewport:
		return
	var mat = StandardMaterial3D.new()
	mat.uv1_triplanar = true
	mat.albedo_texture = subviewport.get_texture()
	mat.emission_enabled = true
	mat.emission_texture = subviewport.get_texture()
	set_surface_override_material(0, mat)
