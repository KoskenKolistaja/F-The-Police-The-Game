extends Node3D



func _ready():
	%Skeleton3D.randomize_appearance()
	var dic = {"head" : "police_head","body" : "body1"}
	
	var mat : StandardMaterial3D = %Example.get_active_material(0)
	mat.albedo_texture = await get_photo(dic)
	
	await get_tree().create_timer(1).timeout
	
	var mat2 : StandardMaterial3D = %Example2.get_active_material(0)
	mat2.albedo_texture = await get_photo({"head" : "head10", "body" : "business_body"})



func get_photo(appearance_dic : Dictionary) -> ImageTexture:
	%Skeleton3D.setup_appearance(appearance_dic)

	# Wait a frame if the viewport needs time to render
	await RenderingServer.frame_post_draw
	%SubViewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE
	await RenderingServer.frame_post_draw

	var viewport_texture = %SubViewport.get_texture()
	var image = viewport_texture.get_image()

	var image_texture = ImageTexture.create_from_image(image)
	return image_texture
