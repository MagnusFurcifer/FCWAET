extends KinematicBody

#Movement Vars
export var speed = 10
export var crouch_speed = 2
export var acceleration = 5
export var gravity = 25
export var jump_power = 30
export var mouse_sens = 0.3
export var maximum_slope_angle = 60
var look_at_target = Vector3()

var path = []
var path_node = 0
onready var nav = get_parent()

enum {
	IDLE,
	MOVE,
	WAIT,
	ATTACK
}
var current_state = IDLE
var is_player_in_range = false
var attack_anim_name = "kick"

#Movement Tracking
var velocity = Vector3()
var camera_x_rotation = 0
var is_crouching = false
var has_floor_surface_contact = true
var on_ladder = false
var headbone
var inital_head_transform
var alive = true

#Access to nodes
onready var head = $head
onready var animationplayer = $NPCModel/AnimationPlayer
onready var skeleton = $NPCModel/Skeleton
onready var pathtimer = $PathUpdateTimer
onready var hitparticles = $gun_shot
onready var deathtimer = $deathtimer

onready var attackarea = $head/attack

func _ready():
		pass # Replace with function body.


func hit():
	#print("HIT")
	alive = false
	hitparticles.emitting = true
	$CollisionShape.queue_free()
	$head_collision.queue_free()
	$head.queue_free()
	$PathUpdateTimer.queue_free()
	$hitfx.stream.loop = false
	$hitfx.play()
	skeleton.physical_bones_start_simulation()
	deathtimer.start()
	
func _physics_process(_delta):
	
	if alive:
		if current_state != ATTACK and current_state != WAIT:
			var direction = Vector3()
			var apply_gravity = false
			if is_on_floor() and !on_ladder: #Built in floor detection
				has_floor_surface_contact = true #Yes can jump
				var n = $CollisionShape/slope_ray.get_collision_normal() #Get normal
				var floor_angle = rad2deg(acos(n.dot(Vector3(0, 1, 0)))) #Get the angle of the slope that is intersected by the normal
				if floor_angle > maximum_slope_angle:
					apply_gravity = true
			else:
				has_floor_surface_contact = false
				#This section below is to stop gravity applying if the raycast is colloding but is on floor isn't calculated to be on the floor. Stops sliding down easy slopes
				if $CollisionShape/slope_ray.is_colliding():
					apply_gravity = false
					has_floor_surface_contact = true
				else:
					apply_gravity = true
				
			
			if path_node < path.size():

				direction = (path[path_node] - global_transform.origin)
				
				if abs(direction.x) < 1 and abs(direction.z) < 1:
					path_node += 1

				else:

					velocity = direction.normalized() * speed
					#look_at(global_transform.origin + velocity, Vector3.UP)
					look_at(look_at_target, Vector3.UP)
					if apply_gravity:
						velocity.y -= gravity #Apply gravity to the up/down velocity
					move_and_slide(velocity, Vector3.UP)
				
				
		if current_state == IDLE:
			animationplayer.play("idleanimation")
		elif current_state == MOVE:
			animationplayer.play("walk")
		elif current_state == WAIT:
			animationplayer.play("idleanimation")
		
func move_to(target_pos):
	#print("Move To:")
	#print("Target:" + str(target_pos))
	#print("Origin: " + str(global_transform.origin))
	#print("PATH")
	#print(path)
	#print("Player loc: " + str(GlobalManager.playernode.global_transform.origin))
	var tmp = target_pos
	tmp.y = global_transform.origin.y
	look_at_target = tmp
	path = nav.get_simple_path(global_transform.origin, tmp)
	path_node = 0
	
func attack(body):
	if current_state != WAIT and current_state != ATTACK:
		if body.is_in_group("player"):
			#print("PLAYER IN ATTACK AREA")
			#print(current_state)
			current_state = ATTACK
			animationplayer.playback_speed = 2
			animationplayer.play(attack_anim_name)
			GlobalManager.playernode.hit()
			#print(current_state)

func _on_detect_body_entered(body):
	if body.is_in_group("player"):
		#print(body)
		#print(body.get_parent())
		#print("DETECT PLAYER")
		#print(current_state)
		current_state = MOVE
		move_to(GlobalManager.playernode.global_transform.origin)
		#print(current_state)

func _on_PathUpdateTimer_timeout():
	if alive:
		if current_state == MOVE:
			move_to(GlobalManager.playernode.global_transform.origin)

func _on_AttackTimeoutTimer_timeout():
	if current_state == WAIT:
		#print("ATTACK TIMED OUT")
		#print(current_state)
		if is_player_in_range:
			current_state = MOVE
			attack(GlobalManager.playernode)
		else:
			current_state = MOVE
			move_to(GlobalManager.playernode.global_transform.origin)
			#print(current_state)

func _on_attack_body_entered(body):
	if body.is_in_group("player"):
		is_player_in_range = true
		attack(body)

func animation_finished(name):
	if name == attack_anim_name:
		animationplayer.playback_speed = 1
		#print("ATTACK ANIM FINISHED")
		#print(current_state)
		if current_state == ATTACK:
			current_state = WAIT
			var attack_cooldown = Timer.new()
			attack_cooldown.one_shot = true
			attack_cooldown.connect("timeout", self, "_on_AttackTimeoutTimer_timeout")
			add_child(attack_cooldown)
			attack_cooldown.wait_time = 1
			attack_cooldown.start()
			#print(current_state)
	pass


func _on_attack_body_exited(body):
	if body.is_in_group("player"):
		is_player_in_range = false


func _on_deathtimer_timeout():
	self.queue_free()
