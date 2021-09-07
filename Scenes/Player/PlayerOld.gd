extends KinematicBody

var cmd = {
	forward_move 	= 0.0,
	right_move 		= 0.0,
	up_move 		= 0.0
}
export var isplayer = true
export var sensitivity = .1
export var gravity = 40 #Was 45
export var friction = 15.0
export var move_speed = 14.0
export var run_acceleration = 14.0
export var run_deacceleration = 10.0
export var air_acceleration = 800
export var air_deacceleration_forward = 3.0
export var air_deacceleration_back = 3.0
export var air_control = .3
export var side_strafe_acceleration = 200.0
export var side_strafe_speed = 2
export var jump_speed = 12.0 #Was 20
export var move_scale = 1.0
export var air_slow = 50
export var ground_snap_tolerance = 1
export var const_friction = 10

var on_ladder = false

var move_direction_norm = Vector3()
var player_velocity = Vector3()
var up = Vector3(0,1,0)

var mwheel_jump = false;

var wish_jump = false;
var touching_ground = false;

var has_screen_shaked = false

var current_weapon

var elapsed = 0

#Stats Vars
export var kick_strength = 5

var max_angle = 90
#Access to nodes
onready var head = $head
onready var camera = $head/Camera
onready var shoot_ray = $head/Camera/shoot_cast
onready var timer_label = $head/Camera/UX/timer_data


var max_hp = 3
var hp = 3

func _ready():
	hp = max_hp
	set_physics_process(true)
	GlobalManager.playernode = self
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_weapon = $head/Camera/weapon_node/shotgun
	elapsed = 0


func _physics_process(delta):
	sensitivity = GlobalManager.mouse_sens/10
	queue_jump()
	
	if touching_ground:
		ground_move(delta)
	else:
		air_move(delta)
	player_velocity = move_and_slide(player_velocity, up)
	touching_ground = is_on_floor()

func snap_to_ground(from):
	#var from = global_transform.origin
	var to = from + -global_transform.basis.y * ground_snap_tolerance
	var space_state = get_world().get_direct_space_state()
	
	var result = space_state.intersect_ray(from, to)
	if !result.empty():
		global_transform.origin.y = result.position.y

func set_movement_dir():
	cmd.forward_move = 0.0
	cmd.right_move = 0.0
	if touching_ground:
		cmd.forward_move += int(Input.is_action_pressed("move_forward"))
	cmd.forward_move -= int(Input.is_action_pressed("move_backward")) * 0.5
	cmd.right_move += int(Input.is_action_pressed("move_right"))
	cmd.right_move -= int(Input.is_action_pressed("move_left"))


func queue_jump():

	if !touching_ground: #This is ahack to allow mwheel jumping
		mwheel_jump = false
	#if Input.is_action_just_pressed("jump") and !wish_jump: #No autobhop
	if Input.is_action_pressed("move_jump") and !wish_jump: #autobhop
		wish_jump = true
		has_screen_shaked = false
	if mwheel_jump and !wish_jump: #mwheel jumping
		wish_jump = true
		has_screen_shaked = false
	if Input.is_action_just_released("move_jump"):
		wish_jump = false

func air_move(delta):
	var wishdir = Vector3()
	var wishvel = air_acceleration
	var accel = 0.0
	
	var scale = cmd_scale()
	
	set_movement_dir()
	
	wishdir += transform.basis.x * cmd.right_move
	wishdir -= transform.basis.z * cmd.forward_move
	
	var wishspeed = wishdir.length()
	wishspeed *= move_speed
	
	wishdir = wishdir.normalized()
	move_direction_norm = wishdir
	
	var wishspeed2 = wishspeed
	if player_velocity.dot(wishdir) < 0:
		accel = air_deacceleration_forward
	else:
		accel = air_acceleration
	
	if(cmd.forward_move == 0) and (cmd.right_move != 0):
		if wishspeed > side_strafe_speed:
			wishspeed = side_strafe_speed
		accel = side_strafe_acceleration
		
	accelerate(wishdir, wishspeed, accel, delta)
	if air_control > 0:
		air_control(wishdir, wishspeed2, delta)
		
	player_velocity.y -= gravity * delta

func air_control(wishdir, wishspeed, delta):
	var zspeed = 0.0
	var speed = 0.0
	var dot = 0.0
	var k = 0.0
	
	if (abs(cmd.forward_move) < 0.001) or (abs(wishspeed) < 0.001):
		return
	zspeed = player_velocity.y
	player_velocity.y = 0
	
	speed = player_velocity.length()
	player_velocity = player_velocity.normalized()
	
	dot = player_velocity.dot(wishdir)
	k = 32.0
	k *= air_control * dot * dot * delta
	
	if dot > 0:
		player_velocity.x = player_velocity.x * speed + wishdir.x * k
		player_velocity.y = player_velocity.y * speed + wishdir.y * k 
		player_velocity.z = player_velocity.z * speed + wishdir.z * k 
		player_velocity = player_velocity.normalized()
		move_direction_norm = player_velocity
	
	player_velocity.x *= speed 
	player_velocity.y = zspeed 
	player_velocity.z *= speed 

