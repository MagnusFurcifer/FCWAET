extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene("res://Scenes/GameScene/GameScene.tscn")
	if Input.is_action_just_pressed("ui_cancel"): #This just allows us to quit
		get_tree().quit()
