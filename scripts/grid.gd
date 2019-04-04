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

# Obstacle Stuff FIXME
var empty_spaces = PoolVector2Array([]) #PoolVector2Array([Vector2(0,0),Vector2(7,0),Vector2(0,9),Vector2(7,9),Vector2(3,4),Vector2(4,4),Vector2(3,5),Vector2(4,5)])
var ice_spaces = PoolVector2Array([]) #PoolVector2Array([Vector2(3,0),Vector2(4,0),Vector2(3,9),Vector2(4,9)])
var lock_spaces = PoolVector2Array([]) #PoolVector2Array([Vector2(3,2),Vector2(4,2),Vector2(3,7),Vector2(4,7)])
var concrete_spaces = PoolVector2Array([]) #PoolVector2Array([Vector2(3,1),Vector2(4,1),Vector2(3,8),Vector2(4,8)])
var slime_spaces = PoolVector2Array([]) #PoolVector2Array([Vector2(0,4),Vector2(0,5),Vector2(7,4),Vector2(7,5)])
var damaged_slim = false

# Obstacle Signals
signal damage_ice
signal make_ice
signal make_lock
signal damage_lock
signal make_concrete
signal damage_concrete
signal make_slime
signal damage_slime


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
var all_pieces = []
var current_matches = []

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
	state = move
	all_pieces = make_2d_array()	
	spawn_piece()
	spawn_ice()
	spawn_lock()
	spawn_concrete()
	spawn_slime()

# Check if the place is a available place to move a piece
func restricted_fill(place):
	# Check the empty peices
	if is_in_array(empty_spaces, place):
		return true
	if is_in_array(concrete_spaces, place):
		return true
	if is_in_array(slime_spaces, place):
		return true
	return false

func restricted_move(place):
	# Check the licorice pieces
	if is_in_array(lock_spaces, place):
		return true
	return false

# FIXME[This method has a better implementation]
func is_in_array(array,item):
	for i in array.size():
		if array[i] == item:
			return true
	return false

func remove_from_array(array,item):
	for i in range (array.size() -1, -1, -1):
		if array[i] == item:
			array.remove(i)	

# Called every frame. 'delta' is the elapsed time since the previous frame
func _process(delta):
	if state == move:
		touch_imput()

# Returns a matrix FIXME[Export this method to singleton script]
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

func spawn_lock():
	for i in lock_spaces.size():
		emit_signal("make_lock", lock_spaces[i])

func spawn_concrete():
	for i in concrete_spaces.size():
		emit_signal("make_concrete", concrete_spaces[i])

func spawn_slime():
	for i in slime_spaces.size():
		emit_signal("make_slime", slime_spaces[i])

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
		if not restricted_move(Vector2(column,row)) and not restricted_move(Vector2(column,row) + direction):
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
					if not is_piece_null(i-1,j) && not is_piece_null(i+1,j):
						if all_pieces[i-1][j].color == current_color && all_pieces[i+1][j].color == current_color:
							var pieces = [all_pieces[i-1][j], all_pieces[i][j], all_pieces[i+1][j]]
							#change_pieces_visibility(pieces, true)
							match_and_dim(all_pieces[i-1][j])
							match_and_dim(all_pieces[i][j])
							match_and_dim(all_pieces[i+1][j])
							add_to_array(Vector2(i-1,j))
							add_to_array(Vector2(i,j))
							add_to_array(Vector2(i+1,j))
				if j > 0 && j < height - 1:
					if not is_piece_null(i,j-1) && not is_piece_null(i,j+1):
						if all_pieces[i][j-1].color == current_color && all_pieces[i][j+1].color == current_color:
							var pieces = [all_pieces[i][j-1], all_pieces[i][j], all_pieces[i][j+1]]
							#change_pieces_visibility(pieces, true)
							match_and_dim(all_pieces[i][j-1])
							match_and_dim(all_pieces[i][j])
							match_and_dim(all_pieces[i][j+1])
							add_to_array(Vector2(i,j-1))
							add_to_array(Vector2(i,j))
							add_to_array(Vector2(i,j+1))
	get_bombed_pieces()
	get_parent().get_node('destroy_timer').start()

