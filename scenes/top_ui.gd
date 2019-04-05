extends TextureRect

onready var score_label = $MarginContainer/HBoxContainer/score_label
var current_score = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	_on_grid_update_score(current_score)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

##################################################################################################################################
##################################################################################################################################
##################################################################################################################################
# SIGNAL: Destroy the pieces mached after a timing expecified. It is called when start function on timer node is executed
func _on_grid_update_score(amount_to_change):
	print("_on_grid_update_score")
	current_score += amount_to_change
	score_label.text = String(current_score)