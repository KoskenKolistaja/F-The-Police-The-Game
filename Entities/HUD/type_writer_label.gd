extends Label

## Emitted when the text has completely finished typing out.
signal finished

## The delay between each character in seconds.
@export var typing_speed: float = 0.05

# Keeps track of the current typing session to prevent overlapping loops
var _current_pid: int = 0


## Starts the typewriter effect with the provided text.
func start_typing(new_text: String) -> void:
	# Increment the process ID to cancel any currently running typewriter loops
	_current_pid += 1
	var my_pid = _current_pid
	
	text = ""
	var current_index = 0
	
	while current_index < new_text.length():
		# If start_typing was called again, safely abort this old loop
		if my_pid != _current_pid:
			return
			
		var current_char = new_text[current_index]
		text += current_char
		current_index += 1
		
		# Ignore spaces: only pause if the character typed was NOT a space
		if current_char != " ":
			await get_tree().create_timer(typing_speed).timeout

	# Double-check we are still the active process before emitting finished
	if my_pid == _current_pid:
		finished.emit()
