extends Sprite

export var border_width : int
var border_color : Color

func _ready():
	var back_sprite = self.get_parent().get_node("BackSprite")
	var back_sprite_texture_size = Vector2(back_sprite.texture.get_width() * back_sprite.get_scale()[0],
			back_sprite.texture.get_height() * back_sprite.get_scale()[1])
	var image = Image.new()
	image.create(back_sprite_texture_size[0] + border_width * 2, back_sprite_texture_size[1] + border_width * 2,
			false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	self.texture.create_from_image(image)
	
	self.material.set_shader_param("shining_width", border_width)
	
	self.hide()

func changeColor(new_color : Color):
	self.border_color = new_color
	self.material.set_shader_param("shining_color", border_color)
	