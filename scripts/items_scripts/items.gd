extends CSGBox3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.is_in_group("Sword"):
		queue_free()


func _on_hitbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("player_hitbox"):
		health_manager.life -= 1
		print(health_manager.life)
