extends Control

signal back_pressed()

func _on_close_pressed() -> void:
	back_pressed.emit()

func open_credits()->void:
	visible = true
	$Close.grab_focus()
