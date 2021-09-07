extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var xhair = $xhair

# Called when the node enters the scene tree for the first time.
func _ready():
	xhair.set_position(get_viewport_rect().size / 2)
