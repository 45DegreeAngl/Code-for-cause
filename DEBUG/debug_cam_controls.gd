extends Window

#we will use a size mod 4 + size div 4 for the different aspects of the camera arr
@onready var window_arr:Array[Window] = []

@onready var grid:GridContainer = $PanelContainer/ScrollContainer/GridContainer

const CAM_OPTIONS:Array[String] = ["Free","Car","FP","Wheel"]

func _on_close_requested() -> void:
	pass # Replace with function body.

func _on_about_to_popup() -> void:
	pass # Replace with function body.


func add_camera():
	var cam_index:int = window_arr.size()+1
	#assemble options
	var cam_label_name:Label = Label.new()
	cam_label_name.text = "Cam"+str(cam_index)
	
	var cam_options:OptionButton = OptionButton.new()
	for option:String in CAM_OPTIONS:
		cam_options.add_item(option)
	cam_options.selected = 0
	
	var duplicate_button:Button = Button.new()
	duplicate_button.text = "Dupe"
	
	var view_button:Button = Button.new()
	view_button.text = "View"
	pass

func on_window_close_requested(window:Window):
	remove_camera(window_arr.find(window))

func remove_camera(index:int):
	var cam_window : Window = window_arr.pop_at(index)
	var entry_start : int = (index+1) * grid.columns
	for i in grid.columns:
		grid.get_child(entry_start+grid.columns-i).call_deferred("queue_free")
	cam_window.call_deferred("queue_free")

func cam_changed_option(option:int,window:Window):
	pass

func set_camera_options(option:int,window:Window):
	pass
