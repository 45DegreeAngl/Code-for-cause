extends Window

@export var first_person_cam: Camera3D = null
@export var world_wheel_cam: Camera3D = null
@export var lock_target: Node3D = null  # Assignable target in Inspector
@export var car_target: Node3D = null  # Assign car in Inspector
@export var player_model : MeshInstance3D = null
@export var default_distance: float = 12.0  # Default zoom distance
@export var zoom_speed: float = 1.0  # Speed of zooming
@export var min_distance: float = 2.0  # Minimum zoom distance
@export var max_distance: float = 40.0  # Maximum zoom distance
@export var rotation_speed: float = 0.01  # Speed of mouse rotation

var yaw = 0.0
var pitch = 0.0
var distance = default_distance

@onready var free: Camera3D = $SubViewportContainer/SubViewport/CAMERAS/Free
@onready var car: Camera3D = $SubViewportContainer/SubViewport/CAMERAS/Car
@onready var first_person: Camera3D = $"SubViewportContainer/SubViewport/CAMERAS/First Person"
@onready var wheel: Camera3D = $SubViewportContainer/SubViewport/CAMERAS/Wheel

@export var fp_sensitivity: float = 0.2
@export var fp_speed: float = 50
@export var fp_speed_increment: float = 5
@export var fp_sensitivity_increment: float = 0.02

var mouse_input = Vector2.ZERO
var mouse_captured = false
var window_focus = false
var is_locked_on = false  # Lock-on toggle state

func _input(event):
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_1:
				switch_camera(free)
			KEY_2:
				switch_camera(car)
			KEY_3:
				switch_camera(first_person)
			KEY_4:
				switch_camera(wheel)
	
	if !window_focus:
		return  # Skip processing if the window isn't focused

	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed():
		toggle_mouse_capture()
	
	if event is InputEventKey and event.keycode == KEY_L and event.is_pressed():
		toggle_lock_on()  # Toggles lock-on mode

	if event is InputEventKey and event.keycode == KEY_SPACE and event.is_pressed():
		if first_person:
			free.global_transform = first_person.global_transform

	# Adjust sensitivity and speed (only in free mode)
	if free.current and !is_locked_on:
		if event is InputEventKey and event.is_pressed():
			if event.keycode == KEY_PLUS:
				fp_sensitivity += fp_sensitivity_increment
			elif event.keycode == KEY_MINUS:
				fp_sensitivity = max(0.01, fp_sensitivity - fp_sensitivity_increment)

		if event is InputEventMouseButton and event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				fp_speed += fp_speed_increment
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				fp_speed = max(5, fp_speed - fp_speed_increment)
	
	if car.current:
		if event is InputEventKey and event.is_pressed():
			
			if event.keycode == KEY_EQUAL:
				var target_distance = distance
				target_distance = max(min_distance, distance - zoom_speed)
				distance = lerpf(distance,target_distance,0.1)
			elif event.keycode == KEY_MINUS:
				var target_distance = distance
				target_distance = min(max_distance, distance + zoom_speed)
				distance = lerpf(distance,target_distance,0.1)

		# Rotate camera based on mouse movement
		if event is InputEventMouseMotion and !mouse_captured:
			yaw -= event.relative.x * rotation_speed
			pitch = clamp(pitch - event.relative.y * rotation_speed, -PI/4, PI/4)  # Limit up/down rotation

	# Mouse look (only in free mode)
	if free.current and event is InputEventMouseMotion and !mouse_captured and !is_locked_on:
		mouse_input = event.relative * fp_sensitivity *20

func switch_camera(new_camera: Camera3D):
	if new_camera:
		free.current = new_camera == free
		car.current = new_camera == car
		first_person.current = new_camera == first_person
		wheel.current = new_camera == wheel


func sync_free_camera_to_first_person():
	if first_person_cam:
		free.global_transform = first_person_cam.global_transform
		#free.global_transform = first_person_cam.global_transform  # Sync position & rotation


