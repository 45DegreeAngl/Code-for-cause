# ServerFunc.gd
extends Node

signal summon_finish()
signal delete_finished()
signal relocate_finished()
signal change_value_finished()
signal call_function_finished()
signal change_value_encoded_finished()

func test_function():
	if multiplayer.get_remote_sender_id() == multiplayer.get_unique_id():
		print("This function was called locally")
	else:
		print("This function was called by the multiplayer authority")

# --- PRIVATE HELPER to reliably find nodes ---
# This is the core of the new system. It can find a node
# whether it's a static manager (by name) or a dynamic object (by ID).
func _get_node_from_identifier(identifier) -> Node:
	var target_node: Node = null
	
	# Check if the identifier is a string for the static registry.
	if identifier is String:
		target_node = Globals.get_static_node(identifier)
	# Check if the identifier is an integer for the dynamic registry.
	elif identifier is int:
		target_node = Globals.get_node_by_id(identifier)

	if is_instance_valid(target_node):
		return target_node
	else:
		printerr("ServerFunc Error: Could not find a valid node for identifier: ", identifier)
		return null

## Spawns a scene and parents it to the node found by the identifier.
func summon(file_path: String, parent_identifier):
	var parent_node = _get_node_from_identifier(parent_identifier)
	if not parent_node:
		summon_finish.emit()
		return null

	var loaded_file = load(file_path)
	if loaded_file is PackedScene:
		var loaded_instance = loaded_file.instantiate()
		parent_node.add_child(loaded_instance, true)
		summon_finish.emit()
		return loaded_instance
	
	summon_finish.emit()
	return null

## Deletes the node found by the identifier.
func delete(victim_identifier):
	var victim_node = _get_node_from_identifier(victim_identifier)
	if victim_node:
		victim_node.queue_free()
	delete_finished.emit()

## Reparents a node to another, both found by their identifiers.
func relocate(destination_identifier, object_identifier, keep_global: bool = false):
	var dest_node = _get_node_from_identifier(destination_identifier)
	var obj_node = _get_node_from_identifier(object_identifier)
	
	if not dest_node or not obj_node:
		relocate_finished.emit()
		return
	
	obj_node.reparent(dest_node, keep_global)
	relocate_finished.emit()

## Changes a variable on the node found by the identifier.
func change_value(object_identifier, var_name: String, new_val):
	var obj_node = _get_node_from_identifier(object_identifier)
	if not obj_node:
		change_value_finished.emit()
		return
		
	if var_name in obj_node:
		obj_node.set(var_name, new_val)
	else:
		print("Variable '", var_name, "' is not in object, cancelling value change.")
	
	change_value_finished.emit()

## Calls a function on the node found by the identifier.
func call_function(object_identifier, func_name: String, parameters: Array = []):
	var obj_node = _get_node_from_identifier(object_identifier)
	if not obj_node:
		call_function_finished.emit()
		return

	if obj_node.has_method(func_name):
		obj_node.callv(func_name, parameters)
	else:
		print(obj_node, " doesn't have function ", func_name)
	
	call_function_finished.emit()

## Changes a value using JSON encoding on the node found by the identifier.
func change_value_encoded(object_identifier, obj_name: String, encoded_data: String):
	var obj_node = _get_node_from_identifier(object_identifier)
	if not obj_node:
		change_value_encoded_finished.emit()
		return
		
	if not (obj_name in obj_node):
		print("Variable name not found within the object, cancelling value change")
		change_value_encoded_finished.emit()
		return
		
	var json = JSON.new()
	var error = json.parse(encoded_data)
	if error == OK:
		obj_node.set(obj_name, json.data)
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", encoded_data, " at line ", json.get_error_line())
	
	change_value_encoded_finished.emit()

# This function is now responsible for finding the correct player's car
# and calling the handle_input method on it.
func process_player_input(player_id: int, input_dict: Dictionary):
	var player_manager = Globals.get_static_node("player_manager")
	if player_manager and player_manager.player_cars.has(player_id):
		var car = player_manager.player_cars[player_id]
		if is_instance_valid(car) and car.has_method("handle_input"):
			car.handle_input(input_dict)
		else:
			printerr("Car for player %d is not valid or has no handle_input method." % player_id)
	else:
		printerr("Could not find car for player %d to process input." % player_id)
