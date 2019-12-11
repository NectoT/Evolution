extends Area2D

var enabled_highlight_animation = false
var enabled_highlight = true
var enabled_pickup = true
var picked_up = false
var mouse_inside = false
var highlighted = false

var id
var manager

var animation_start_point : Vector2
var animation_end_point : Vector2

var animation_offset : Vector2
var required_animation_offset : Vector2
var curr_animation_time : float
export var animation_time : float = 1  # can't be zero, i didn't make a check for that so yeah
var animation_speed : Vector2
var animation_acceleration : Vector2

func set_required_animation_offset(offset, time_reset=true):
	if time_reset:
		self.curr_animation_time = 0
	
	if self.curr_animation_time == self.animation_time:
		print("auto animation time reset")
		self.curr_animation_time = 0
	
	self.required_animation_offset = offset
	
	self.animation_start_point = self.transform.origin
	self.animation_end_point = self.pos + self.required_animation_offset
	
	var animation_vector = self.animation_end_point - self.animation_start_point
	
	var time = self.animation_time - self.curr_animation_time
	self.animation_speed = 2 * animation_vector / time
	self.animation_acceleration = -self.animation_speed / time

func add_required_animation_offset(offset, time_reset=true):
	if time_reset:
		self.curr_animation_time = 0
	self.set_required_animation_offset(self.required_animation_offset + offset)

func update_animation():
	set_required_animation_offset(self.required_animation_offset)

func reset_animation():  # makes transform.origin the current position
	self.animation_offset = Vector2(0, 0)
	self.highlight_required_offset = Vector2(0, 0)
	self.set_required_animation_offset(Vector2(0, 0))

var highlight_required_offset : Vector2 setget highlight_required_offset_set

func highlight_required_offset_set(value):
	self.add_required_animation_offset(-self.highlight_required_offset)
	highlight_required_offset = value
	self.add_required_animation_offset(self.highlight_required_offset)

# in radians
var angle_offset = 0
var required_angle_offset = 0
export var angle_animation_time : float = self.animation_time / 2
var curr_angle_animation_time : float
var angle_speed
var angle_acceleration
var pos : Vector2 setget pos_set, pos_get

var start_angle
var end_angle

func set_required_angle_offset(offset, time_reset=true):
	if time_reset:
		self.curr_angle_animation_time = 0
	
	if self.curr_angle_animation_time == self.angle_animation_time:
		print("auto angle animation time reset")
		self.curr_angle_animation_time = 0
	
	self.required_angle_offset = offset
	
	self.start_angle = self.angle_offset
	
	var difference = self.required_angle_offset - self.start_angle
	var time = self.angle_animation_time - self.curr_angle_animation_time
	self.angle_speed = 2 * difference / time
	#print(self.angle_speed, rad2deg(offset))
	print(self.id, " ", rad2deg(self.required_angle_offset), " ")
	self.angle_acceleration = -self.angle_speed / time
	
	self.transform.x = Vector2(1, 0).rotated(offset)
	self.transform.y = Vector2(0, 1).rotated(offset)

func pos_set(value):
	pos = value
	self.update_animation()

func pos_get():
	return pos

func set_pos(new_pos, animation=true):
	if not animation:
		pos = new_pos
		self.transform.origin = new_pos
		self.reset_animation()
	else:
		self.pos = new_pos

signal card_created(path)
signal pickup_request(path, event)
signal put_down_request(path, event)
signal highlighted(path)
signal not_highlighted(path)

func _enter_tree():
	manager = self.get_tree().get_root().get_node("Manager")
	
	self.connect("card_created", manager, "_on_card_created")
	emit_signal("card_created", self.get_path())
	
	self.connect("pickup_request", manager, "_on_pickup_request")
	self.connect("put_down_request", manager, "_on_put_down_request")
#	self.connect("highlighted", manager, "_on_card_highlighted")
#	self.connect("not_highlighted", manager, "_on_card_not_highlighted")

func _ready():
	size_changed()
	self.set_required_animation_offset(Vector2(0, 0))
	
