extends Resource

class_name InfoResource
##what type of item this resource is
@export_enum("Music","Road") var item_type : String = "Music"
##the steam item id of the resource
##this is set on item creation
@export var item_id : int = 0
##the path to the image that the resource is
##Workshop required
@export var description : String = ""
@export var metadata : String = ""
@export var preview_path : String
@export var tags : Array[String] = []
@export var title : String = "null"

##workshop not required
##set this on item creation
@export var uploader : String = ""#on launch this allows you to view the creator of the workshop item
#global var worlds = [InfoResources] these info resources are item_type World
#global var objects = [InfoResources] these info resources are item_type Object
##set this on item creation
@export var file_name : String = ""#on launch this allows you to sort items by item_type and access them
##this is set on res repathing
@export var folder_path : String = "res://"#on launch this allows you to sort items by item_type and access them
