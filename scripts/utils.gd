extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Returns a matrix
func make_2d_array(width,height):
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array
