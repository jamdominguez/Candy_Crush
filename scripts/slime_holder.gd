extends Node2D

signal remove_slime

# Called when the node enters the scene tree for the first time.
var slime_pieces = []
var width = 8
var height = 10
var slime = preload("res://scenes/slime.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	print("_ready - ice_holder lock_pieces.size["+String(slime_pieces.size())+"]")

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
# SIGNAL: function for make_lock signal
func _on_grid_make_slime(board_position):	
	if slime_pieces.size() == 0:
		slime_pieces = make_2d_array()
	var current = slime.instance()
	add_child(current)
	current.position = Vector2(board_position.x * 64 + 64 , -board_position.y * 64 + 800)
	slime_pieces[board_position.x][board_position.y] = current

# SIGNAL: function for damage_lock signal
func _on_grid_damage_slime(board_position):	
	var current_slime_piece = slime_pieces[board_position.x][board_position.y]
	if current_slime_piece != null:
		current_slime_piece.take_damage(1)
		if current_slime_piece.health <= 0:
			current_slime_piece.queue_free()
			slime_pieces[board_position.x][board_position.y] = null
			emit_signal("remove_slime", board_position)