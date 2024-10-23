extends CharacterBody2D

@export var player_camera: PackedScene
@export var camera_height = -232

@export var player_sprite: AnimatedSprite2D

@export var movement_speed = 300
@export var gravity = 30
@export var jump_strength = 600

@onready var initial_sprite_scale = player_sprite.scale

var owner_id = 1
var max_number_of_jumps = 1
var current_number_of_jumps = 0
var camera_instance

func _enter_tree():
	owner_id = name.to_int()
	set_multiplayer_authority(owner_id)
	if not is_player_auth():
		return
	set_up_camera()

func _process(_delta):
	if multiplayer.multiplayer_peer == null:
		return
	if not is_player_auth():
		return
	update_camera_pos()


func _physics_process(_delta):
	if not is_player_auth():
		return
	var horizontal_input = (
		Input.get_action_strength("move_right")
		- Input.get_action_strength("move_left")
	)
	var vertical_input = (
		Input.get_action_strength("jump")
		- Input.get_action_strength("down")
	)
	
	velocity.x = horizontal_input * movement_speed
	velocity.y += gravity
	handle_movement_state(horizontal_input)
	move_and_slide()
	
	

	face_movement_direction(horizontal_input)

func _on_animated_sprite_2d_animation_finished():
	player_sprite.play("jump")

func set_up_camera():
	camera_instance = player_camera.instantiate()
	camera_instance.global_position.y = camera_height
	get_tree().current_scene.add_child.call_deferred(camera_instance)

func update_camera_pos():
	camera_instance.global_position.x = global_position.x

func face_movement_direction(horizontal_input):
	if not is_zero_approx(horizontal_input):
		if horizontal_input < 0:
			player_sprite.scale = Vector2(-initial_sprite_scale.x, initial_sprite_scale.y)
		else:
			player_sprite.scale = initial_sprite_scale
			
func handle_movement_state(horizontal_input):
	var is_falling = velocity.y < 0.0 and not is_on_floor()
	var is_jumping = current_number_of_jumps < max_number_of_jumps and Input.is_action_just_pressed("jump")
	var is_idle = is_zero_approx(horizontal_input) and is_on_floor()
	var is_walking = not is_zero_approx(horizontal_input) and is_on_floor()
	var is_jump_cancelled = Input.is_action_just_pressed("down") and not is_on_floor()
	var is_double_jumping = current_number_of_jumps > 0 
	
	if is_jumping:
		player_sprite.play("jump")
	elif is_double_jumping:
		player_sprite.play("double_jump_start")
	elif is_walking:
		player_sprite.play("walk")
	elif is_falling:
		player_sprite.play("fall")
	elif is_idle:
		player_sprite.play("idle")
	
	if is_jumping:
		velocity.y = -jump_strength
		current_number_of_jumps += 1
	elif is_jump_cancelled:
		velocity.y = gravity
	if is_on_floor():
		current_number_of_jumps = 0	

func is_player_auth():
	return owner_id == multiplayer.get_unique_id()