func ground_move(delta):
	var wishdir = Vector3()
	
	if (!wish_jump):
		apply_friction(1.0, delta)
	else:
		apply_friction(0, delta)
	
	set_movement_dir()
	
	var scale = cmd_scale()
	
	wishdir += transform.basis.x * cmd.right_move
	wishdir -= transform.basis.z * cmd.forward_move
	
	wishdir = wishdir.normalized()
	move_direction_norm = wishdir
	
	var wishspeed = wishdir.length()
	wishspeed *= move_speed
	
	accelerate(wishdir, wishspeed, run_acceleration, delta)
	
	player_velocity.y = 0.0
	
	if wish_jump:
		player_velocity.y = jump_speed
		wish_jump = false

func apply_friction(t, delta):
	var vec = player_velocity
	var speed = 0.0
	var newspeed = 0.0
	var control = 0.0
	var drop = 0.0
	
	vec.y = 0.0
	speed = vec.length()
	drop = 0.0
	
	if touching_ground:
		if speed < run_deacceleration:
			control = run_deacceleration
		else:
			control = speed
		drop = control * friction * delta * t
	
	newspeed = speed - drop;
	if newspeed < 0:
		newspeed = 0
	if speed > 0:
		newspeed /= speed
	
	player_velocity.x *= newspeed
	player_velocity.z *= newspeed

func accelerate(wishdir, wishspeed, accel, delta):
	var addspeed = 0.0
	var accelspeed = 0.0
	var currentspeed = 0.0
	
	currentspeed = player_velocity.dot(wishdir)
	addspeed = wishspeed - currentspeed
	if addspeed <=0:
		return
	accelspeed = accel * delta * wishspeed
	if accelspeed > addspeed:
		accelspeed = addspeed
	
	player_velocity.x += accelspeed * wishdir.x
	player_velocity.z += accelspeed * wishdir.z

func cmd_scale():
	var var_max = 0
	var total = 0.0
	var scale = 0.0
	
	var_max = int(abs(cmd.forward_move))
	if(abs(cmd.right_move) > var_max):
		var_max = int(abs(cmd.right_move))
	if var_max <= 0:
		return 0
	
	total = sqrt(cmd.forward_move * cmd.forward_move + cmd.right_move * cmd.right_move)
	scale = move_speed * var_max / (move_scale * total)
	
	return scale

func _input(ev):
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if (ev is InputEventMouseMotion):
		rotate_y(-deg2rad(ev.relative.x) * sensitivity)
		var x_delta = ev.relative.y * sensitivity
		camera.rotate_x(deg2rad(-x_delta)) #Mose go verticcal, camera rotate up and down (Lateral axis)
		camera.rotation.x = clamp(camera.rotation.x, deg2rad(-90), deg2rad(90))

	if (ev is InputEventMouseButton):
		if ev.is_pressed():
			if ev.button_index == 5: # Scroll Down
				mwheel_jump = true
			if ev.button_index == 4: # Scroll Up
				mwheel_jump = true
	

func hit():
	print("Player Hit")
	$hitsfx.stream.loop = false
	$hitsfx.play()
	$head/Camera.shake(0.5, 40, 0.2)
	hp = hp - 1

func _process(delta):
	elapsed += delta;
	timer_label.text = "%0.3f" % elapsed
	if hp == 0:
		$head/Camera/UX/hp1.color = Color("black")
		$head/Camera/UX/hp2.color = Color("black")
		$head/Camera/UX/hp3.color = Color("black")
		get_tree().change_scene("res://Scenes/GameScene/GameScene.tscn")
	if hp == 1:
		$head/Camera/UX/hp1.color = Color("b40000")
		$head/Camera/UX/hp2.color = Color("black")
		$head/Camera/UX/hp3.color = Color("black")
	if hp == 2:
		$head/Camera/UX/hp1.color = Color("b40000")
		$head/Camera/UX/hp2.color = Color("b40000")
		$head/Camera/UX/hp3.color = Color("black")
	if hp == 3:
		$head/Camera/UX/hp1.color = Color("b40000")
		$head/Camera/UX/hp2.color = Color("b40000")
		$head/Camera/UX/hp3.color = Color("b40000")
	
	if Input.is_action_just_pressed("ui_cancel"): #This just allows us to quit
		get_tree().quit()
		
	if Input.is_action_just_pressed("action_shoot"):
		current_weapon.fire(self)
		if shoot_ray.is_colliding():
			print("Shooting ray colliding")
			var target = shoot_ray.get_collider()
			if shoot_ray.get_collider().is_in_group("shootable"):
				target.hit()
