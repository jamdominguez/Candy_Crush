extends Node2D

export (int) var health

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func take_damage(damage):
	health -= damage
	#print("take_damage["+damage+"] health["+health+"]")
	# Can add damage effect here