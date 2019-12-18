extends Container

var Card = preload("res://Cards/Card.tscn")
var SharpVision = preload("res://Cards/SharpVision.tscn")

var cards_arr = []
var fake_card = Card.instance()
var potential_card = null

export var maximum_tilt : int = 15
export var default_angle_between_cards : int = 6

export var highlight_animation_time : float = 2

func _notification(what):
    if (what==NOTIFICATION_SORT_CHILDREN):
        # Must re-sort the children
        for c in get_children():
            if c is Control:
            	fit_child_in_rect( c, Rect2( Vector2(), self.get_size() ) )

func _ready():
	self.fake_card.visible = false  # so that you couldn't see it and interact with it
	self.add_child(self.fake_card)
	
	var card = SharpVision.instance()
	#card.flip_card()

	self.set_mouse_filter(MOUSE_FILTER_IGNORE)  # important stuff, lets cards in the deck get mouse events
	
	for i in range(5):
		self.receive_card(SharpVision.instance(), true)
	
	self.set_view()

func receive_card(card, append=false):
	self.remove_fake_card()
	self.potential_card = null
	
	self.add_child(card)
	
	if append:
		cards_arr.append(card)
		card.z_index += len(cards_arr) - 1  # temp
	else:
		for i in range(len(cards_arr)):
			var hand_card = cards_arr[i]
			if card.pos.x < hand_card.pos.x:
				cards_arr.insert(i, card)
				card.z_index += i
				break
		if !(card in cards_arr):
			cards_arr.append(card)
			card.z_index += len(cards_arr) - 1  # temp
	
	card.enabled_highlight_animation = true
	
	self.set_view()

# same thing as receive_card except instead of the card it inserts invisible card
func receive_fake_card(index):  # used for showing where the potential card will be placed
	self.remove_fake_card()
	cards_arr.insert(index, self.fake_card)
	self.set_view()

func remove_card(card):
	if self.cards_arr.find(card) == -1:
		print("There is no such card in hand")
		return
	self.cards_arr.erase(card)
	
	card.z_index = 1  # temp
	card.enabled_highlight_animation = false
	
	self.remove_child(card)
	
	self.set_view()

func remove_fake_card():
	self.cards_arr.erase(self.fake_card)

func add_potential_card(card):
	self.potential_card = card

func remove_potential_card():
	self.potential_card = null

func set_view():
	if len(cards_arr) == 0:
		return
	
	var current_angle
	var angle_between_cards
	if len(cards_arr) / 2 * self.default_angle_between_cards > maximum_tilt:
		angle_between_cards = self.maximum_tilt / (len(cards_arr) / 2)
	else:
		angle_between_cards = self.default_angle_between_cards
	
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
		
		current_card.set_required_angle_offset(deg2rad(current_angle))
		
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
		
		card_top_left = current_card.pos + current_card.get_size().rotated(current_card.transform.get_rotation()) / -2
		var difference = card_top_right - card_top_left
		
		current_card.pos += difference
		current_card.pos += Vector2(-5, 5)  # to make hand look less like a fan and more like a hand
		
		card_top_right = current_card.pos + Vector2(current_card.get_size()[0] / 2,
				 current_card.get_size()[1] / -2).rotated(current_card.transform.get_rotation())
		
		current_angle += angle_between_cards

func _process(delta):
	if self.potential_card != null:
		# worls only if card has normal proportions, where width is less than height
		var min_card_width = self.fake_card.get_size()[0]
		var max_card_width = self.fake_card.get_size()[1]
		
		var index_error = ceil(float(max_card_width) / min_card_width)
		
		var difference_between_potential_and_middle_cards =  self.potential_card.pos[0] - self.rect_size[0] / 2
		var index_distance = ceil(difference_between_potential_and_middle_cards / min_card_width)
		
		var start
		var end
		var step
		if index_distance > 0:
			start = clamp(len(self.cards_arr) / 2 + index_distance, -len(self.cards_arr) + 1, len(self.cards_arr) - 1)
			end = start - index_error
			step = -1
		else:
			start = clamp(len(self.cards_arr) / 2 + index_distance, -len(self.cards_arr) + 1, len(self.cards_arr) - 1)
			end = start + index_error
			step = 1
		for i in range(start, end, step):
			var hand_card = self.cards_arr[i]
			if self.potential_card.pos.x < hand_card.pos.x:
				if cards_arr.find(self.fake_card) != i:
					self.receive_fake_card(i)
				break
	