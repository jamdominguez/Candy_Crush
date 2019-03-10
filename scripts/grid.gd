extends Node2D

#Grid variables
export (int) var width = 8
export (int) var height = 10
export (int) var x_start = 64
export (int) var y_start = 800
export (int) var offset =  64

#The piece array
var possible_pieces = [
	preload("res://scenes/piece/piece_blue.tscn"),
	preload("res://scenes/piece/piece_green.tscn"),
	preload("res://scenes/piece/piece_light_green.tscn"),
	preload("res://scenes/piece/piece_orange.tscn"),
	preload("res://scenes/piece/piece_yellow.tscn"),
	preload("res://scenes/piece/piece_pink.tscn")
]
#current pieces in the screen
var all_pieces

#Touch Variables
var first_touch= Vector2(0,0)
var final_touch= Vector2(0,0)
var controlling = false

# Called when the node enters the scene tree for the first time.
func _ready():
	all_pieces = make_2d_array()
	spawn_piece()

func _process(delta):
	touch_imput()

#Return a matrix
func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

#Set all pieces into the grid
func spawn_piece():
	randomize()
	for i in width:
		for j in height:
			#choose a random nuber and store it
			var rand = randi() % possible_pieces.size()
			#var rand = floor(rand_range(0, possible_pieces.size()))
			#Instance that piece from the array
			var piece = possible_pieces[rand].instance()
			var loops = 0
			while (match_at(i,j,piece.color) && loops < 100):
				rand = randi() % possible_pieces.size()
				loops += 1
				piece = possible_pieces[rand].instance()
			add_child(piece)
			piece.position = grid_to_pixel(i,j)
			all_pieces[i][j] = piece

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

#Return the position in pixel according column and row
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start + -offset * row
	return Vector2(new_x,new_y)
	
func is_in_grid(grid_position):
	if grid_position.x>=0 &&grid_position.x<width:
		if grid_position.y>= 0&& grid_position.y<height:
			return true
		return false

#return the position in a column and row according to a pixel
func pixel_to_grid(pixel):
	var new_x = round((pixel.x -x_start)/offset)
	var new_y = round((pixel.y -y_start)/-offset)
	return Vector2(new_x,new_y)

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

func swap_pieces(column, row,direction):
	var first_piece =all_pieces[column][row]
	var other_piece =all_pieces[column+direction.x][row+direction.y]
	if first_piece != null && other_piece != null:
		all_pieces[column][row] = other_piece
		all_pieces[column+direction.x][row+direction.y]= first_piece;
		first_piece.move(grid_to_pixel(column+direction.x,row+direction.y))
		other_piece.move(grid_to_pixel(column,row))
		find_matches()

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

# Find the pieces mat
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
	for i in width:
		for j in height:
			var piece = all_pieces[i][j]
			if piece != null and piece.matched:
				piece.queue_free()
				all_pieces[i][j] = null

# Destroy the pieces mached fater a timing expecified
func _on_destroy_timer_timeout():
	destroy_matches()