func _physics_process(delta: float) -> void:
	if first_person_cam:
		first_person.global_transform = first_person_cam.global_transform
	
	if world_wheel_cam:
		wheel.global_transform = world_wheel_cam.global_transform

	if car_target:
		update_car_camera(delta)

	if free and free.current and window_focus:
		if is_locked_on and lock_target:
			free.look_at(lock_target.global_transform.origin, Vector3.UP)  # Lock camera onto target
		else:
			handle_free_camera_movement(delta)  # Normal movement

func update_car_camera(_delta):
	# Calculate new camera position based on yaw, pitch, and distance
	var offset = Vector3(
		distance * cos(yaw) * cos(pitch),
		distance * sin(pitch),
		distance * sin(yaw) * cos(pitch)
	)

	var target_position = car_target.global_transform.origin + offset
	car.global_transform.origin = lerp(car.global_transform.origin,target_position, 0.1)  # Smooth movement

	# Make the camera look at the car
	car.look_at(car_target.global_transform.origin, Vector3.UP)


func handle_free_camera_movement(delta):
	# Smoothly rotate the camera
	var target_rotation_x = clamp(free.rotation.x - deg_to_rad(mouse_input.y), -PI/2, PI/2)
	free.rotation.x = lerp_angle(free.rotation.x, target_rotation_x, 0.1)  # Smooth pitch rotation
	free.rotation.y = lerp_angle(free.rotation.y, free.rotation.y - deg_to_rad(mouse_input.x), 0.1)  # Smooth yaw rotation
	mouse_input = Vector2.ZERO

	var direction = Vector3.ZERO

	if Input.is_action_pressed("Numpad 8"):  # W key
		direction -= free.transform.basis.z
	if Input.is_action_pressed("Numpad 5"):  # S key
		direction += free.transform.basis.z
	if Input.is_action_pressed("Numpad 4"):  # A key
		direction -= free.transform.basis.x
	if Input.is_action_pressed("Numpad 6"):  # D key
		direction += free.transform.basis.x
	if Input.is_action_pressed("Numpad 9"):  # Q key
		direction += free.transform.basis.y
	if Input.is_action_pressed("Numpad 7"):  # E key
		direction -= free.transform.basis.y
	if Input.is_action_just_pressed("Numpad 0"):
		player_model.visible = !player_model.visible

	direction = direction.normalized()
	
	# Smooth movement using lerp
	var target_position = free.position + direction * fp_speed * delta
	free.position = free.position.lerp(target_position, 0.1)  # Gradual movement

func toggle_mouse_capture():
	mouse_captured = !mouse_captured
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE)

func toggle_lock_on():
	is_locked_on = !is_locked_on  # Toggle lock-on state

func _on_close_requested() -> void:
	call_deferred("queue_free")

func _on_focus_entered() -> void:
	window_focus = true

func _on_focus_exited() -> void:
	window_focus = false

@onready var input_dict :Dictionary = {
	"Numpad 0": KEY_KP_0,"Numpad 1": KEY_KP_1,
	"Numpad 2": KEY_KP_2,"Numpad 3": KEY_KP_3,
	"Numpad 4": KEY_KP_4,"Numpad 5": KEY_KP_5,
	"Numpad 6": KEY_KP_6,"Numpad 7": KEY_KP_7,
	"Numpad 8": KEY_KP_8,"Numpad 9": KEY_KP_9,
	"Numpad .": KEY_KP_PERIOD,"Numpad /": KEY_KP_DIVIDE,
	"Numpad *": KEY_KP_MULTIPLY,"Numpad -": KEY_KP_SUBTRACT,
	"Numpad +": KEY_KP_ADD,"Numpad Enter": KEY_KP_ENTER
}

func _ready():
	for action in input_dict.keys():
		add_input_action_key(action,input_dict[action])

func add_input_action_key(action_name: String, key_code: int): 
	var event = InputEventKey.new()
	event.keycode = key_code
	append_action_event(action_name,event)

func append_action_event(action_name:String,event:InputEvent):
	if not InputMap.has_action(action_name): 
		InputMap.add_action(action_name) 
	InputMap.action_add_event(action_name, event)
