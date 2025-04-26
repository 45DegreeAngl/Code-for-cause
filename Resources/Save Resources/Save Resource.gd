extends Resource
class_name Save_Options

@export var motion_sickness:bool = false
@export var aracnophobia:bool = false
@export var aracnophilia:bool = false

@export var res_options:int = 0
@export var quality_options:int = 0
@export var window_options:int = 0
@export var language_options:int = 0

@export var mouse_sense_mult : float = 1
@export var contr_sense_mult : float = 1

@export var master_vol:float = 1.0
@export var voice_vol:float = 1.0
@export var music_vol:float = 1.0
@export var world_vol:float = 1.0

# New variable to store controls.
@export var controls : Dictionary = {}  # Stores input mappings as key-value pairs.
