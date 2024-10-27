extends CharacterBody3D

var current_state = player_states.MOVE
enum player_states {MOVE, JUMP, SWORD, FALL, HURT, DEAD}

@export var speed := 4.0
@export var gravity := 20.0
@export var jump_force := 7.0

@onready var player_body = $CharacterArmature
@onready var anim = $AnimationPlayer
@onready var camera = $"../cam_gimbal"
@onready var anim_tree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")
@onready var camera_shake = $"../cam_gimbal/Camera3D"

var angular_speed = 10

var movement
var direction
var sprint_speed = 7.0
var health = health_manager.life

func _physics_process(delta: float):
	match current_state:
		player_states.MOVE:
			move(delta)
		player_states.JUMP:
			jump()
		player_states.SWORD:
			sword(delta)
		player_states.FALL:
			fall(delta)
		player_states.HURT:
			hurt()
		player_states.DEAD:
			dead()
	
	velocity.y -= gravity * delta
	move_and_slide()
			
func anim_set():
	anim_tree.set("parameters/air_state/start_jump/blend_position", movement)
	anim_tree.set("parameters/attack_state/Sword/blend_position", movement)
	anim_tree.set("parameters/ground_state/Idle/blend_position", movement)
	anim_tree.set("parameters/ground_state/Walk/blend_position", movement)
	anim_tree.set("parameters/ground_state/Sprint/blend_position", movement)
	anim_tree.set("parameters/damage_state/hurt/blend_position", movement)
	anim_tree.set("parameters/ground_state/Dead/blend_position", movement)

func _input(event):
	if Input.is_action_just_pressed("player_sword") && current_state == player_states.MOVE && is_on_floor():
		current_state = player_states.SWORD
	if Input.is_action_just_pressed("player_jump") && current_state == player_states.MOVE && is_on_floor():
		current_state = player_states.JUMP

func input_movement(delta):
	anim_tree["parameters/ground_state/conditions/standing"] = true
	movement = Input.get_vector("player_move_left", "player_move_right", "player_move_forward", "player_move_backward")
	direction = Vector3(movement.x, 0, movement.y).rotated(Vector3.UP, camera.rotation.y).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		player_body.rotation.y = lerp_angle(player_body.rotation.y, atan2(velocity.x, velocity.z), delta * angular_speed)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

func move(delta):
	movement = Input.get_vector("player_move_left", "player_move_right", "player_move_forward", "player_move_backward")
	direction = Vector3(movement.x, 0, movement.y).rotated(Vector3.UP, camera.rotation.y).normalized()
	var sprint = false
	
	if Input.is_action_pressed("player_sprint"):
		sprint = true
	if Input.is_action_just_released("player_sprint"):
		sprint = false
	
	if direction && sprint == false:
		anim_set()
		anim_tree["parameters/ground_state/conditions/walking"] = true
		anim_state.travel("ground_state/Walk")
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		player_body.rotation.y = lerp_angle(player_body.rotation.y, atan2(velocity.x, velocity.z), delta * angular_speed)
	elif direction && sprint == true:
		anim_tree["parameters/ground_state/conditions/sprinting"] = true
		anim_state.travel("ground_state/Sprint")
		velocity.x = direction.x * sprint_speed
		velocity.z = direction.z * sprint_speed
		player_body.rotation.y = lerp_angle(player_body.rotation.y, atan2(velocity.x, velocity.z), delta * angular_speed)
	else:
		anim_tree["parameters/ground_state/conditions/standing"] = true
		anim_state.travel("ground_state/Idle")
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

func jump():
	velocity.y = jump_force
	anim_tree["parameters/conditions/jumping"] = true
	anim_state.travel("air_state/start_jump")
	
	if velocity.y > 5.0:
		current_state = player_states.FALL
		
func fall(delta):
	input_movement(delta)
	
	if is_on_floor():
		anim_tree["parameters/conditions/on_ground"] = true
		anim_state.travel("landing")
	
	move_and_slide()

func sword(delta):
	input_movement(delta)
	anim_state.travel("attack_state/Sword")
	
func hurt():
	velocity.x = 0
	velocity.z = 0
	if health_manager.life >= 1:
		anim_state.travel("damage_state/hurt")
	else:
		current_state = player_states.DEAD
		
func dead():
	velocity.x = 0
	velocity.z = 0
	anim_state.travel("ground_state/Dead")
	
func game_over():
	if get_tree():
		get_tree().change_scene_to_file("res://scenes/levels/game_over_menu.tscn")
		health_manager.life = health_manager.max_life
		data.reset()

func reset_state():
	current_state = player_states.MOVE

func _on_hitbox_area_entered(area: Area3D) -> void:
	camera_shake._camera_shake()
	current_state = player_states.HURT
