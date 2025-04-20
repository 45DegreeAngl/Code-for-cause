extends Control

@export var holder: VBoxContainer 

func load_radio_entries():
	clear_installed_entries()
	
	for nickname:String in Globals.radio_to_load:
		holder.add_child(create_music_entry(nickname,Globals.radio_to_load[nickname]))
	

func clear_installed_entries():
	for child in holder.get_children():
		if child.get_index()!=0:
			child.queue_free()

func music_activity(toggled_on:bool,title:String,file_path:String):
	if toggled_on:
		#add it to the songs list to load
		Globals.radio_to_load[title] = file_path
	else:
		#remove it from songs list to load
		if Globals.radio_to_load.has(title):
			Globals.radio_to_load.erase(title)

func create_music_entry(title:String,file_path:String)->HBoxContainer:
	var temp:HBoxContainer = HBoxContainer.new()
	temp.alignment = BoxContainer.ALIGNMENT_END
	var title_label:Label = Label.new()
	title_label.text = title
	temp.add_child(title_label)
	var spacer:VSeparator = VSeparator.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND
	temp.add_child(spacer)
	var active_checkbox:CheckBox = CheckBox.new()
	active_checkbox.toggled.connect(music_activity.bind(title,file_path))
	temp.add_child(active_checkbox)
	active_checkbox.button_pressed = true
	#var spacer2:VSeparator = VSeparator.new()
	#spacer2.size_flags_horizontal = Control.SIZE_EXPAND
	#temp.add_child(spacer2)
	
	return temp

func open_radio_folder():
	#print(GlobalWorkshop.user_paths["workshop_music"])
	OS.shell_open(ProjectSettings.globalize_path(GlobalWorkshop.user_paths["workshop_music"]))

func create_music_entry_(info:InfoResource)->HBoxContainer:
	var temp:HBoxContainer = HBoxContainer.new()
	var title_label:Label = Label.new()
	title_label.text = info.title
	temp.add_child(title_label)
	if info.item_id!=-1:
		var store_button:Button = Button.new()
		store_button.text = "Visit"
		store_button.pressed.connect(GlobalWorkshop.visit_item.bind(info.item_id))
		temp.add_child(store_button)
	var spacer:VSeparator = VSeparator.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND
	temp.add_child(spacer)
	var active_checkbox:CheckBox = CheckBox.new()
	active_checkbox.toggled.connect(music_activity.bind(info.title,info.folder_path+info.file_name))
	temp.add_child(active_checkbox)
	var spacer2:VSeparator = VSeparator.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND
	temp.add_child(spacer2)
	
	return temp

func _on_reset_radio_to_load_pressed() -> void:
	Globals.load_songs_from_folder()

func _on_back_pressed() -> void:
	Globals.clear_impossible_queues()
	print(Globals.radio_to_load)
