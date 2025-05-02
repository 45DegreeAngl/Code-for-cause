extends Node

var console_active:bool = false
var beer_meter_visible : bool = true
var debug_mode : bool = false

var debug_camera_spawned : bool = false
@onready var fp_cam : Camera3D
@onready var wheel_cam : Camera3D
@onready var lock_target : Node3D
@onready var car_target : Node3D
@onready var player_model : Node3D
@onready var debug_camera_packed = preload("res://DEBUG/Debug Camera.tscn")

@onready var temp_road_packed = preload("res://Prefabs/Roads/Road Segments/TEMP ROAD.tscn")

func _process(_delta)->void:
	if Input.is_action_just_pressed("Tilde"):
		if !Globals.is_cheater:
			Globals.is_cheater = true
		console_active = !console_active

func _input(event: InputEvent) -> void:
	if !console_active:
		return
	if event is InputEventKey and event.is_pressed():
		match event.physical_keycode:
			KEY_H:
				beer_meter_visible = !beer_meter_visible
				MainShaderCanvas.set_beer_visibility(beer_meter_visible)
			KEY_EQUAL:
				Globals.drunkenness += 10
			KEY_MINUS:
				Globals.drunkenness -= 10
			KEY_G:
				if Globals.player_vehicle:
					debug_mode = !debug_mode
					Globals.player_vehicle.DEBUG_MODE = debug_mode
			KEY_C:
				if debug_camera_spawned:
					return
				debug_camera_spawned = true
				print("WAL:OUJSDIOHJW")
				var debug_cam : Window = debug_camera_packed.instantiate()
				add_child(debug_cam)
				debug_cam.first_person_cam = fp_cam
				debug_cam.world_wheel_cam = wheel_cam
				debug_cam.lock_target = lock_target
				debug_cam.car_target = car_target
				debug_cam.close_requested.connect(on_cam_close)
				debug_cam.player_model = player_model
				debug_cam.visible = true
			KEY_INSERT:#spawn road
				Globals.world_node.cur_player_road +=1
			KEY_HOME:
				Globals.world_node.append_segment(temp_road_packed)

func on_cam_close():
	debug_camera_spawned = false