#	self.connect("mouse_entered", self, "_on_mouse_entered")
#	self.connect("mouse_exited", self, "_on_mouse_exited")

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == 1 and enabled_pickup:
		if mouse_inside:
			self.highlight_control()
			self.picked_up = !self.picked_up  # in this line works like a mousebuttonpressed variable
			if manager != null and picked_up:
				emit_signal("pickup_request", self.get_path(), event) 
				print(self.picked_up)
				if picked_up:
					self.set_required_angle_offset(0)
			elif manager != null and not picked_up:
				print(self.picked_up)
				emit_signal("put_down_request", self.get_path(), event)
			else:
				self.picked_up = !self.picked_up
		else:
			picked_up = false
	elif picked_up and event is InputEventMouseMotion:
		self.move_card(event)
	elif event is InputEventMouseMotion:
		#print(self.z_index)
		if self.point_belongs_to_card(event.position):
			if not mouse_inside:
				self._on_mouse_entered()
		elif mouse_inside:
			self._on_mouse_exited()

func point_belongs_to_card(point : Vector2):
	var size = self.get_size()
	if point[0] > self.transform.origin.x + size[0] / 2 or point[0] < self.transform.origin.x - size[0] / 2:
		return false
	if point[1] > self.transform.origin.y + size[1] / 2 or point[1] < self.transform.origin.y - size[1] / 2:
		return false
	return true

func move_card(mouse_motion : InputEventMouseMotion):
	var screen_size = self.get_viewport().size
	var x = clamp(self.pos.x + mouse_motion.relative.x,
			self.get_size()[0] / 2, screen_size.x - self.get_size()[0] / 2)
	var y = clamp(self.pos.y + mouse_motion.relative.y,
			self.get_size()[1] / 2, screen_size.y - self.get_size()[1] / 2)
	self.set_pos(Vector2(x, y), false)

func get_size():
	return Vector2($BackSprite.texture.get_width() * $BackSprite.get_scale()[0],
			 $BackSprite.texture.get_height() * $BackSprite.get_scale()[1])

func flip_card():
	$BackSprite.set_visible(!$BackSprite.is_visible())
	$FrontSprite.set_visible(!$FrontSprite.is_visible())

func _on_mouse_entered():
	if self.enabled_highlight:
		mouse_inside = true
		self.highlight_control()
	
func _on_mouse_exited():
	if self.enabled_highlight:
		mouse_inside = false
		self.highlight_control()

func highlight_control():
	self.highlighted = true if self.mouse_inside else false
	if highlighted:
		if self.enabled_highlight_animation:
			var vertical_animation_offset = Vector2(0, -self.get_size()[1] / 2)
			self.highlight_required_offset = vertical_animation_offset.rotated(self.transform.get_rotation())
		$BordersSprite.show()
		emit_signal("highlighted", self.get_path())
	else:
		if self.enabled_highlight_animation:
			self.highlight_required_offset = Vector2(0, 0)
		$BordersSprite.hide()
		emit_signal("not_highlighted", self.get_path())

func _process(delta):
	# linear animation
	self.transform.origin = self.animation_start_point - self.animation_offset
	self.curr_animation_time = clamp(self.curr_animation_time + delta, 0, self.animation_time)
	self.animation_offset = self.curr_animation_time * self.animation_speed + \
			pow(self.curr_animation_time, 2) * self.animation_acceleration / 2
	self.transform.origin = self.animation_start_point + self.animation_offset
	
	# angle animation
	if self.required_angle_offset == self.angle_offset:
		return
	self.curr_angle_animation_time = clamp(self.curr_angle_animation_time + delta, 0, self.angle_animation_time)
	self.angle_offset = self.start_angle + self.curr_angle_animation_time * self.angle_speed + \
			pow(self.curr_angle_animation_time, 2) * self.angle_acceleration / 2
	self.transform.x = Vector2(1, 0).rotated(self.angle_offset)
	self.transform.y = Vector2(0, 1).rotated(self.angle_offset)


# wip
func size_changed():
	var collision_shape = RectangleShape2D.new()
	var texture_size = self.get_size()
	collision_shape.extents = texture_size / 2
	$CollisionShape2D.shape = collision_shape