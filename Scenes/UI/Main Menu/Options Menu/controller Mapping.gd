# This script handles input remapping for a Godot project.
extends Control

# Variables to manage remapping states.
var is_remapping : bool = false # Indicates if remapping is currently active.
var action_to_remap = null # The input action being remapped.
var remapping_button = null # The button pressed during remapping.

# Movement-related input actions to be displayed and managed.
@onready var movement_actions : Array = [
	"KEYWORD_FORWARD",
	"KEYWORD_BACKWARD",
	"KEYWORD_LEFT",
	"KEYWORD_RIGHT",
	"KEYWORD_JUMP",
]

# Gameplay-related input actions to be displayed and managed.
@onready var gameplay_actions : Array = [
	"KEYWORD_INTERACT",
	"KEYWORD_ALT_INTERACT",
	"KEYWORD_MISC_INTERACT",
	"KEYWORD_PAUSE",
	"KEYWORD_LEFT_HAND",
	"KEYWORD_RIGHT_HAND"
]

@onready var back_button : Button = $PanelContainer/VBoxContainer/Labels/Back
# Containers for action UI elements.
@export var movement_action_vbox : VBoxContainer
@export var gameplay_action_vbox : VBoxContainer

# Called when the node is ready. Initializes the UI by populating action entries.
func _ready() -> void:
	load_all_actions()

func load_all_actions()->void:
	clear_action_hboxes() # Remove existing action entries.
	# Add entries for movement actions.
	var cur_movement_entry : HBoxContainer
	var movement_action_count : int = 0
	for action_name : String in movement_actions:
		cur_movement_entry = create_action_entry(action_name)
		movement_action_vbox.add_child(cur_movement_entry)
		movement_action_count+=1
		#print(cur_movement_entry.get_index())
		if movement_action_count==1:#if its the top entry
			#print("First movement entry : ", cur_movement_entry)
			cur_movement_entry.get_child(6).focus_neighbor_top = back_button.get_path()
			back_button.focus_neighbor_bottom = cur_movement_entry.get_child(6).get_path()
		else:
			var prev_action_entry:HBoxContainer = movement_action_vbox.get_child(cur_movement_entry.get_index()-1)
			cur_movement_entry.get_child(6).focus_neighbor_top = prev_action_entry.get_child(6).get_path()
			prev_action_entry.get_child(6).focus_neighbor_bottom = cur_movement_entry.get_child(6).get_path()
		
	
	#print(bottom_movement)
	#back_button.focus_neighbor_bottom = movement_action_vbox.get_child(1).get_child(6).get_path()
	# Add entries for gameplay actions.
	var cur_gameplay_entry : HBoxContainer
	var gameplay_action_count :int = 0
	for action_name : String in gameplay_actions:
		cur_gameplay_entry = create_action_entry(action_name)
		gameplay_action_vbox.add_child(cur_gameplay_entry)
		gameplay_action_count+=1
		#print(cur_gameplay_entry.get_index())
		
		if gameplay_action_count==1:
			#print("First entry is : ",cur_gameplay_entry)
			cur_gameplay_entry.get_child(6).focus_neighbor_top = cur_movement_entry.get_child(6).get_path()
			cur_movement_entry.get_child(6).focus_neighbor_bottom = cur_gameplay_entry.get_child(6).get_path()

		else:
			var prev_action_entry:HBoxContainer = gameplay_action_vbox.get_child(gameplay_action_count)
			#print("IS TRUE: ",prev_action_entry == cur_gameplay_entry)
			cur_gameplay_entry.get_child(6).focus_neighbor_top = gameplay_action_vbox.get_node(prev_action_entry.get_path()).get_child(6).get_path()
			prev_action_entry.get_child(6).focus_neighbor_bottom = cur_gameplay_entry.get_child(6).get_path()
	
	cur_gameplay_entry.get_child(6).focus_neighbor_bottom = back_button.get_path()
	back_button.focus_neighbor_top = cur_gameplay_entry.get_child(6).get_path()
	
	

# Clears all UI elements except the default one in the containers.
func clear_action_hboxes():
	# Iterate over children in the movement actions container.
	for child : Node in movement_action_vbox.get_children():
		if child.get_index() != 0: # Skip the default child.
			child.queue_free() # Remove the child.
	# Iterate over children in the gameplay actions container.
	for child : Node in gameplay_action_vbox.get_children():
		if child.get_index() != 0: # Skip the default child.
			child.queue_free() # Remove the child.

