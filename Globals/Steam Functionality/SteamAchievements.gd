extends Node

func _ready()->void:
	pass

func setAchievement(ach:String):
	var status = Steam.getAchievement(ach)
	if !status:
		return
	if status["achieved"]:
		print("Already Unlocked")
		return
	Steam.setAchievement(ach)
	print("Unlocked achievement: ",ach)
	if not Steam.storeStats():
		print("Balls")
