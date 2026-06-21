extends Node3D


func get_photo(appearance_dic : Dictionary) -> ImageTexture:
	
	if appearance_dic["head"] == null:
		return null
	
	%Skeleton3D.setup_appearance(appearance_dic)

	# Wait a frame if the viewport needs time to render
	await RenderingServer.frame_post_draw
	%SubViewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE
	await RenderingServer.frame_post_draw

	var viewport_texture = %SubViewport.get_texture()
	var image = viewport_texture.get_image()

	var image_texture = ImageTexture.create_from_image(image)
	return image_texture
