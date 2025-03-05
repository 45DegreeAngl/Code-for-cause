extends Node3D

@onready var drinks:Dictionary = {"Jaeger":$Bottles/Jaeger,"Sake":$Bottles/Sake,"Beer":$Bottles/Beer}
@onready var multimeshes:Dictionary = {"Beer":$Beer,"Sake":$Sake,"Jaeger":$Jaeger}
@onready var content:Dictionary = {"Beer":3,"Sake":2,"Jaeger":1}
@onready var alchohol_count:int = 0
var randomize_array:Array[String] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_bottles()

const bottle_step_count : float = 2
var x = 0
var z = 0

func update_bottles():
	alchohol_count=0
	##add keys to this temp array to remove them one by one
	for i:String in content.keys():
		#print(i)
		randomize_array.append(i)
	#print(randomize_array)
	var bottle_type = ""
	for instance in $instances.get_children():
		instance.queue_free()
	for balls in randomize_array.size():
		bottle_type = randomize_array.pick_random()
		#print(str(randomize_array),bottle_type)
		randomize_array.erase(bottle_type)
		#print(bottle_type)
		#var cur_multimesh_instance : MultiMeshInstance3D = multimeshes[bottle_type]
		#print(multimeshes[bottle_type].name)
		
		var beg_marker_pos : Vector3 = $Beginning.position
		var end_marker_pos : Vector3 = $End.position
		var bottle_y_pos : float = drinks[bottle_type].position.y
		
		for b in content[bottle_type]:
			alchohol_count+=1
			var new_mesh : MeshInstance3D = MeshInstance3D.new()
			$instances.add_child(new_mesh)
			new_mesh.mesh = drinks[bottle_type].mesh
			
			if beg_marker_pos.x+x*bottle_step_count>end_marker_pos.x:
				z+=1
				x=0
			if beg_marker_pos.z+z*bottle_step_count>end_marker_pos.z:
				z=0
			new_mesh.position = Vector3(beg_marker_pos.x+x*bottle_step_count,bottle_y_pos,beg_marker_pos.z+z*bottle_step_count)
			x+=1
			
		#var cur_multimesh : MultiMesh = MultiMesh.new()
		#cur_multimesh.mesh = drinks[bottle_type].mesh
		#cur_multimesh.transform_format = MultiMesh.TRANSFORM_3D
		#cur_multimesh.instance_count = content[bottle_type]
		#cur_multimesh.visible_instance_count = cur_multimesh.instance_count
		#var beg_transform :Transform3D= Transform3D($Beginning.global_transform.basis,$Beginning.global_transform.origin * $".".scale)
		#var end_transform :Transform3D= Transform3D($End.global_transform.basis,$End.global_transform.origin * $".".scale)
		#var bottle_y:float = drinks[bottle_type].global_transform.origin.y * $".".scale.y
		#
		#for i in cur_multimesh.visible_instance_count:
			##print(x)
			#if beg_transform.origin.x+x*bottle_step_count>end_transform.origin.x:
				#z+=1
				#x=0
			#if beg_transform.origin.z+z*bottle_step_count>end_transform.origin.z:
				##print("balls")
				#z=0
			#
			#cur_multimesh.set_instance_transform(i,Transform3D(Basis(),Vector3(beg_transform.origin.x+x*bottle_step_count,bottle_y,beg_transform.origin.z+z*bottle_step_count)))
			#x+=1
		#cur_multimesh_instance.multimesh = cur_multimesh

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
