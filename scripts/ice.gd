extends Node2D

var health

# Called when the node enters the scene tree for the first time.
func _ready():
	health = 1
	pass # Replace with function body.

func take_damage(damage):
	health -= damage
	print('take_damage damage['+String(damage)+'] health['+String(health)+']')
	# Can add damage effect here