extends Node2D

signal remove_lock

# Called when the node enters the scene tree for the first time.
var lock_pieces = []
var width = 8
var height = 10
var licorice = preload("res://scenes/licorice.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

################################################################################################
################################################################################################
################################################################################################
# SIGNAL: function for make_lock signal
func _on_grid_make_lock(board_position):	
	if lock_pieces.size() == 0:
		lock_pieces = utils.make_2d_array(width,height)
	var current = licorice.instance()
	add_child(current)
	current.position = Vector2(board_position.x * 64 + 64 , -board_position.y * 64 + 800)
	lock_pieces[board_position.x][board_position.y] = current

# SIGNAL: function for damage_lock signal
func _on_grid_damage_lock(board_position):	
	var current_ice_piece = lock_pieces[board_position.x][board_position.y]
	if current_ice_piece != null:
		current_ice_piece.take_damage(1)
		if current_ice_piece.health <= 0:
			current_ice_piece.queue_free()
			lock_pieces[board_position.x][board_position.y] = null
			emit_signal("remove_lock", board_position)