extends Node3D

@export var cam_sensitivity = 500
@onready var player = $"../Player"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = player.position


func _input(event):
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x / cam_sensitivity
		rotation.x -= event.relative.y / cam_sensitivity
		rotation.x = clamp(rotation.x, deg_to_rad(-45), deg_to_rad(90))  # limits rotation
