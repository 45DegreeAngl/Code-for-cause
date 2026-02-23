extends Window

## The scene for the individual debug camera window.
## Assign this in the Godot Inspector.
@export var debug_cam_scene: PackedScene

# We will use this array to keep track of the created windows and their UI.
@onready var window_arr: Array[Window] = []
@onready var grid: GridContainer = $VBoxContainer/PanelContainer/ScrollContainer/GridContainer

@export var first_person_cam: Camera3D = null
@export var world_wheel_cam: Camera3D = null
@export var lock_target: Node3D = null  # Assignable target in Inspector
@export var car_target: Node3D = null  # Assign car in Inspector
@export var player_model : MeshInstance3D = null

@export var cops_node : Node3D
@export var sober_node : Node3D
@export var player_vehicle : VehicleBody3D

const CAM_OPTIONS: Array[String] = ["Free", "Car", "FP", "Wheel"]

# --- Main Functions ---

func add_camera() -> void:
	# Ensure the debug camera scene has been assigned in the inspector.
	if not debug_cam_scene:
		printerr("Debug Cam Scene is not set in the Camera Control Panel.")
		return

	# 1. Create the actual debug camera window instance
	var new_cam_window = debug_cam_scene.instantiate()
	
	# --- NEWLY ADDED ---
	# Pass the required node references from this control panel
	# to the new debug window instance.
	new_cam_window.first_person_cam = self.first_person_cam
	new_cam_window.world_wheel_cam = self.world_wheel_cam
	new_cam_window.lock_target = self.lock_target
	new_cam_window.car_target = self.car_target
	new_cam_window.player_model = self.player_model
	# --- END OF NEW CODE ---

	add_child(new_cam_window)
	window_arr.append(new_cam_window)
	
	# Connect the window's own close button to our removal logic
	new_cam_window.close_requested.connect(_on_window_close_requested.bind(new_cam_window))
	
	var cam_index: int = window_arr.size()

	# 2. Create the UI controls for this new window (No changes here)
	var cam_label = LineEdit.new()
	cam_label.text = "Cam " + str(cam_index)
	new_cam_window.title = cam_label.text
	cam_label.text_changed.connect(_on_window_title_changed.bind(new_cam_window))

	var cam_options = OptionButton.new()
	for option in CAM_OPTIONS:
		cam_options.add_item(option)
	cam_options.item_selected.connect(_on_cam_type_selected.bind(new_cam_window))

	var view_button = CheckButton.new()
	view_button.text = "View"
	view_button.toggle_mode = true
	view_button.button_pressed = true
	view_button.toggled.connect(_on_view_button_toggled.bind(new_cam_window))

	var close_button = Button.new()
	close_button.text = "X"
	close_button.pressed.connect(_on_window_close_requested.bind(new_cam_window))
	
	# 3. Add the UI controls to the grid (No changes here)
	grid.add_child(cam_label)
	grid.add_child(cam_options)
	grid.add_child(view_button)
	grid.add_child(close_button)

func remove_camera(window_to_remove: Window) -> void:
	var index = window_arr.find(window_to_remove)
	if index == -1:
		return # Window not found

	# 1. Calculate the start index WITH the header row offset
	# The first camera's UI starts AFTER the first 4 header elements.
	var start_child_index = (index * grid.columns) + grid.columns

	# 2. Safely collect and remove the UI controls for this window
	var children_to_remove: Array[Node] = []
	for i in range(grid.columns):
		# This part of the logic remains simple because we remove the node
		# at the start index each time, letting the next one shift into place.
		var child_node = grid.get_child(start_child_index)
		children_to_remove.append(child_node)
		grid.remove_child(child_node)

	for child in children_to_remove:
		child.queue_free()

	# 3. Remove the window from our tracking array and the scene
	window_arr.pop_at(index)
	window_to_remove.queue_free()
	
	# 4. Update the labels of the remaining camera UI rows
	_update_cam_labels()

# --- Signal Handlers ---

## Called when a window's close button (or the UI 'X' button) is pressed.
func _on_window_close_requested(window: Window) -> void:
	remove_camera(window)

## Called when the View/Hide button is toggled.
func _on_view_button_toggled(toggled_on: bool, window: Window) -> void:
	window.visible = toggled_on

func _on_window_title_changed(new_text:String, window:Window):
	window.title = new_text

## Called when an item in the OptionButton dropdown is selected.
func _on_cam_type_selected(item_index: int, window: Window) -> void:
	# This function calls the 'switch_camera' function inside the target
	# debug cam window. It needs access to that window's camera nodes.
	if window and window.has_method("switch_camera"):
		var camera_to_switch_to
		match item_index:
			0: camera_to_switch_to = window.get_node("SubViewportContainer/SubViewport/CAMERAS/Free")
			1: camera_to_switch_to = window.get_node("SubViewportContainer/SubViewport/CAMERAS/Car")
			2: camera_to_switch_to = window.get_node("SubViewportContainer/SubViewport/CAMERAS/First Person")
			3: camera_to_switch_to = window.get_node("SubViewportContainer/SubViewport/CAMERAS/Wheel")
		
		if camera_to_switch_to:
			window.switch_camera(camera_to_switch_to)

# --- Helper Functions ---

func _update_cam_labels() -> void:
	for i in range(window_arr.size()):
		# Corrected: Add the offset to skip the header row when finding the label
		var label_index_in_grid = (i * grid.columns) + grid.columns
		
		var label_node = grid.get_child(label_index_in_grid) as Label
		if label_node:
			label_node.text = "Cam " + str(i + 1)


func _on_about_to_popup() -> void:
	add_camera()


func _on_close_requested() -> void:
	call_deferred("queue_free")


func _on_instructions_pressed() -> void:
	add_child(load("res://DEBUG/Camera Instructions.tscn").instantiate())
