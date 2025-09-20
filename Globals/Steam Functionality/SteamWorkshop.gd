extends Node
##edit, worked in 4.3, unsure if it works in 4.4, especially with the repathing stuff
signal item_uploading_now()
signal item_uploaded_now()
signal item_downloading_now()
signal items_downloaded_now()

var _subscribed_items : Dictionary = {}
const steam_workshop_tos : String = "https://steamcommunity.com/workshop/workshoplegalagreement/"
const game_workshop_page : String = "https://steamcommunity.com/app/3076530/workshop/"
const workshop_item_url : String = "https://steamcommunity.com/sharedfiles/filedetails/?id="

const user_paths : Dictionary= {
	##base directory
	"base":"user://",
	##Save directories
	"save":"user://Saves/",
	##workshop directory
	"workshop":"user://Workshop/",
	##workshop utility directories
	"workshop_upload":"user://Workshop/Upload/",
	##workshop music directories
	"workshop_music":"user://Workshop/Radio/"
	
}
##note if you have PCK files (files in the bottom left editor) 
##and want to copy and edit them into the filesystem you might want to change this ProjectSetting
##editor/export/convert_text_resources_to_binary

func _ready() -> void:
	initialize_workshop()

var loaded_workshop_items : Dictionary = {"Music":[],"Road":[],"Misc":[]}

func initialize_workshop():
	prepare_files()
	print(Steam.getSubscribedItems())
	Steam.item_created.connect(_on_item_created)
	Steam.item_updated.connect(_on_item_update)
	Steam.item_downloaded.connect(_on_item_downloaded)
	#print(FileManager.uPaths["dependency_resource"]+"map_2.tres")
	#var temp_resource = FileManager.load_file(FileManager.uPaths["dependency_resource"]+"map_2.tres")
	#
	##print(temp_resource)
	#_create_item_from_dependency_resource(temp_resource)
	download_subbed_items()
	
	#FileManager.open_directory(get_item_folder(3409627313))

func visit_item(item_id:int):
	OS.shell_open(workshop_item_url+str(item_id))

##DOWNLOAD
var sub_num = 0
var subscribed_counter = 0

func download_subbed_items():
	sub_num = Steam.getSubscribedItems().size()
	for item in Steam.getSubscribedItems():
		item_downloading_now.emit()
		Steam.downloadItem(item,true)

@warning_ignore("unused_parameter")
func _on_item_downloaded(result:int,file_id:int,app_id:int):
	if result == 1:
		_subscribed_items[file_id] = get_item_install_info(file_id)
		#FileManager.sort_folder_to_user_folders(get_item_folder(file_id))
		replace_res_of_a_folder_unbounded_iterative(get_item_folder(file_id))
		#FileManager.open_directory(get_item_folder(file_id))
		load_workshop_info_folders()
	else:
		print("RESULT: ",result)
	subscribed_counter += 1
	if subscribed_counter>=sub_num:
		items_downloaded_now.emit()
##ITEM CREATION
var item_content : String = "res://Dependencies/Error Asset/"
var item_description : String = "Null"
var item_metadata : String = "Null"
var item_preview : String = "res://icon.svg"
var item_tags : Array[String] = []
var item_title : String = "Null"
var item_visibility : int = 0

##for when creating steam items, create a folder inside of the upload folder called info, which would contain a resource or something
##of all relevant info, whether something is a world, what possible settings a world has or configuration
##the tags of this, reccomended player count

func _create_item_in_folder(folder_path:String,description:String="",metadata:String="null",preview:String="res://Dependencies/Error Asset/Error.png",tags:Array[String]=[],title:String="null",visibility:int=0):
	item_content = folder_path
	item_description = description
	item_metadata = metadata
	item_preview = preview
	item_tags = tags
	item_title = title
	item_visibility = visibility
	Steam.createItem(GlobalSteam.game_id,item_visibility)

var temp_file_id : int

