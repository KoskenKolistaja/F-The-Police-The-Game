extends Control

var world_position : Vector3 = Vector3.ZERO

@export var icon : Texture



func _ready():
	await get_tree().create_timer(0.1).timeout
	%Icon.texture = icon


func _physics_process(delta):
	self.position = get_viewport().get_camera_3d().unproject_position(world_position)
