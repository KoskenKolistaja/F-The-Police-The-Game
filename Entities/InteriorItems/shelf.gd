extends StaticBody3D


# Called when the node enters the scene tree for the first time.
func _ready():
	%ShelfEnd.hide()
	var c = get_children().pick_random()
	c.show()
