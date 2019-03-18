extends Node2D

# State Machine. To control the function calls timing (no refill before collapse for example)
enum {wait, move}
var state

# Grid variables
export (int) var width = 8
export (int) var height = 10
export (int) var x_start = 64
export (int) var y_start = 800
export (int) var offset =  64
export (int) var y_offset = -2

# Obstacle Stuff
export (PoolVector2Array) var empty_spaces
export (PoolVector2Array) var ice_spaces

# Obstacle Signals
signal damage_ice
signal make_ice

# The piece array
var possible_pieces = [
	preload("res://scenes/piece/piece_blue.tscn"),
	preload("res://scenes/piece/piece_green.tscn"),
	preload("res://scenes/piece/piece_light_green.tscn"),
	preload("res://scenes/piece/piece_orange.tscn"),
	preload("res://scenes/piece/piece_yellow.tscn"),
	preload("res://scenes/piece/piece_pink.tscn")
]
# Current pieces in the screen
var all_pieces

# Swap Back Variables
var piece_one = null
var piece_two = null
var last_place = Vector2(0,0)
var last_direction = Vector2(0,0)
var move_checked = false

# Touch Variables
var first_touch= Vector2(0,0)
var final_touch= Vector2(0,0)
var controlling = false

# Called when the node enters the scene tree for the first time.
func _ready():
	print("_ready - grid")
	state = move
	all_pieces = make_2d_array()	
	spawn_piece()
	spawn_ice()

# Check if the place is a available place to move a piece
func restricted_movement(place):
	for i in empty_spaces.size():
		if empty_spaces[i] == place:
			return true
	return false

# Called every frame. 'delta' is the elapsed time since the previous frame
func _process(delta):
	if state == move:
		touch_imput()

# Returns a matrix
func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

# Set all pieces into the grid
func spawn_piece():
	randomize()
	for i in width:
		for j in height:
			set_random_piece_on_grid(i,j)

func spawn_ice():
	for i in ice_spaces.size():
		emit_signal("make_ice", ice_spaces[i])

# Returns true is find at less 3 pieces with same color
func match_at(column, row, color):
	if column > 1:
		if all_pieces[column - 1][row] != null && all_pieces[column - 2][row] != null:
			if all_pieces[column - 1][row].color == color && all_pieces[column - 2][row].color == color:
				return true
	if row > 1:
		if all_pieces[column][row-1] != null && all_pieces[column][row-2] != null:
			if all_pieces[column][row-1].color == color && all_pieces[column][row-2].color == color:
				return true
	return false

# Returns the position in pixel according column and row
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start + -offset * row
	return Vector2(new_x,new_y)

# Check if grid_position is in grid
func is_in_grid(grid_position):
	if grid_position.x>=0 &&grid_position.x<width:
		if grid_position.y>= 0&& grid_position.y<height:
			return true
		return false

# Returns the position in a column and row according to a pixel
func pixel_to_grid(pixel):
	var new_x = round((pixel.x -x_start)/offset)
	var new_y = round((pixel.y -y_start)/-offset)
	return Vector2(new_x,new_y)

