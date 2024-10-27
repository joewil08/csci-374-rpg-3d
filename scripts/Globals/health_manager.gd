extends Node
class_name health_manager

static var max_life = 4
static var life = 4

static func heal():
	if life < max_life:
		life += 1
