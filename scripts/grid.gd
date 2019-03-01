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

func match_at(column,row, color):
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
	
func is_in_grid(column,row):
	if column>=0 &&column<width:
		if row>= 0&& row<height:
			return true
		return false
#return the position in a column and row according to a pixel
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x -x_start)/offset)
	var new_y = round((pixel_y -y_start)/-offset)
	return Vector2(new_x,new_y)
	

func touch_imput():
	if Input.is_action_just_pressed("ui_touch"):
		first_touch =get_global_mouse_position()
		var grid_position = pixel_to_grid(first_touch.x,first_touch.y)
		if is_in_grid(grid_position.x,grid_position.y):
			controlling = true
	if Input.is_action_just_released("ui_touch"):
		final_touch = get_global_mouse_position()
		var grid_position = pixel_to_grid(final_touch.x,final_touch.y)
		if is_in_grid(grid_position.x,grid_position.y) && controlling:
			touch_difference(pixel_to_grid(first_touch.x,first_touch.y), grid_position)
			print("Swip ("+String(grid_position.x)+","+String(grid_position.y)+")")
		controlling = false
		

func swap_pieces(column, row,direction):
	var first_piece =all_pieces[column][row]
	var other_piece =all_pieces[column+direction.x][row+direction.y]
	all_pieces[column][row] = other_piece
	all_pieces[column+direction.x][row+direction.y]= first_piece;
	first_piece.move(grid_to_pixel(column+direction.x,row+direction.y))
	other_piece.move(grid_to_pixel(column,row))

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

func _process(delta):
	touch_imput()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
