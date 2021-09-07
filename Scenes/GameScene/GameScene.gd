extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var level
var Player

# Called when the node enters the scene tree for the first time.
func _ready():
	#Player = load("res://Scenes/Player/Player.tscn").instance()
	#add_child(Player)
	load_next_level()


func load_next_level():
	print("Loading: " + str(GlobalManager.level))
	level = load(GlobalManager.level_list[GlobalManager.level]).instance()
	add_child(level)
	Player = load("res://Scenes/Player/Player.tscn").instance()
	add_child(Player)
	Player.global_transform.origin = level.get_node("spawn").global_transform.origin
	Player.look_at(level.get_node("spawn").get_node("spawn_dir").global_transform.origin, Vector3.UP)

func _on_killbox_body_entered(body):
	if body.is_in_group("player"):
		print(Player)
		print(level)
		Player.global_transform.origin = level.get_node("spawn").global_transform.origin
		Player.look_at(level.get_node("spawn").get_node("spawn_dir").global_transform.origin, Vector3.UP)
		
func finish(body):
	if GlobalManager.level < GlobalManager.num_levels - 1:
		GlobalManager.timer_list[GlobalManager.level] = Player.elapsed
		Player.elapsed = 0
		if level:
			level.queue_free()
		GlobalManager.level += 1
		load_next_level()
	else:
		GlobalManager.timer_list[GlobalManager.level] = Player.elapsed
		get_tree().change_scene("res://Scenes/EndScreen/EndScreen.tscn")
		print("Game Over")
