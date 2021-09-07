extends Spatial



var finished = true

func _ready():
	finished = false


func _on_finish_area_body_entered(body):
	if !finished:
		print("Finish detected")
		print(body)
		if body.is_in_group("player"):
			$finish/finish_area.disconnect("body_entered", self, "_on_finish_area_body_entered")
			finished = true
			GlobalManager.playernode.queue_free()
			for i in get_tree().get_nodes_in_group("NPC"):
				i.queue_free()
			get_parent().finish(body)
