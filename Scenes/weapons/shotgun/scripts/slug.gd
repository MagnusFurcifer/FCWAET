extends Area

var LIFE_TIME = 300
var speed : float = 100.0
var damage : int = 20
var parent_entity

var x_speed
var y_speed

func _ready():
	# Enable bullet collision detection
	connect("body_entered", self, "_on_bullet_hit")
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(1,1,1,1)
	$MeshInstance.set_surface_material(0, mat)
	
	GlobalManager.rng.randomize()
	if GlobalManager.rng.randi() % 2:
		x_speed = -10
		x_speed += GlobalManager.rng.randi() % 5
	
	GlobalManager.rng.randomize()
	if GlobalManager.rng.randi() % 2:
		y_speed = -5
		y_speed += GlobalManager.rng.randi() % 5
		
	$death_timer.start()
	
func _on_bullet_hit(body):
	print("Bullet hit")
	print(body)
	print(body.name)
	if body != parent_entity:
		if body.is_in_group("shootable"):
			body.hit()
		destroy()
		
func set_parent_entity(entity):
	parent_entity = entity
	pass
		
func _physics_process(delta):
	translation -= global_transform.basis.z * speed * delta
	if x_speed:
		translation -= global_transform.basis.x * x_speed * delta
	if y_speed:
		translation -= global_transform.basis.y * y_speed * delta
		
func _on_life_timeout():
	destroy()
	
func destroy():
	queue_free()
