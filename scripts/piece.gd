extends Node2D

export (String) var color
var move_tween
var matched = false

# Called when the node enters the scene tree for the first time.
func _ready():
	move_tween=$move_tween

# Move the piece to the target
func move(target):
	move_tween.interpolate_property(self,"position",position,target,.4,
	Tween.TRANS_ELASTIC,Tween.EASE_OUT)
	move_tween.start()

# Dim the piece
func dim():
	var sprite = get_node("Sprite")
	sprite.modulate = Color(1, 1, 1, .5)
	pass