func _on_item_created(result:int,file_id:int,tos:bool):
	if tos:
		OS.shell_open(steam_workshop_tos)
	if result == 1:
		item_uploading_now.emit()
		temp_file_id = file_id
		replace_info_item_ids_in_folder_unbounded_iterative(user_paths["workshop_upload"]+"/info",temp_file_id)
		var integer : int = Steam.startItemUpdate(GlobalSteam.game_id,file_id)
		print("SetItemTitle: ",Steam.setItemTitle(integer,item_title))
		print("SetItemDescription: ",Steam.setItemDescription(integer,item_description))
		print("SetItemMetadata: ",Steam.setItemMetadata(integer,item_metadata))
		print("SetItemVisibility: ",Steam.setItemVisibility(integer,item_visibility))
		print("SetItemTags: ",Steam.setItemTags(integer,item_tags))
		print("SetItemContent: ",Steam.setItemContent(integer,ProjectSettings.globalize_path(item_content)))
		print("SetItemPreview: ",Steam.setItemPreview(integer,ProjectSettings.globalize_path(item_preview)))
		Steam.submitItemUpdate(integer,"Created New Item")
		
	else:
		print("cry")

func _on_item_created_fill_in_ids(result:int,file_id:int,tos:bool):
	if tos:
		OS.shell_open(steam_workshop_tos)
	if result == 1:
		temp_file_id = file_id
		var folder_path = user_paths["workshop_upload"]+"info"
		if folder_path.right(1)!="/":
			folder_path+="/"
		folder_path.replace("\\","/")
		var dir = DirAccess.open(folder_path)
		if dir!=null:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name!="":
				if dir.current_is_dir():
					pass
				else:
					var potential_info_res = ResourceLoader.load(folder_path+file_name)
					if potential_info_res is InfoResource:
						print("This info resource: " ,folder_path+file_name, " Is getting value ",temp_file_id)
						potential_info_res.item_id = temp_file_id
						potential_info_res.uploader = GlobalSteam.steam_username + "[" + str(GlobalSteam.steam_id) + "]"
						ResourceSaver.save(potential_info_res,folder_path+file_name)
				file_name = dir.get_next()
			dir.list_dir_end()
		else:
			print("Error: Could not open Directory")
		var integer : int = Steam.startItemUpdate(GlobalSteam.game_id,file_id)
		print("SetItemTitle: ",Steam.setItemTitle(integer,item_title))
		print("SetItemDescription: ",Steam.setItemDescription(integer,item_description))
		print("SetItemMetadata: ",Steam.setItemMetadata(integer,item_metadata))
		print("SetItemVisibility: ",Steam.setItemVisibility(integer,item_visibility))
		print("SetItemTags: ",Steam.setItemTags(integer,item_tags))
		print("SetItemContent: ",Steam.setItemContent(integer,ProjectSettings.globalize_path(item_content)))
		print("SetItemPreview: ",Steam.setItemPreview(integer,ProjectSettings.globalize_path(item_preview)))
		Steam.submitItemUpdate(integer,"Created New Item")
		
	else:
		print("cry")

func _on_item_update(result:int,tos:bool):
	if tos:
		OS.shell_open(steam_workshop_tos)
	if result==1:
		print("Success")
		Steam.subscribeItem(temp_file_id)
	elif result == 25:
		print("Image too big")
	else:
		Steam.deleteItem(temp_file_id)
	item_uploaded_now.emit()
	reset_item_variables()

##resets the variables that item creation uses
func reset_item_variables():
	item_content = "res://Dependencies/Error Asset/"
	item_description = "Null"
	item_metadata = "Null"
	item_preview = "res://icon.svg"
	item_tags = []
	item_title = "Null"
	item_visibility = 0

##UTILITY
func get_item_folder(p_item_id:int)->String:
	return _subscribed_items[p_item_id]["folder"]

func load_workshop_info_folders():
	for item in _subscribed_items:
		load_workshop_info_folder_unbounded_iterative(get_item_folder(item))

func repath_all_workshop_downloads():
	for item in _subscribed_items:
		replace_res_of_a_folder_unbounded_iterative(get_item_folder(item))

