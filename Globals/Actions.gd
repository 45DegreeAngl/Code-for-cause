extends Node

@export var input_dict_keyboard : Dictionary = {
"Space": KEY_SPACE,"Esc": KEY_ESCAPE,
"Tab": KEY_TAB,"Backspace": KEY_BACKSPACE,
"Enter": KEY_ENTER,"Shift": KEY_SHIFT,
"Ctrl": KEY_CTRL,"Alt": KEY_ALT,
"Pause": KEY_PAUSE,"Capslock": KEY_CAPSLOCK,
"Insert": KEY_INSERT,"Delete": KEY_DELETE,
"Home": KEY_HOME,"End": KEY_END,
"Page Up": KEY_PAGEUP,"Page Down": KEY_PAGEDOWN,
"Left": KEY_LEFT,"Up": KEY_UP,
"Right": KEY_RIGHT,"Down": KEY_DOWN,
"A": KEY_A,"B": KEY_B,"C": KEY_C,"D": KEY_D,
"E": KEY_E,"F": KEY_F,"G": KEY_G,"H": KEY_H,
"I": KEY_I,"J": KEY_J,"K": KEY_K,"L": KEY_L,
"M": KEY_M,"N": KEY_N,"O": KEY_O,"P": KEY_P,
"Q": KEY_Q,"R": KEY_R,"S": KEY_S,"T": KEY_T,
"U": KEY_U,"V": KEY_V,"W": KEY_W,"X": KEY_X,
"Y": KEY_Y,"Z": KEY_Z,"0": KEY_0,"1": KEY_1,
"2": KEY_2,"3": KEY_3,"4": KEY_4,"5": KEY_5,
"6": KEY_6,"7": KEY_7,"8": KEY_8,"9": KEY_9,
"F1": KEY_F1,"F2": KEY_F2,"F3": KEY_F3,"F4": KEY_F4,
"F5": KEY_F5,"F6": KEY_F6,"F7": KEY_F7,"F8": KEY_F8,
"F9": KEY_F9,"F10": KEY_F10,"F11": KEY_F11,"F12": KEY_F12,
"Num Lock": KEY_NUMLOCK,"Scroll Lock": KEY_SCROLLLOCK,
"Numpad 0": KEY_KP_0,"Numpad 1": KEY_KP_1,
"Numpad 2": KEY_KP_2,"Numpad 3": KEY_KP_3,
"Numpad 4": KEY_KP_4,"Numpad 5": KEY_KP_5,
"Numpad 6": KEY_KP_6,"Numpad 7": KEY_KP_7,
"Numpad 8": KEY_KP_8,"Numpad 9": KEY_KP_9,
"Numpad .": KEY_KP_PERIOD,"Numpad /": KEY_KP_DIVIDE,
"Numpad *": KEY_KP_MULTIPLY,"Numpad -": KEY_KP_SUBTRACT,
"Numpad +": KEY_KP_ADD,"Numpad Enter": KEY_KP_ENTER,
}

@export var input_dict_joypad_buttons : Dictionary = { 
"A Button": JOY_BUTTON_A, "B Button": JOY_BUTTON_B, "X Button": JOY_BUTTON_X, 
"Y Button": JOY_BUTTON_Y, "Select Button": JOY_BUTTON_BACK, 
"Start Button": JOY_BUTTON_START, "Guide Button": JOY_BUTTON_GUIDE, 
"D-Pad Up": JOY_BUTTON_DPAD_UP, "D-Pad Down": JOY_BUTTON_DPAD_DOWN, 
"D-Pad Left": JOY_BUTTON_DPAD_LEFT, "D-Pad Right": JOY_BUTTON_DPAD_RIGHT, 
"Left Shoulder": JOY_BUTTON_LEFT_SHOULDER, "Right Shoulder": JOY_BUTTON_RIGHT_SHOULDER, 
}

@export var input_dict_joypad_axis : Dictionary = {
	"Left X-Axis":JOY_AXIS_LEFT_X, "Left Y-Axis":JOY_AXIS_LEFT_Y,
	"Right X-Axis":JOY_AXIS_RIGHT_X, "Right Y-Axis":JOY_AXIS_RIGHT_Y,
	"Left Trigger":JOY_AXIS_TRIGGER_LEFT, "Right Trigger":JOY_AXIS_TRIGGER_RIGHT
}

@export var input_dict_mouse : Dictionary = {
	"Left Button": MOUSE_BUTTON_LEFT, "Right Button": MOUSE_BUTTON_RIGHT, 
	"Middle Button": MOUSE_BUTTON_MIDDLE, "Thumb Button 1": MOUSE_BUTTON_XBUTTON1, 
	"Thumb Button 2": MOUSE_BUTTON_XBUTTON2, "Scroll Up": MOUSE_BUTTON_WHEEL_UP, 
	"Scroll Down": MOUSE_BUTTON_WHEEL_DOWN, "Scroll Left": MOUSE_BUTTON_WHEEL_LEFT, 
	"Scroll Right": MOUSE_BUTTON_WHEEL_RIGHT
}

##todo, finish joypad, mouse inputs
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for key in input_dict_keyboard.keys():
		add_input_action_key(key,input_dict_keyboard[key])
	for key in input_dict_mouse.keys():
		add_input_action_mouse(key,input_dict_mouse[key])
	for key in input_dict_joypad_buttons.keys():
		add_input_action_controller_button(key,-1,input_dict_joypad_buttons[key])
	for key in input_dict_joypad_axis.keys():
		add_input_action_controller_axis(key,-1,input_dict_joypad_axis[key])
	#after adding the actions, remove this node from the premises
	queue_free()

func print_input_map()->void:
	var cur_indx : int = 0
	var temp_string : String = ""
	for action in InputMap.get_actions():
		if cur_indx<5:
			cur_indx+=1
			temp_string+=(" "+str(action))
		else:
			cur_indx = 0
			print(temp_string)
			temp_string = ""
	return

func remove_input_action(action_name:String):
	if InputMap.has_action(action_name):
		InputMap.erase_action(action_name)

func append_action_event(action_name:String,event:InputEvent):
	if not InputMap.has_action(action_name): 
		InputMap.add_action(action_name) 
	InputMap.action_add_event(action_name, event)

func add_input_action_mouse(action_name: String, button_index:int):
	var event = InputEventMouseButton.new() 
	event.button_index = button_index 
	append_action_event(action_name,event)

func add_input_action_controller_button(action_name: String, device_index: int, button_index: int):
	var event = InputEventJoypadButton.new() 
	if device_index!=-1:
		event.device = device_index 
	event.button_index = button_index 
	append_action_event(action_name,event)

func add_input_action_controller_axis(action_name:String, device_index:int, axis):
	var event = InputEventJoypadMotion.new()
	if device_index!=-1:
		event.device = device_index 
	event.axis = axis
	append_action_event(action_name,event)

func add_input_action_key(action_name: String, key_code: int): 
	var event = InputEventKey.new()
	event.keycode = key_code
	append_action_event(action_name,event)
