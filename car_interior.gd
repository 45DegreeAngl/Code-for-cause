extends Node

@export var cam_speed : float = 400

@onready var min_bound : Vector2 = $CollisionShape2D.position - $CollisionShape2D.shape.size/2
@onready var max_bound : Vector2 = $CollisionShape2D.position + $CollisionShape2D.shape.size/2
@export var windshield_cam : Camera3D = null
@export var left_window_cam : Camera3D = null
@export var right_window_cam : Camera3D = null
@export var left_mirror_cam : Camera3D = null
@export var right_mirror_cam : Camera3D = null


func _ready()->void:
	if windshield_cam:
		$Control/Windshield/RealViewport.cam3d_target = windshield_cam
	if left_window_cam:
		$"Control/Left Window/RealViewport".cam3d_target = left_window_cam
	if right_window_cam:
		$"Control/Right Window/RealViewport".cam3d_target = right_window_cam
	if left_mirror_cam:
		$"Control/Left Mirror/RealViewport".cam3d_target = left_mirror_cam
	if right_mirror_cam:
		$"Control/Right Mirror/RealViewport".cam3d_target = right_mirror_cam
	pass

func _process(delta: float) -> void:
	
	var direction : float = 0
	var mouse_position = get_viewport().get_mouse_position()
	
	if mouse_position.x < get_viewport().size.x/3:
		direction = -1
	elif mouse_position.x > 2*get_viewport().size.x/3:
		direction = 1
	else:
		direction = 0 
	
	if direction:
		$CanvasLayer/SubViewportContainer/Camera.velocity.x = direction*cam_speed
	else:
		$CanvasLayer/SubViewportContainer/Camera.velocity.x = move_toward($CanvasLayer/SubViewportContainer/Camera.velocity.x,0,cam_speed)
	
	var new_cam_position = $CanvasLayer/SubViewportContainer/Camera.global_position + $CanvasLayer/SubViewportContainer/Camera.velocity * delta
	
	if new_cam_position.x>max_bound.x:
		new_cam_position.x = max_bound.x
	elif new_cam_position.x<min_bound.x:
		new_cam_position.x = min_bound.x
	
	if new_cam_position.y>max_bound.y:
		new_cam_position.y = max_bound.y
	elif new_cam_position.y<min_bound.y:
		new_cam_position.y = min_bound.y
	
	$CanvasLayer/SubViewportContainer/Camera.move_and_slide()
	$CanvasLayer/SubViewportContainer/Camera.global_position = new_cam_position
