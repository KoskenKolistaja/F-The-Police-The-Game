extends Label


var items_to_show = []

var current_area = null


func add_new_item(new_item : String):
	if items_to_show.is_empty():
		items_to_show.append(new_item)
		show_new_item()
	else:
		items_to_show.append(new_item)





func show_new_item():
	if items_to_show.is_empty():
		return
	
	if current_area == items_to_show[0]:
		items_to_show.remove_at(0)
		return
	
	text = items_to_show[0]
	current_area = items_to_show[0]
	
	%AnimationPlayer.play("show_item")


func _on_animation_player_animation_finished(anim_name):
	items_to_show.remove_at(0)
	if not items_to_show.is_empty():
		show_new_item()
