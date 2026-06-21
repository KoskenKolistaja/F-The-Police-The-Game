extends Panel

# This array acts as our queue line
var items_to_show = []
# Tracks whether the panel is currently running a sequence
var _is_processing_queue: bool = false





func show_item(new_dic):
	# 1. Add the incoming data to the end of the line
	items_to_show.append(new_dic)
	
	# 2. If we are already running a sequence, stop here. 
	# The loop will eventually get to this item.
	if _is_processing_queue:
		return
		
	# 3. Lock the gate and process the queue
	_is_processing_queue = true
	await _process_queue()
	_is_processing_queue = false


# Internal loop that eats away at the queue until it's empty
func _process_queue() -> void:
	while items_to_show.size() > 0:
		# Grab the first item in line and remove it from the array
		var current_dic = items_to_show.pop_front()
		
		# Execute your sequential logic safely
		modulate.a = 0.0
		%TypeWriterLabel.text = ""
		%CharacterIcon.texture = ItemData.character_icons[current_dic["icon_name"]]
		%CharacterName.text = current_dic["name"]
		
		var tween_in = create_tween()
		tween_in.tween_property(self, "modulate:a", 1.0, 0.5) 
		await tween_in.finished
		
		%TypeWriterLabel.start_typing(current_dic["text"])
		await %TypeWriterLabel.finished
		
		await get_tree().create_timer(3.0).timeout
		
		var tween_out = create_tween()
		tween_out.tween_property(self, "modulate:a", 0.0, 0.5) 
		await tween_out.finished
		
		# Small delay between items so they don't instantly snap back in
		await get_tree().create_timer(0.2).timeout
