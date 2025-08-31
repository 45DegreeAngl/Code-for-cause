extends Node

@export var game_packed : PackedScene
@export var intro_packed : PackedScene
@export var TitleMusicPlayer :AudioStreamPlayer

func _ready()->void:
	Steam.getCurrentGameLanguage()
	print(OS.get_locale_language())
	TranslationServer.set_locale(OS.get_locale_language())
	$"Main Menu/PanelContainer/VBoxContainer/Start".grab_focus()
	#GlobalSteam.set_up_leaderboards()
	#save_options()

func _on_start_pressed() -> void:
	##set game globals to proper values
	Globals.tutorial = false
	Globals.drunkenness = 20
	Globals.tutorial = true
	Globals.is_cheater = false
	Debug.console_active = false
	Globals.reset_stats()
	Globals.game_over = false
	MainShaderCanvas.visible = true
	Globals.detected = false
	get_tree().change_scene_to_packed(intro_packed)

func _on_options_pressed() -> void:
	$Options.open_options()
	$"Main Menu".visible = false

func _on_radio_workshop_pressed() ->void:
	$"Main Menu".visible = false
	$"Radio Workshop"._show_radio_workshop()

func _on_credits_pressed() -> void:
	$"Main Menu".visible = false
	$Credits.open_credits()

func main_menu():
	$"Main Menu Geometry".visible = true
	$"Main Menu".visible = true
	$Credits.visible = false
	$Options.visible = false
	$Leaderboard.visible = false
	$"Radio Workshop".visible = false
	$"Main Menu/PanelContainer/VBoxContainer/Start".grab_focus()


func on_back()->void:
	main_menu()
	#for child in $"Game World".get_children():
		#child.queue_free()
	#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#if !TitleMusicPlayer.playing:
		#TitleMusicPlayer.playing = true

##Practice,Easy,Medium,Hard,Endless
#[10,25,50,100,INF]
func _on_difficulty_options_item_selected(index: int) -> void:
	Globals.roads_to_win = Globals.roads_to_win_options[index]

func _on_leaderboards_pressed() -> void:
	$"Main Menu".visible = false
	$Leaderboard.visible = true
	$Leaderboard/Back.grab_focus()

func _on_quit_pressed() -> void:
	get_tree().quit()
