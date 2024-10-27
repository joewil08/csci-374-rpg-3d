extends CharacterBody3D

var player = null
var state_machine

const ATTACK_RANGE = 2.5
const RUN_RANGE = 20
const WALK_RANGE = 5

@export var player_path : NodePath
@export var health = 5
@export var speed = 3.0

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_node(player_path)
	state_machine = anim_tree.get("parameters/playback")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	velocity = Vector3.ZERO
	if _target_in_run_range() && GameManager.get_node("Audio/BackgroundMusic").stream != load("res://assets/audio/Action 1 (Loop).wav") && health > 0:
		GameManager.playBGM(load("res://assets/audio/Action 1 (Loop).wav"))
	
	match state_machine.get_current_node():
		"Run":
			nav_agent.set_target_position(player.global_transform.origin)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * (speed * 2)
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
		"Walk":
			nav_agent.set_target_position(player.global_transform.origin)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * speed
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
		"Sword":
			nav_agent.set_target_position(player.global_transform.origin)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * (speed / 1.5)
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		
	
	# Conditions
	anim_tree.set("parameters/conditions/idle", !_target_in_run_range())
	anim_tree.set("parameters/conditions/run", _target_in_run_range() && !_target_in_walk_range())
	anim_tree.set("parameters/conditions/walk", _target_in_walk_range())
	anim_tree.set("parameters/conditions/sword", _target_in_attack_range())
	
	move_and_slide()

func _target_in_run_range():
	return global_position.distance_to(player.global_position) < RUN_RANGE

func _target_in_walk_range():
	return global_position.distance_to(player.global_position) < WALK_RANGE

func _target_in_attack_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE

# Skeleton hits the player
func _on_dagger_area_area_entered(area: Area3D) -> void:
	if area.is_in_group("player_hitbox"):
		health_manager.life -= 1
		print(health_manager.life)

# Skeleton is hit by the player
func _on_hitbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("Sword"):
		health -= 1
		if health > 0:
			anim_tree.set("parameters/conditions/hit", true)
			await $AnimationTree.animation_finished
			anim_tree.set("parameters/conditions/hit", false)
		else:
			anim_tree.set("parameters/conditions/dead", true)
			await get_tree().create_timer(2.5).timeout
			GameManager.playBGM(load("res://assets/audio/Ambience 1.wav"))
			queue_free()
