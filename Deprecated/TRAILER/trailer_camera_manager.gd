extends Node
@onready var wheel_cam: Camera3D = $WheelCam
@onready var orbit_cam: Camera3D = $OrbitPivot/OrbitCam
@onready var orbit_pivot: Node3D = $OrbitPivot
@onready var free_cam: FreeLookCamera = $FreeCam
@onready var trailer_player: AnimationPlayer = $TrailerPlayer

@onready var windshield: Camera3D = $"../Cameras/Windshield"

@onready var camList : Array[Camera3D] = []

var camLocked : bool = false
var camIndex = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camList = [windshield, wheel_cam, orbit_cam, free_cam]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed() and event.keycode == KEY_C:
			switch_cam()
		if event.is_pressed() and event.keycode == KEY_V:
			change_cam_mode()
	
	if event is InputEventMouseMotion:
		orbit_pivot.rotate_y(-event.relative.x * Globals.car_mous_sens)
	
func switch_cam():
	if get_cam_name() == "FreeCam":
		free_cam.cam_follow = false
		camLocked = not camLocked
		
	
	camIndex+=1
	
	if camLocked:
		camIndex-=1
	
	if camIndex >= len(camList):
		camIndex = 0
	
	camList[camIndex].current = true
	
	if get_cam_name() == "FreeCam" and not camLocked:
		camList[camIndex].global_position = orbit_pivot.global_position
		camList[camIndex].global_rotation.y = orbit_pivot.global_rotation.y
		Globals.game_paused = true
	else:
		Globals.game_paused = false
	
	
func get_cam_name():
	return camList[camIndex].name

func change_cam_mode():
	if camList[camIndex].name == "OrbitCam":
		trailer_player.play("orbit_anim")
	if camList[camIndex].name == "FreeCam":
		free_cam.set_cam_target(windshield)
		free_cam.cam_follow = true
