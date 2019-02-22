extends Node2D

#Grid variables
export (int) var width = 8
export (int) var height = 10
export (int) var x_start = 64
export (int) var y_start = 224
export (int) var offset =  64

var possible_pieces = [
	preload("res://scenes/piece/piece_blue.tscn"),
	preload("res://scenes/piece/piece_green.tscn"),
	preload("res://scenes/piece/piece_light_green.tscn"),
	preload("res://scenes/piece/piece_orange.tscn"),
	preload("res://scenes/piece/piece_yellow.tscn"),
	preload("res://scenes/piece/piece_pink.tscn")
]
var all_pieces

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
			print(piece.position)

func match_at(column,row, color):
	if column > 1:
		if all_pieces[column - 1][row] != null && all_pieces[column - 2][row] != null:
			if all_pieces[column - 1][row].color == color && all_pieces[column - 2][row].color == color:
				return true
	if row > 1:
		if all_pieces[column][row-1] != null && all_pieces[column][row-2] != null:
			if all_pieces[column ][row-1].color == color && all_pieces[column][row-2].color == color:
				return true
	return false

#Return the position in pixel according column and row
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start + offset * row
	return Vector2(new_x,new_y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
