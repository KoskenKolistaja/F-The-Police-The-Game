extends Node3D



func fade_object(mesh: MeshInstance3D, alpha: float):
	var mat = mesh.get_active_material(0).duplicate()

	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var color = mat.albedo_color
	color.a = alpha
	mat.albedo_color = color

	mesh.material_override = mat
