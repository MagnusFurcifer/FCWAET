extends Spatial


onready var shoot_ray
export var shoot_range = 1000
export var base_damange = 10
export var slug_dist_value = 30

var num_of_slugs = 16

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func fire(parent_entity):
	if !$AnimationPlayer.is_playing():
		$AnimationPlayer.play("shoot")
		$sfx/fire.play()
		process_shot_physics(parent_entity)
	pass
	
func process_shot_physics(parent_entity):
	for i in num_of_slugs:
		var slug = preload("res://scenes/entities/weapons/shotgun/scenes/slug.tscn").instance()
		
		var slug_transform = parent_entity
		if parent_entity.is_in_group("player"):
			slug_transform = parent_entity.head
		else:
			slug_transform = parent_entity
			
		slug.global_transform = slug_transform.global_transform
		
		slug.set_parent_entity(parent_entity)
		get_tree().root.add_child(slug)
	pass
	
func process_shot_ray(parent_entity):
	if parent_entity.shoot_ray.is_colliding():
		var target = parent_entity.shoot_ray.get_collider()
		if parent_entity.shoot_ray.get_collider().is_in_group("shootable"):
			target.hit(base_damange)
	pass
	
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "shoot":
		$AnimationPlayer.play("cock")
		$sfx/cock.play()
