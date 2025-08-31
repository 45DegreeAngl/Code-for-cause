extends Control
class_name IntroComic

var animp :AnimationPlayer 
var timer : Timer
func _ready():
	timer = $"Next animation timer"
	animp = $AnimationPlayer
	reset_anims()
	
	play_intro()
	$GoToGame.grab_focus()

func reset_anims():
	$"1".visible = false
	$"2".visible = false
	$"3".visible = false
	$"4".visible = false

func play_intro():
	animp.play("scene1")
	await animp.animation_finished
	timer.start()
	await timer.timeout
	animp.play("move_scene1")
	await animp.animation_finished
	
	animp.play("scene2")
	await animp.animation_finished
	timer.start()
	await timer.timeout
	animp.play("move_scene2")
	await animp.animation_finished
	
	animp.play("scene3")
	await animp.animation_finished
	timer.start()
	await timer.timeout
	animp.play("move_scene3")
	await animp.animation_finished
	
	animp.play("scene4")
	await animp.animation_finished
	animp.play("move_scene4")
	await animp.animation_finished

func _on_go_to_game_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/SinglePlayer/Game.tscn")
