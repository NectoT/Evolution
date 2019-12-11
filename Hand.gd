extends Container

var Card = preload("res://Cards/Scripts/Card.gd")
var SharpVision = preload("res://Cards/SharpVision.tscn")

var cards_arr = []
var hand_radius

export var highlight_animation_time : float = 2

func _notification(what):
    if (what==NOTIFICATION_SORT_CHILDREN):
        # Must re-sort the children
        for c in get_children():
            if c is Control:
            	fit_child_in_rect( c, Rect2( Vector2(), self.get_size() ) )

func _ready():
	var card = SharpVision.instance()
	#card.flip_card()

	self.set_mouse_filter(MOUSE_FILTER_IGNORE)  # important stuff, lets cards in the deck get mouse events
	
	for i in range(60):
		self.receive_card(SharpVision.instance())
	
	self.set_view()

func receive_card(card):
	if len(cards_arr) == 0: 
		self.hand_radius = sqrt(pow(self.rect_size[0], 2) + pow(self.rect_size[1], 2)) / 2
		print(self.hand_radius)
	
	self.add_child(card)
	cards_arr.append(card)
	
	card.z_index += len(cards_arr)  # temp
	card.enabled_highlight_animation = true
	
	self.set_view()

func remove_card(card):
	if self.cards_arr.find(card) == -1:
		print("There is no such card in hand")
		return
	self.cards_arr.erase(card)
	
	card.z_index = 1  # temp
	card.enabled_highlight_animation = false
	
	self.set_view()

func set_view():
	if len(cards_arr) == 0:
		return
	
	var maximum_tilt = 20
	var angle_between_cards = 6
	var current_angle
	if len(cards_arr) / 2 * angle_between_cards > maximum_tilt:
		angle_between_cards = maximum_tilt / (len(cards_arr) / 2)
	
	var current_card = cards_arr[0]
	var card_top_right
	var card_top_left
	
	# code for the middle card
	if len(cards_arr) % 2 == 1:
		var current_card_position = self.rect_size / 2
		current_card = cards_arr[len(cards_arr) / 2]
		current_card.transform[0] = Vector2(1, 0)
		current_card.transform[1] = Vector2(0, 1)
		current_card.pos = current_card_position
		current_card.set_required_angle_offset(0)
	
	# code for cards that are in the left half
	card_top_left = (self.rect_size - current_card.get_size()) / 2
	if len(cards_arr) % 2 == 0:
		card_top_left[0] += current_card.get_size()[0] / 2
	current_angle = -angle_between_cards
	for i in range(len(cards_arr) / 2 - 1, -1, -1):
		current_card = cards_arr[i]
		
		#print(current_card.id, " ", current_angle)
		current_card.set_required_angle_offset(deg2rad(current_angle))
		#current_card.transform = current_card.transform.rotated(deg2rad(-current_angle))
		
		card_top_right = current_card.pos + Vector2(current_card.get_size()[0] / 2,
				 current_card.get_size()[1] / -2).rotated(current_card.transform.get_rotation())
		var difference = card_top_left - card_top_right
		current_card.pos += difference
		current_card.pos += Vector2(5, 5)  # to make hand look less like a fan and more like a hand
		
		card_top_left = current_card.pos + current_card.get_size().rotated(current_card.transform.get_rotation()) / -2
		
		current_angle -= angle_between_cards
	
	# code for cards that are in the right half
	card_top_right = Vector2(self.rect_size[0] + current_card.get_size()[0],
			self.rect_size[1] - current_card.get_size()[1]) / 2
	if len(cards_arr) % 2 == 0:
		card_top_right[0] -= current_card.get_size()[0] / 2
	current_angle = angle_between_cards
	for i in range(len(cards_arr) / 2 + len(cards_arr) % 2, len(cards_arr)):
		current_card = cards_arr[i]
		
		current_card.set_required_angle_offset(deg2rad(current_angle))
		#current_card.transform = current_card.transform.rotated(deg2rad(current_angle))
		
		card_top_left = current_card.pos + current_card.get_size().rotated(current_card.transform.get_rotation()) / -2
		var difference = card_top_right - card_top_left
		current_card.pos += difference
		current_card.pos += Vector2(-5, 5)  # to make hand look less like a fan and more like a hand
		card_top_right = current_card.pos + Vector2(current_card.get_size()[0] / 2,
				 current_card.get_size()[1] / -2).rotated(current_card.transform.get_rotation())
		
		current_angle += angle_between_cards

#func _input(event):
#	print(3, "\n")

#func _gui_input(event):
#	pass