func get_bombed_pieces():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					if all_pieces[i][j].is_column_bomb:
						match_all_in_column(i)
					elif all_pieces[i][j].is_row_bomb:
						match_all_in_column(j)
					elif all_pieces[i][j].is_adjacent_bomb:
						find_adjacent_pieces(i,j)

func add_to_array(value, array_to_add = current_matches):
	if !array_to_add.has(value):
		array_to_add.append(value)

func is_piece_null(column,row):
	if all_pieces[column][row] == null:
		return true
	false

func match_and_dim(item):
	item.matched = true
	item.dim()

# FIXME[This method is main: Change the visibility of pieces array according matched value]
func change_pieces_visibility(pieces, matched):
	for piece in pieces:
		piece.matched = matched
		piece.dim()

func find_bombs():
	#Iterater over the current_matches array
	for i in current_matches.size():
		# Sotre some values for this mathc
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		var current_color = all_pieces[current_column][current_row].color
		var col_matched = 0
		var row_matched = 0
		# Iterater over the current matches to chekc for column, row and color
		for j in current_matches.size():
			var this_column = current_matches[j].x
			var this_row = current_matches[j].y
			var this_color = all_pieces[current_column][current_row].color
			if this_column == current_column and this_color == current_color:
				col_matched += 1
			if this_row == current_row and this_color == current_color:
				row_matched += 1
		if col_matched == 5 or row_matched == 5:
			print("color bomb")
			return
		elif col_matched >= 3 and row_matched >= 3:
			print("adjacent bomb")
			make_bom(0,current_color)
			return
		elif col_matched == 4:
			print("column bomb")
			make_bom(1,current_color)
			return
		elif row_matched == 4:
			print("row bomb")
			make_bom(2,current_color)
			return

func make_bom(bomb_type,color):
	# iterate over current matches
	for i in current_matches.size():
		# cache a few varaibles
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		if all_pieces[current_column][current_row] == piece_one and piece_one.color == color:
			# Make a piece_one a bomb
			piece_one.matched = false
			change_bomb(bomb_type,piece_one)
		elif all_pieces[current_column][current_row] == piece_two and piece_two.color == color:
			# Make a piece_one a bomb
			piece_two.matched = false
			change_bomb(bomb_type,piece_two)
 
func change_bomb(bomb_type,piece):
	if bomb_type == 0:
		piece.make_adjacent_bomb()
	elif bomb_type == 1:
		piece.make_row_bomb()
	elif bomb_type == 2:
		piece.make_column_bomb()

# Destroy the pieces matched
func destroy_matches():	
	find_bombs()
	var was_matches = false
	for i in width:
		for j in height:
			var piece = all_pieces[i][j]
			if piece != null and piece.matched:
				damage_special(i,j)
				was_matches = true
				piece.queue_free()
				all_pieces[i][j] = null
	move_checked = true
	if was_matches:
		get_parent().get_node('collapse_timer').start()
	else:
		swap_back()
	current_matches.clear()

func check_concrete(column,row):
	# Check Right
	if column  < width - 1:
		emit_signal("damage_concrete", Vector2(column + 1,row))
	# Check Left
	if column  > 0:
		emit_signal("damage_concrete", Vector2(column - 1,row))
	# Check Up
	if row  < height - 1:
		emit_signal("damage_concrete", Vector2(column,row + 1))
	# Check Down
	if row  > 0:
		emit_signal("damage_concrete", Vector2(column,row - 1))

func check_slime(column,row):
	# Check Right
	if column  < width - 1:
		emit_signal("damage_slime", Vector2(column + 1,row))
	# Check Left
	if column  > 0:
		emit_signal("damage_slime", Vector2(column - 1,row))
	# Check Up
	if row  < height - 1:
		emit_signal("damage_slime", Vector2(column,row + 1))
	# Check Down
	if row  > 0:
		emit_signal("damage_slime", Vector2(column,row - 1))

