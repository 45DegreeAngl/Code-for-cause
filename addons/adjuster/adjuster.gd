@tool
extends EditorPlugin

var vbox:VBoxContainer
var adjust_tree_button : Button
var adjust_lamp_button : Button

func _enter_tree() -> void:
	vbox = VBoxContainer.new()
	# Initialization of the plugin goes here.
	adjust_tree_button = Button.new()
	adjust_tree_button.text = "Adjust Tree"
	adjust_tree_button.pressed.connect(_on_adjust_tree_button_pressed)
	
	adjust_lamp_button = Button.new()
	adjust_lamp_button.text = "Adjust Lamp"
	adjust_lamp_button.pressed.connect(_on_adjust_lamp_button_pressed)
	
	var apply_parent_transform_button = Button.new()
	apply_parent_transform_button.text = "Apply Parent Transform"
	apply_parent_transform_button.pressed.connect(_on_apply_parent_transform_button_pressed)
	
	var adjust_debris_button = Button.new()
	adjust_debris_button.text = "Adjust Debris"
	adjust_debris_button.pressed.connect(_on_adjust_debris_button_pressed)
	
	vbox.add_child(adjust_tree_button)
	vbox.add_child(adjust_lamp_button)
	vbox.add_child(adjust_debris_button)
	
	vbox.add_child(apply_parent_transform_button)
	vbox.add_child(create_mass_adjuster())
	
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BL,vbox)
	

func _on_adjust_tree_button_pressed():
	var selection = EditorInterface.get_selection()
	
	for node in selection.get_selected_nodes():
		if node is Node3D:
			node.scale = Vector3.ONE
			
			node.position.x*=20
			node.position.z*=20
			node.position.y*=20

func _on_adjust_lamp_button_pressed():
	var selection = EditorInterface.get_selection()
	
	for node in selection.get_selected_nodes():
		print(node)
		if node is Node3D:
			node.scale = Vector3.ONE
			
			node.position.z*=20
			node.position.x*=20
			node.position.y*=20

func _on_apply_parent_transform_button_pressed():
	var selection = EditorInterface.get_selection()
	
	for node in selection.get_selected_nodes():
		if node is Node3D:
			var parent_pos = node.position
			node.position = Vector3.ZERO
			for child in node.get_children():
				if child is Node3D:
					child.position+=parent_pos

func _on_adjust_barrier_button_pressed():
	pass

func _on_adjust_debris_button_pressed():
	var selection = EditorInterface.get_selection()
	
	for node in selection.get_selected_nodes():
		print(node)
		if node is Node3D:
			node.position.z*=20
			node.position.x*=20


var number_input:LineEdit
var option_dropdown : OptionButton
var function_dropdown : OptionButton
var mass_adjust_pos_button : Button

func create_mass_adjuster()->VBoxContainer:
	var mass_adjuster : VBoxContainer = VBoxContainer.new()
	
	number_input = LineEdit.new()
	option_dropdown = OptionButton.new()
	option_dropdown.add_item("x")
	option_dropdown.add_item("y")
	option_dropdown.add_item("z")
	function_dropdown = OptionButton.new()
	function_dropdown.add_item("+")
	function_dropdown.add_item("*")
	function_dropdown.add_item("/")
	function_dropdown.add_item("=")
	mass_adjust_pos_button = Button.new()
	mass_adjust_pos_button.text = "Mass Apply"
	mass_adjust_pos_button.pressed.connect(_on_mass_adjust_pos_pressed)
	mass_adjuster.add_child(number_input)
	mass_adjuster.add_child(function_dropdown)
	mass_adjuster.add_child(option_dropdown)
	mass_adjuster.add_child(mass_adjust_pos_button)
	return mass_adjuster

func _on_mass_adjust_pos_pressed():
	var input_number = number_input.text.to_float()
	
	var selection = EditorInterface.get_selection()
	
	for node in selection.get_selected_nodes():
		if node is Node3D:
			##go by axis, then by function
			match option_dropdown.selected:
				0:
					match function_dropdown.selected:
						0:
							node.position.x+=input_number
						1:
							node.position.x*=input_number
						2:
							node.position.x/=input_number
						3:
							node.position.x=input_number
					
				1:
					match function_dropdown.selected:
						0:
							node.position.y+=input_number
						1:
							node.position.y*=input_number
						2:
							node.position.y/=input_number
						3:
							node.position.y=input_number
					
				2:
					match function_dropdown.selected:
						0:
							node.position.z+=input_number
						1:
							node.position.z*=input_number
						2:
							node.position.z/=input_number
						3:
							node.position.z=input_number


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_control_from_docks(vbox)
