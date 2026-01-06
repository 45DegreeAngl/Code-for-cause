extends Node

@export var cops_node:Node3D
@export var ped_node:Node3D
@export var glob_path:Path3D

#this script is to spawn roads from a list inside of a hideable UI
@export var roads:Node

#array of active roads
var road_array:Array[RoadSegment]

#roads grow in the -z direction and have a center point being position of them
func spawn_road(road:PackedScene):
	var inst:RoadSegment = road.instantiate()
	
	var spawn_pos:Vector3
	
	if road_array.is_empty():
		spawn_pos = Vector3.ZERO
	else:
		var latest_road:RoadSegment = road_array.back()
		
		spawn_pos = latest_road.find_child("Exit").global_position
	
	inst.process_mode = Node.PROCESS_MODE_DISABLED
	
	roads.add_child(inst)
	
	inst.global_position = spawn_pos
	
	road_array.append(inst)
	
	#append path to the global path
	for point_indx:int in inst.nav_curve.curve.point_count:
		var t_pos:Vector3 = inst.global_position + inst.nav_curve.curve.get_point_position(point_indx)
		
		glob_path.curve.add_point(t_pos)


#remove from the front
func delete_road():
	var latest:RoadSegment = road_array.pop_back()
	if not latest:
		return
	var total_points:int = latest.nav_curve.curve.point_count
	
	#remove path from the global path
	for point_indx:int in total_points:
		glob_path.curve.remove_point(total_points - point_indx)
	
	latest.queue_free()

@onready var pedestrian_array:Array = [preload("res://Scenes/Inheritance/Ped/Reckless Ped.tscn"),preload("res://Scenes/Inheritance/Ped/Safe Ped.tscn"),preload("res://Scenes/Inheritance/Ped/Super Ped.tscn")]
@onready var cop_array:Array = [preload("res://Scenes/Inheritance/Cop/RecklessCop.tscn"),preload("res://Scenes/Inheritance/Cop/Safe Cop.tscn"),preload("res://Scenes/Inheritance/Cop/Super Cop.tscn")]
const driver_type_names:Array[String] = ["Reckless","Safe","Super"]

var driver_type:int = 1
func car_setting_selected(index:int):
	driver_type = index

func spawn_car():
	var type = ["Cop","Ped"].pick_random()
	var car_inst:BaseDriver
	var but:Button = Button.new()
	if type =="Cop":
		car_inst = cop_array.get(driver_type).instantiate()
		cops_node.add_child(car_inst)
		but.text= "COP - "
	elif type == "Ped":
		car_inst = pedestrian_array.get(driver_type).instantiate()
		ped_node.add_child(car_inst)
		but.text= "PED - "
	else:
		return
	
	car_inst.global_position = $Marker3D.global_position
	
	but.pressed.connect(delete_vehicle.bind(car_inst,but))
	but.text += driver_type_names.get(driver_type)
	
	$"CanvasLayer/Control/HBoxContainer/Car Container".add_child(but)

func delete_vehicle(veh:BaseDriver,but:Button):
	but.queue_free()
	veh.queue_free()


##UI CONTROLS
@export var road_options:OptionButton
@export var road_to_add:Array[PackedScene]
@onready var road_indx:int = 0

func _on_add_road_pressed() -> void:
	if not road_to_add:
		return
	spawn_road(road_to_add.get(road_indx))

func open_cams():
	Debug.spawn_debug_cam()

func _ready()->void:
	Debug.cops_node = cops_node
	Debug.sober_node = ped_node
	Globals.driving_path = glob_path
	
	road_options.clear()
	
	for road_packed:PackedScene in road_to_add:
		var file_name:String = road_packed.resource_path.get_file()
		road_options.add_item(file_name)


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/Main Menu/main_menu.tscn")


func _on_chosen_road_item_selected(index: int) -> void:
	road_indx = index
