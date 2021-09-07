extends Node


var main
var playernode
var mouse_sens = 2.0
var level = 0

var level_list = [
	"res://Scenes/GameScene/Levels/Debug01/debug01.tscn",
	"res://Scenes/GameScene/Levels/Debug02/debug02.tscn",
	"res://Scenes/GameScene/Levels/Debug03/debug03.tscn",
]

var timer_list = [
	0,
	0,
	0
]

onready var num_levels = level_list.size()

var rng = RandomNumberGenerator.new()
var rng_seed = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.seed = rng_seed
	rng.randomize()
	pass # Replace with function body.

