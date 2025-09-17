extends BaseCar
class_name BaseDriver

@export var target:BaseCar = null
@export var hunt_dist:float = 15
@export var backwards : bool = false
@export var reverse_timer:Timer
@export_group("AI Tuning")
@export var max_speed = 80.0
@export var min_speed_on_curve = 25.0
@export var steer_responsiveness = 1.0
var hunt:bool = false
var parked : bool = false
var reversing:bool = false
var dist_to_target:float = INF

func driver_process(_delta):
	if target:
		dist_to_target = xz_plane_dist(self.global_position,target.global_position)

func on_stuck_timer_ended():
	reversing = true
	reverse_timer.start()

func on_reverse_timer_ended():
	reversing = false
