extends Node3D

var actions:Array = ["KEYWORD_FORWARD","KEYWORD_LEFT","KEYWORD_BACKWARD","KEYWORD_RIGHT"]

func _ready():
	var temp : String = ""
	
	for balls in actions:
		var action_mappings : Array = InputMap.action_get_events(balls)
		for action : InputEvent in action_mappings:
			if action is InputEventMouse or action is InputEventKey:
				temp += action.as_text().substr(0,1)
	
	get_child(0).get_child(0).text = tr("TUTORIAL_BILLBOARD_1").format([str(temp)])
	
	