func get_item_install_info(p_item_id : int)->Dictionary:
	var info : Dictionary
	info = Steam.getItemInstallInfo(p_item_id)
	
	if info["ret"] == false:
		@warning_ignore("unused_variable")
		var warning = "Item " + str(p_item_id) + " isn't installed or has no content"
	return info

##FILE MANAGEMENT
func prepare_files():
	#userPaths.sort_custom(compare_path_hierarchy)
	var uSorted = user_paths.values()
	uSorted.sort_custom(compare_path_hierarchy)
	#print("--------SCANNING USER--------")
	for path in uSorted:
		check_directory(path)
	#replace_res_of_a_folder_unbounded_iterative(uPaths["workshop_upload"])
	repath_all_workshop_downloads()
	load_workshop_info_folders()

##for the custom sort of the paths so we can check directories in proper order
func compare_path_hierarchy(a,b)->bool:
	var slashA = 0
	var slashB = 0
	for letter in a:
		if letter == '/':
			slashA+=1
	for letter in b:
		if letter == '/':
			slashB+=1
	return slashA<slashB

##checks if the directory exists, if it doesnt, it creates it
func check_directory(folder_path:String)->void:
	if folder_path.right(1)!="/":
		folder_path+="/"
	var dir = DirAccess.open(folder_path)
	if dir == null:
		DirAccess.make_dir_absolute(folder_path)
		print("Created new folder at ",folder_path)

func create_layered_directory(folder_path:String)->void:
	var temp_path : String = ""
	var origin : String
	if folder_path.find("res://")>=0:
		origin = "res://"
	elif folder_path.find("user://")>=0:
		origin = "user://"
	
	var neutered_string :String = folder_path.replace("res://","").replace("user://","")
	for index in neutered_string.length():
		if neutered_string[index]=="/":
			temp_path+="/"
			check_directory(origin+temp_path)
		else:
			temp_path+=neutered_string[index]

func get_files_in_directory_unbounded_iterative(directory_path: String) -> Array:
	var result: Array = []
	var stack = []
	stack.append(directory_path)
	while stack.size() > 0:
		var current_path = stack.pop_back()
		var dir = DirAccess.open(current_path)
		if dir != null:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					if file_name != "." and file_name != "..":
						stack.append(current_path + "/" + file_name)
				else:
					if current_path!="user://":
						result.append(current_path + "/" + file_name)
					else:
						result.append(current_path + file_name)
				file_name = dir.get_next()
			dir.list_dir_end()
		else:
			print("Error: Could not open Directory: ", current_path)

	return result

##replaces res_paths with user paths in the same folder pointing towards the same thing, note for this to work everything 
##within a folder must be within the same folder
func replace_res_paths_in_file(folder_path:String,file_name:String,global_folder_path:String):
	if folder_path.right(1)!="/" :
		folder_path+="/"
	if global_folder_path.right(1)!="/":
		global_folder_path+="/"
	folder_path = folder_path.replace("\\","/")
	global_folder_path.replace("\\","/")
	#print("GLOBAL FOLDER PATH: ",global_folder_path)
	var file = FileAccess.open(folder_path+file_name,FileAccess.READ)
	if file == null:
		print("ERROR FILE NOT ABLE TO LOAD: ",folder_path+file_name)
		return
	
	if !(file_name.find(".tres")>=0 or file_name.find(".tscn")>=0 or file_name.find(".gd")>=0):
		#print("non godot files will not have their paths changed")
		return
	var file_as_text = file.get_as_text()
	var file_changed_flag : bool = false
	var is_info_res : bool = false
	if file_name.find(".tres") >-1 and load(folder_path+file_name) is InfoResource:
		#print("This is an info resource, so we will only changer user://Workshop/Upload/ folder paths to proper ones")
		is_info_res=true
		
	while !file.eof_reached():
		var line : String = file.get_line()
		var res_index : int = line.find("res://")
		if  res_index!=-1 and !is_info_res:
			var left_of_res : String = line.substr(0,res_index)
			var right_of_res : String = line.substr(res_index+6)
			var good_line : String = left_of_res+global_folder_path+right_of_res
			file_as_text = file_as_text.replace(line,good_line.replace("\\","/"))
			file_changed_flag = true
		elif line.find("user://Workshop/Upload/")!=-1:
			#print("line: ",line)
			var good_line = line.replace("user://Workshop/Upload/",global_folder_path.replace("\\","/"))
			#print("line: ",good_line)
			file_as_text = file_as_text.replace(line,good_line)
			file_changed_flag = true
	
	file.close()
	if file_changed_flag:
		#print(folder_path+file_name)
		var new_file = FileAccess.open(folder_path+file_name,FileAccess.WRITE)
		new_file.store_string(file_as_text)
		new_file.close()
	#print(scene.get_script())

