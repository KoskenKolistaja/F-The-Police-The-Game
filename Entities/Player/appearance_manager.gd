extends Skeleton3D

var current_head = null
var current_body = null

var head_name = null
var body_name = null





func randomize_appearance():
	if current_body:
		current_body.queue_free()
	if current_head:
		current_head.queue_free()
	
	var civilian_heads = ClothingData.heads.keys().duplicate()
	var civilian_bodies = ClothingData.bodies.keys().duplicate()
	
	civilian_heads.erase("police_head")
	civilian_bodies.erase("police_body")
	
	var new_head_name = civilian_heads.pick_random()
	var new_body_name = civilian_bodies.pick_random()
	
	
	
	var new_head : MeshInstance3D = ClothingData.heads[new_head_name].instantiate()
	var new_body : MeshInstance3D = ClothingData.bodies[new_body_name].instantiate()
	
	
	current_head = new_head
	current_body = new_body
	
	head_name = new_head_name
	body_name = new_body_name
	
	add_child(new_head)
	add_child(new_body)
	
	new_head.show()
	new_body.show()
	
	new_head.skeleton = new_head.get_path_to(self)
	new_body.skeleton = new_head.get_path_to(self)


func set_police():
	if current_body:
		current_body.queue_free()
	if current_head:
		current_head.queue_free()
	
	var new_head_name = "police_head"
	var new_body_name = "police_body"
	
	
	var new_head : MeshInstance3D = ClothingData.heads[new_head_name].instantiate()
	var new_body : MeshInstance3D = ClothingData.bodies[new_body_name].instantiate()
	
	current_head = new_head
	current_body = new_body
	
	head_name = new_head_name
	body_name = new_body_name
	
	add_child(new_head)
	add_child(new_body)
	
	new_head.show()
	new_body.show()
	
	
	new_head.skeleton = new_head.get_path_to(self)
	new_body.skeleton = new_head.get_path_to(self)

func setup_appearance(appearance_dic):
	if current_body:
		current_body.queue_free()
	if current_head:
		current_head.queue_free()
	
	var civilian_heads = ClothingData.heads.keys().duplicate()
	var civilian_bodies = ClothingData.bodies.keys().duplicate()
	
	civilian_heads.erase("police_head")
	civilian_bodies.erase("police_body")
	
	var new_head_name = appearance_dic["head"]
	var new_body_name = appearance_dic["body"]
	
	
	
	var new_head : MeshInstance3D = ClothingData.heads[new_head_name].instantiate()
	var new_body : MeshInstance3D = ClothingData.bodies[new_body_name].instantiate()
	
	
	current_head = new_head
	current_body = new_body
	
	head_name = new_head_name
	body_name = new_body_name
	
	add_child(new_head)
	add_child(new_body)
	
	new_head.show()
	new_body.show()
	
	new_head.skeleton = new_head.get_path_to(self)
	new_body.skeleton = new_head.get_path_to(self)

func get_appearance() -> Dictionary:
	var dic = {}
	dic["head"] = head_name
	dic["body"] = body_name
	return dic
