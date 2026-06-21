extends Node


var police_id := 0
var first_is_police = true
var second_is_police = false



var items = {
	"pistol" : preload("res://Entities/HandItems/pistol.tscn"),
	"graffiti_bottle" : preload("res://Entities/HandItems/graffiti_bottle.tscn"),
	"camera" : preload("res://Entities/HandItems/camera.tscn"),
	"handcuffs" : preload("res://Entities/HandItems/hand_cuffs.tscn"),
	"spyglass" : preload("res://Entities/HandItems/spyglass.tscn"),
	"uzi" : preload("res://Entities/HandItems/uzi.tscn"),
	"mp5" : preload("res://Entities/HandItems/mp_5.tscn"),
	"smoke_bomb" : preload("res://Entities/HandItems/smoke_bomb.tscn"),
}


var icons = {
	"pistol" : preload("res://Assets/Textures/Icons/pistol-gun.png"),
	"graffiti_bottle" : preload("res://Assets/Textures/Icons/spray.png"),
	"camera" : preload("res://Assets/Textures/Icons/photo-camera.png"),
	"handcuffs" : preload("res://Assets/Textures/Icons/handcuffs.png"),
	"spyglass" : preload("res://Assets/Textures/Icons/magnifying-glass.png"),
	"uzi" : preload("res://Assets/Textures/Icons/uzi.png"),
	"mp5" : preload("res://Assets/Textures/Icons/mp5.png"),
	"smoke_bomb" : preload("res://Assets/Textures/Icons/stun-grenade.png"),
}


var graffitis = [
	preload("res://Assets/Textures/Graffitis/Graffiti.png"),
	preload("res://Assets/Textures/Graffitis/SampoGraffiti.png"),
	preload("res://Assets/Textures/Graffitis/DonSimeon.png"),
	preload("res://Assets/Textures/Graffitis/DonSimeon2.png"),
	preload("res://Assets/Textures/Graffitis/Veljet.png")
]


var character_icons = {
	"police_chief" : preload("res://Assets/Textures/Characters/PoliceChief.png"),
	"mafia_boss" : preload("res://Assets/Textures/Characters/MafiaBoss.png"),
}

var first_names = [
	"James",
	"John",
	"Robert",
	"Michael",
	"William",
	"David",
	"Richard",
	"Joseph",
	"Thomas",
	"Charles",
	"Daniel",
	"Matthew",
	"Anthony",
	"Mark",
	"Donald",
	"Steven",
	"Paul",
	"Andrew",
	"Joshua",
	"Kenneth",
	"Emily",
	"Olivia",
	"Emma",
	"Sophia",
	"Charlotte",
	"Amelia",
	"Isabella",
	"Mia",
	"Evelyn",
	"Harper",
	"Abigail",
	"Ella",
	"Scarlett",
	"Grace",
	"Chloe",
	"Lily",
	"Hannah",
	"Zoe",
	"Nora",
	"Aurora"
]