func replace_res_of_a_folder_unbounded_iterative(folder_path: String, global_folder_path: String = ""):
	if global_folder_path.is_empty():
		if folder_path.right(1) != "/":
			folder_path = folder_path+"/"
			global_folder_path = folder_path
		else:
			global_folder_path = folder_path
		folder_path = folder_path.replace("\\","/")
		global_folder_path = global_folder_path.replace("\\", "/")
	
	#print("GLOBAL FOLDER PATH: ",global_folder_path)
	#print("Folder path: ",folder_path)
	var stack = []
	stack.append(folder_path)
	while stack.size() > 0:
		var current_path = stack.pop_back()
		var dir = DirAccess.open(current_path)
		if dir != null:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if current_path.right(1)!="/":
					current_path += "/"
				var current_full_path = current_path + file_name
				if dir.current_is_dir():
					if file_name != "." and file_name != "..":
						#print("Directory: ", file_name)
						stack.append(current_full_path)
				else:
					#print("File: ", file_name)
					replace_res_paths_in_file(current_path, file_name, global_folder_path)
				file_name = dir.get_next()
			dir.list_dir_end()
		else:
			print("Error: Could not open Directory: ", current_path)

func replace_info_item_ids_in_folder_unbounded_iterative(folder_path:String,item_id:int):
	if folder_path.right(1)!="/":
		folder_path+="/"
	folder_path.replace("\\","/")
	var stack = []
	stack.push_back(folder_path)

	while stack.size() > 0:
		var current_path = stack.pop_back()
		var dir = DirAccess.open(current_path)
		if dir != null:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				var full_path = current_path + "/" + file_name
				if dir.current_is_dir():
					stack.push_back(full_path)
				else:
					var potential_info_res = load(full_path)
					if potential_info_res is InfoResource:
						potential_info_res.uploader = GlobalSteam.steam_username + "[" + str(GlobalSteam.steam_id) + "]"
						potential_info_res.item_id = item_id
						ResourceSaver.save(potential_info_res, full_path)
				file_name = dir.get_next()
			dir.list_dir_end()
		else:
			print("Error: Could not open Directory")

func load_workshop_info_folder_unbounded_iterative(folder_path:String):
	if folder_path.right(1)!="/":
		folder_path+="/"
	folder_path.replace("\\","/")
	var stack = []
	stack.push_back(folder_path)

	while stack.size() > 0:
		var current_path = stack.pop_back()
		var dir = DirAccess.open(current_path)
		if dir != null:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				var full_path = current_path + "/" + file_name
				if dir.current_is_dir():
					stack.push_back(full_path)
				else:
					var potential_info_res = load(full_path)
					if potential_info_res is InfoResource:
						match potential_info_res.item_type:
							"Music":
								loaded_workshop_items["Music"].push_back(potential_info_res)
							"Road":
								loaded_workshop_items["Road"].push_back(potential_info_res)
							"_":
								loaded_workshop_items["Misc"].push_back(potential_info_res)
				file_name = dir.get_next()
			dir.list_dir_end()
		else:
			print("Error: Could not open Directory")

# Intended to serve as generic error messaging for failed call results.
# Note: this callback is unique to GodotSteam.
func _on_steamworks_error(failed_signal : String, message : String):
	printerr("[GODOTSTEAM] Steamworks Error! Failed Signal %s: %s" %
			[failed_signal, message]) 
