extends Camera3D


@onready var rest_pos = global_position
@export var mouse_scale_factor = 2
@export var interp_rate = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	mouse_pos = mouse_pos.clamp(Vector2.ZERO, get_viewport().size)
	var center : Vector2 = get_viewport().size/2
	var mouse_percent = (center - mouse_pos) / center
	global_position = global_position.slerp(-basis.z * Vector3(mouse_percent.x, mouse_percent.y  * (center.y/center.x),0) * mouse_scale_factor + rest_pos, interp_rate * delta)

func _input(event: InputEvent) -> void:
	pass