# Creates a UI entry for the given action name and returns it as an HBoxContainer.
func create_action_entry(action_name : String) -> HBoxContainer:
	var real_box : HBoxContainer = HBoxContainer.new() # The container for the entry.

	# Create and add a label for the action title.
	var action_title : Label = Label.new()
	action_title.text = tr(action_name) # Translate and set the action name as the label text.
	real_box.add_child(action_title)

	# Create and add a separator between the title and bindings.
	var tit_act_sep : VSeparator = VSeparator.new()
	tit_act_sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Make it fill available space.
	real_box.add_child(tit_act_sep)

	# Get the current input mappings for the action.
	var action_mappings : Array = InputMap.action_get_events(action_name)
	var keyboard_map : InputEvent
	var joypad_map : InputEvent

	# Separate keyboard and joypad input mappings.
	for action : InputEvent in action_mappings:
		if action is InputEventMouse or action is InputEventKey:
			keyboard_map = action
		elif action is InputEventJoypadButton or action is InputEventJoypadMotion:
			joypad_map = action

	# Replace existing mappings with the identified keyboard and joypad mappings.
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, keyboard_map)
	InputMap.action_add_event(action_name, joypad_map)

	# Display keyboard binding in the UI.
	var keyboard_bind_label : Label = Label.new()
	keyboard_bind_label.text = str(keyboard_map.as_text()) # Get and set the text representation.
	real_box.add_child(keyboard_bind_label)

	# Add a separator between keyboard and joypad bindings.
	var key_joy_sep : VSeparator = VSeparator.new()
	key_joy_sep.custom_minimum_size.x = 20 # Set minimum size for spacing.
	real_box.add_child(key_joy_sep)

	# Display joypad binding in the UI.
	var joy_bind_label : Label = Label.new()
	var temp = joypad_map.as_text() # Process joypad mapping text.
	temp = temp.substr(temp.find("(") + 1)
	temp = temp.substr(0, temp.rfind(")"))
	joy_bind_label.text = temp # Set the processed text as label text.
	real_box.add_child(joy_bind_label)

	# Add a separator between joypad bindings and the remapping button.
	var joy_but_sep : VSeparator = VSeparator.new()
	joy_but_sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Make it fill available space.
	real_box.add_child(joy_but_sep)

	# Create and add the button to initiate remapping.
	var change_button : Button = Button.new()
	change_button.text = tr("KEYWORD_CHANGE") # Set button text.
	real_box.add_child(change_button)
	change_button.pressed.connect(receive_bind.bind(action_name, real_box)) # Connect button press to remapping.

	## Print statements for debugging (kept as requested).
	# print(action_name)
	# print(keyboard_bind_label.text)
	# print(temp)

	# Return the completed action entry UI element.
	return real_box

# Popup for remapping inputs.
@onready var binding_popup : Popup = $"Binding Popup"
var cur_action_name : String = "" # Name of the action being remapped.
var cur_action_box : HBoxContainer = null # UI container for the action being remapped.

# Handles the remapping process when the remapping button is pressed.
func receive_bind(action_name : String, hbox : HBoxContainer):
	binding_popup.title = str(tr("BIND_INPUT_LABEL"), tr(action_name)) # Set popup title.
	binding_popup.get_child(0).get_child(0).text = str(tr("BIND_INPUT_LABEL"), tr(action_name)) # Update popup text.
	cur_action_name = action_name # Set current action name.
	cur_action_box = hbox # Set current action UI container.
	binding_popup.popup() # Display the popup.

# Processes input events for remapping in the popup window.
func _on_binding_popup_window_input(event : InputEvent) -> void:
	# Ignore mouse motion or invalid action name.
	if event is InputEventMouseMotion or cur_action_name == "":
		return

	var chosen_kb_map : InputEvent = null # Chosen keyboard mapping.
	var chosen_joy_map : InputEvent = null # Chosen joypad mapping.

	# Determine the type of input event received.
	if event is InputEventMouse or event is InputEventKey:
		chosen_kb_map = event
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		chosen_joy_map = event

	# Update mappings for the action being remapped.
	var action_mappings : Array = InputMap.action_get_events(cur_action_name)
	var keyboard_map : InputEvent
	var joypad_map : InputEvent
	for action : InputEvent in action_mappings:
		if action is InputEventMouse or action is InputEventKey:
			keyboard_map = chosen_kb_map if chosen_kb_map else action # Update keyboard mapping.
		elif action is InputEventJoypadButton or action is InputEventJoypadMotion:
			joypad_map = chosen_joy_map if chosen_joy_map else action # Update joypad mapping.

	# Replace existing mappings with the new ones.
	InputMap.action_erase_events(cur_action_name)
	InputMap.action_add_event(cur_action_name, keyboard_map)
	InputMap.action_add_event(cur_action_name, joypad_map)

	# Update keyboard label in the UI.
	var action_kb_label : Label = cur_action_box.get_child(2)
	action_kb_label.text = str(keyboard_map.as_text())

	# Update joypad label in the UI.
	var action_joy_label : Label = cur_action_box.get_child(4)
	var temp = joypad_map.as_text()
	temp = temp.substr(temp.find("(") + 1)
	temp = temp.substr(0, temp.rfind(")"))
	action_joy_label.text = temp

	# Reset variables and hide the popup.
	cur_action_box = null
	cur_action_name = ""
	binding_popup.hide()

signal back_pressed

func _on_back_pressed() -> void:
	visible = false
	back_pressed.emit()
