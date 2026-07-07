extends Node3D

@export var mesh : MeshInstance3D = null

var textures : Array[Texture] = [
	preload("res://Assets/kenney_city-kit-industrial_1.0 (2)/Models/Textures/variation-a.png"),
	preload("res://Assets/kenney_city-kit-industrial_1.0 (2)/Models/Textures/variation-b.png"),
	preload("res://Assets/kenney_city-kit-industrial_1.0 (2)/Models/Textures/variation-c.png"),
]


#func _ready():
	#if mesh:
		#var mat : StandardMaterial3D = mesh.get_active_material(0)
		#
		#if randf() > 0.3:
			#mat.albedo_texture = textures.pick_random()