# Check if some input is executed by the player
func touch_imput():
	if Input.is_action_just_pressed("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position())):
			first_touch = pixel_to_grid(get_global_mouse_position())
			controlling = true
	if Input.is_action_just_released("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position())):
			controlling = false
			final_touch = pixel_to_grid(get_global_mouse_position())
			touch_difference(first_touch, final_touch)

# Swap a piece in column and row (i,j) to the "direction"
func swap_pieces(column, row,direction):
	var first_piece =all_pieces[column][row]
	var other_piece =all_pieces[column+direction.x][row+direction.y]
	if first_piece != null && other_piece != null:
		store_info(first_piece, other_piece, Vector2(column,row), direction)
		state = wait
		all_pieces[column][row] = other_piece
		all_pieces[column+direction.x][row+direction.y]= first_piece;
		first_piece.move(grid_to_pixel(column+direction.x,row+direction.y))
		other_piece.move(grid_to_pixel(column,row))
		if !move_checked:
			find_matches()

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	# Move the prevously swapped pieces back to the previous place
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = move
	move_checked = false

# Swap the pieces considering the max distance (1) to move
func touch_difference(grid_1,grid_2):
	var difference = grid_2 - grid_1
	if abs(difference.x)>abs(difference.y):
		if difference.x>0:
			swap_pieces(grid_1.x,grid_1.y,Vector2(1,0))
		elif difference.x<0:
			swap_pieces(grid_1.x,grid_1.y,Vector2(-1,0))
	elif abs(difference.y)>abs(difference.x):
		if difference.y>0:
			swap_pieces(grid_1.x,grid_1.y,Vector2(0,1))
		elif difference.y<0:
			swap_pieces(grid_1.x,grid_1.y,Vector2(0,-1))

# Find the pieces matches
func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				if i > 0 && i < width - 1:
					if all_pieces[i-1][j] != null && all_pieces[i+1][j] != null:
						if all_pieces[i-1][j].color == current_color && all_pieces[i+1][j].color == current_color:
							var pieces = [all_pieces[i-1][j], all_pieces[i][j], all_pieces[i+1][j]]
							change_pieces_visibility(pieces, true)
				if j > 0 && j < height - 1:
					if all_pieces[i][j-1] != null && all_pieces[i][j+1] != null:
						if all_pieces[i][j-1].color == current_color && all_pieces[i][j+1].color == current_color:
							var pieces = [all_pieces[i][j-1], all_pieces[i][j], all_pieces[i][j+1]]
							change_pieces_visibility(pieces, true)
	get_parent().get_node('destroy_timer').start()

# Change the visibility of pieces array according matched value
func change_pieces_visibility(pieces, matched):
	for piece in pieces:
		piece.matched = matched
		piece.dim()

# Destroy the pieces matched
func destroy_matches():
	var was_matches = false
	for i in width:
		for j in height:
			var piece = all_pieces[i][j]
			if piece != null and piece.matched:
				#emit_signal("damage_ice", Vector2(i,j))
				was_matches = true
				piece.queue_free()
				all_pieces[i][j] = null
	move_checked = true
	if was_matches:
		get_parent().get_node('collapse_timer').start()
	else:
		swap_back()

# Collapse the pieces into a column
func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null and !restricted_movement(Vector2(i,j)):
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i,j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node('refill_timer').start()

# Refill with pieces a column
func refill_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				set_random_piece_on_grid(i,j)
	after_refill()

# Set a random piece into the grid
func set_random_piece_on_grid(i,j):
	if !restricted_movement(Vector2(i,j)):
		# choose a random number and store it
		var rand = randi() % possible_pieces.size()
		# Instance that piece from the array
		var piece = possible_pieces[rand].instance()
		var loops = 0
		# Check will be different colors in closer pieces
		while (match_at(i,j,piece.color) && loops < 100):
			rand = randi() % possible_pieces.size()
			loops += 1
			piece = possible_pieces[rand].instance()
		add_child(piece)
		# Simulates the piece fallen. Sliding piece
		piece.position = grid_to_pixel(i,j - y_offset)
		piece.move(grid_to_pixel(i,j))
		all_pieces[i][j] = piece

# Check the matches after refill
func after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i,j,all_pieces[i][j].color):
				find_matches()
				get_parent().get_node("destroy_timer").start()
				return
	state = move
	move_checked = false

##################################################################################################################################
##################################################################################################################################
##################################################################################################################################
# SIGNAL: Destroy the pieces mached after a timing expecified. It is called when start function on timer node is executed
func _on_destroy_timer_timeout():
	destroy_matches()

# SIGNAL: Collapse the pieces
func _on_collapse_timer_timeout():
	collapse_columns()

# SIGNAL: Refill the grid with pieces
func _on_refill_timer_timeout():
	refill_columns()