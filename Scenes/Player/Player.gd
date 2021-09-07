extends KinematicBody


#Movement Vars
export var speed = 10
export var crouch_speed = 2
export var acceleration = 5
export var gravity = 2
export var jump_power = 30
export var mouse_sens = 0.3
export var maximum_slope_angle = 60


#Stats Vars
export var stamina_max = 100
export var stamina_regen_rate = 10
export var sprint_burn_rate = 10
export var sprint_modifier = 1.5
export var health_max = 100
export var kick_strength = 5

export var max_hp = 3
var hp = 3

#Stat Tracking
var current_health = health_max
var current_stamina = stamina_max

#Movement Tracking
var velocity = Vector3()
var camera_x_rotation = 0
var is_crouching = false
var has_floor_surface_contact = true
var on_ladder = false
var headbone
var inital_head_transform

var handbone

#Held Object Tracking
var held_object = null
var current_backpack = null
var current_weapon = null

#UI
var ui_active = false #When this is true it stops normal input. Allows us to have ui stuff in the world.

#Access to nodes
onready var head = $head
onready var camera = $head/Camera
onready var shoot_ray = $head/Camera/shoot_cast


func _ready():
	GlobalManager.playernode = self
	hp = max_hp
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_weapon = $head/Camera/weapon_node/shotgun

func hit():
	print("Player Hit")
	$hitsfx.stream.loop = false
	$hitsfx.play()
	$head/Camera.shake(0.5, 40, 0.2)
	hp -= 1
	if hp <= 0:
		get_tree().change_scene("res://Scenes/GameScene/GameScene.tscn")

func _input(ev):
	if ev is InputEventMouseMotion and not ui_active:
		rotate_y(deg2rad(-ev.relative.x * mouse_sens)) #If the mouse moves, we rotate the head around the y axis based on the x axis movement of the mouse (ie side movement makes the head actually roates around the vertical line)
		#Only rotate the camera if  the cameras rotateion (up down) is less than 90 or greater than -90
		var x_delta = ev.relative.y * mouse_sens
		camera.rotate_x(deg2rad(-x_delta)) #Mose go verticcal, camera rotate up and down (Lateral axis)
		camera.rotation.x = clamp(camera.rotation.x, deg2rad(-90), deg2rad(90))

func _process(delta):
	
	if Input.is_action_just_pressed("ui_cancel"): #This just allows us to quit
		get_tree().quit()
		
		
	if Input.is_action_just_pressed("action_shoot"):
		current_weapon.fire(self)
		if shoot_ray.is_colliding():
			print("Shooting ray colliding")
			var target = shoot_ray.get_collider()
			if shoot_ray.get_collider().is_in_group("shootable"):
				target.hit()

	###Crouch Implementation
	if Input.is_action_pressed("move_crouch"):
		self.scale.y = 0.5
		is_crouching = true
	else:
		self.scale.y = 1
		is_crouching = false
	########################################################################

func _physics_process(delta):
	
	
	var head_basis = head.get_global_transform().basis #Direction that the head is facing. 
	var direction = Vector3() #Empty vector that will hold our direction after processing
	
	if Input.is_action_pressed("move_forward") and not ui_active:
		direction -= head_basis.z #Direction is toward the direction the head is facing
		#Move up ladders 
		if on_ladder:
			direction += head_basis.y
	elif Input.is_action_pressed("move_backward") and not ui_active:
		#play anim
		direction += head_basis.z #Direction is ttoward the direction the head is facing
	if Input.is_action_pressed("move_left") and not ui_active:
		direction -= head_basis.x #Move perpenticulalry to the direction the head is facing
	elif Input.is_action_pressed("move_right") and not ui_active:
		direction += head_basis.x #Move perpenticulalry to the direction the head is facing
	
	##########Below here we modify speeds before doing the rest of hte movement logic
	var tmp_speed = speed
	
	if !is_crouching: #Only sprint if not croucing
		########################################################
		#Sprinting Impmentation
		if Input.is_action_pressed("move_sprint") and not ui_active:
			if current_stamina > 0:
				tmp_speed = speed * sprint_modifier
				current_stamina -= sprint_burn_rate * delta
		else:
			if current_stamina < stamina_max:
				current_stamina += stamina_regen_rate * delta
		##########################################################
	else: #Apply crouching speed if crouching
		tmp_speed = crouch_speed
		
	#Apply backpack speed penatly
	if current_backpack != null:
		tmp_speed = tmp_speed * current_backpack.pack_speed_penalty
		
	var direction_normalized = direction.normalized() #Normalize the vector so that you move a the same speed in 2 directions as in 1 direction
	velocity = velocity.linear_interpolate(direction_normalized * tmp_speed, acceleration * delta) #Self explanatory really. Interpolate to our target by our accel adjusted for delta
	
	var apply_gravity = false
	if is_on_floor() and !on_ladder: #Built in floor detection
		has_floor_surface_contact = true #Yes can jump
		var n = $CollisionShape/slope_ray.get_collision_normal() #Get normal
		var floor_angle = rad2deg(acos(n.dot(Vector3(0, 1, 0)))) #Get the angle of the slope that is intersected by the normal
		if floor_angle > maximum_slope_angle:
			apply_gravity = true
	elif on_ladder:
		print("On ladder")
		has_floor_surface_contact = false
		apply_gravity = false
	else:
		has_floor_surface_contact = false
		#This section below is to stop gravity applying if the raycast is colloding but is on floor isn't calculated to be on the floor. Stops sliding down easy slopes
		if $CollisionShape/slope_ray.is_colliding():
			apply_gravity = false
			has_floor_surface_contact = true
		else:
			apply_gravity = true
		
		if apply_gravity:
			velocity.y -= gravity #Apply gravity to the up/down velocity
			
			
	if Input.is_action_pressed("move_jump") and has_floor_surface_contact and not ui_active:
		print("Jump")
		velocity.y += jump_power
	
	#Action the move w/ velocity and up vector
	velocity = move_and_slide(velocity, Vector3.UP)


