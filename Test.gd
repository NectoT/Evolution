extends Sprite

func _ready():
	randomize()
	
	var shader_fps = self.material.get_shader_param("fps")
	self.material.set_shader_param("random_shining_start_frame", randi() % shader_fps)
	