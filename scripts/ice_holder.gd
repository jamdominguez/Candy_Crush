extends Node2D

var ice_pieces = []
var width = 8
var height = 10
var ice = preload("res://scenes/ice.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Returns a matrix
func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

################################################################################################
################################################################################################
################################################################################################
# SIGNAL: function for damage_ice signal
func _on_grid_damage_ice(board_position):	
	var current_ice_piece = ice_pieces[board_position.x][board_position.y]
	if current_ice_piece != null:
		current_ice_piece.take_damage(1)
		if current_ice_piece.health <= 0:
			current_ice_piece.queue_free()
			ice_pieces[board_position.x][board_position.y] = null

# SIGNAL: function for make_ice signal
func _on_grid_make_ice(board_position):	
	if ice_pieces.size() == 0:
		ice_pieces = make_2d_array()
	var current = ice.instance()
	add_child(current)
	current.position = Vector2(board_position.x * 64 + 64 , -board_position.y * 64 + 800)
	ice_pieces[board_position.x][board_position.y] = current
