extends Panel




func set_picture(texture):
	%CriminalPicture.texture = texture


func set_score(amount):
	if amount > 0.0:
		amount = clamp(amount,13.0,1000.0)
	
	%CriminalScore.value = amount



func set_lethality(on : bool):
	if on:
		%LethalContainer.modulate = Color(0,0.7,0)
		%LethalLabel.text = "LETHAL FORCE ALLOWED"
	else:
		%LethalContainer.modulate = Color(0.7,0,0)
		%LethalLabel.text = "LETHAL FORCE NOT ALLOWED"