func damage_special(column,row):
	emit_signal("damage_ice", Vector2(column,row))
	emit_signal("damage_lock", Vector2(column,row))
	check_concrete(column,row)
	check_slime(column,row)

# Collapse the pieces into a column
func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null and !restricted_fill(Vector2(i,j)):
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

# FIXME[This method is mine. Set a random piece into the grid]
func set_random_piece_on_grid(i,j):
	if !restricted_fill(Vector2(i,j)):
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
	if !damaged_slim:
		generate_slime()
	state = move
	move_checked = false
	damaged_slim = false

func generate_slime():
	# Make sure there are slime piece on the board
	if slime_spaces.size() > 0:
		var slime_made = false
		var tracker = 0
		while !slime_made and tracker < 100:
			var random_num = randi() % slime_spaces.size()
			var curr_x = slime_spaces[random_num].x
			var curr_y = slime_spaces[random_num].y
			var neighbor =  find_normal_neighbor(curr_x, curr_y)
			if neighbor != null:
				# Turn that neighbor into a slime
				all_pieces[neighbor.x][neighbor.y].queue_free()
				all_pieces[neighbor.x][neighbor.y] = null
				slime_spaces.append(Vector2(neighbor.x, neighbor.y))
				emit_signal("make_slime", Vector2(neighbor.x, neighbor.y))
				slime_made = true
			tracker += 1

func find_normal_neighbor(column,row):
	# Check right first
	if is_in_grid(Vector2(column + 1, row)):
		if all_pieces[column + 1][row] != null:
			return Vector2(column + 1, row)
	# Check left
	if is_in_grid(Vector2(column - 1, row)):
		if all_pieces[column - 1][row] != null:
			return Vector2(column - 1, row)
	# Check up
	if is_in_grid(Vector2(column, row + 1)):
		if all_pieces[column][row + 1] != null:
			return Vector2(column, row + 1)
	# Check right first
	if is_in_grid(Vector2(column, row - 1)):
		if all_pieces[column][row - 1] != null:
			return Vector2(column, row - 1)

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

# SIGNAL: Unlock the locked piece in place
func _on_lock_holder_remove_lock(place):
	#remove_from_array(lock_spaces,place)
	for i in range (lock_spaces.size() -1, -1, -1):
		if lock_spaces[i] == place:
			lock_spaces.remove(i)		

func _on_concrete_holder_remove_concrete(place):
	#remove_from_array(concrete_spaces,place)
	for i in range (concrete_spaces.size() -1, -1, -1):
		if concrete_spaces[i] == place:
			concrete_spaces.remove(i)

func _on_slime_holder_remove_slime(place):
	damaged_slim = true
	#remove_from_array(concrete_spaces,place)
	for i in range (slime_spaces.size() -1, -1, -1):
		if slime_spaces[i] == place:
			slime_spaces.remove(i)

func match_all_in_column(column):
	for i in height:
		if all_pieces[column][i] != null:
			if all_pieces[column][i].is_row_bomb:
				match_all_in_row(i)
			if	all_pieces[column][i].is_adjacent_bomb:
				find_adjacent_pieces(column,i)
			all_pieces[column][i].matched = true

func match_all_in_row(row):
	for i in width:
		if all_pieces[i][row] != null:
			if all_pieces[row][i].is_column_bomb:
				match_all_in_column(i)
			if	all_pieces[row][i].is_adjacent_bomb:
				find_adjacent_pieces(row,i)
			all_pieces[i][row].matched = true

func find_adjacent_pieces(column, row):
	for i in range(-1,2):
		for j in range(-1,2):
			if is_in_grid(Vector2(column + i, row + j)):
				if all_pieces[column + i][row + j] != null:
					if all_pieces[column][i].is_row_bomb:
						match_all_in_row(i)
					if all_pieces[row][i].is_column_bomb:
						match_all_in_column(i)
					all_pieces[column + i][row + j].matched = true
