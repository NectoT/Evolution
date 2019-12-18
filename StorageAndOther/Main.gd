extends Node

var SharpVision = preload("res://Cards/SharpVision.tscn")

var timer = Timer.new()

var floating_cards_arr = []
var picked_card = null

signal card_highlight_off
signal card_highlight_on

func _ready():
	self.add_child(self.timer)
	self.timer.one_shot = true

# temp
func _input(event):
	if event is InputEventKey and event.get_scancode() == KEY_N and not event.is_echo() and event.is_pressed():
		$Container.receive_card(SharpVision.instance())

func _on_card_created(path):
	var card = self.get_node(path)
	$IDHolder.total_cards_number += 1
	card.id = $IDHolder.total_cards_number

func point_belongs_to_card(card, point : Vector2):
	var size = card.get_size()
	if point[0] > size[0] / 2 or point[0] < -size[0] / 2:
		return false
	if  point[1] > size[1] / 2 or point[1] < -size[1] / 2:
		return false
	return true

func _on_card_highlighted(path):  
	var highlighted_card = self.get_node(path)

	# disabling higlight for all the other cards in hand while the highlighted_card is highlighted
	for card in $Container.cards_arr:
		if card != highlighted_card:
			card.enabled_highlight = false

func _on_card_not_highlighted(path):
	var highlighted_card = self.get_node(path)

	# enabling higlight for all the other cards in hand when the highlighted_card is not highlighted anymore
	for card in $Container.cards_arr: 
		if card != highlighted_card:
			card.enabled_highlight = true

func _on_pickup_request(path, event):
	var card = self.get_node(path)
	
	# handler for card in the Hand
	if card.get_parent() == $Container:
		# checking if this card isn't obstructed by other cards
		var overlapping_cards = card.get_overlapping_areas()
		for overlapping_card in overlapping_cards:
			if point_belongs_to_card(overlapping_card, overlapping_card.to_local(event.global_position)):
				if overlapping_card.z_index > card.z_index:
					card.picked_up = false
					return
		# if it's not than it can be picked up
		card.picked_up = true
		# we need to track down which card is picked up
		self.picked_card = self.get_node(path)
		
		# removing card from the hand
		$Container.remove_card(card)
		
		# setting the card straight i.e. returning it's basis to a normal one
		card.set_required_angle_offset(0)
		
		# the card is temporarily stored in main, until it gets put down
		self.add_child(card)
		self.floating_cards_arr.append(card)  # temp i suppose
		
		return
	
	# temp default handler
	self.picked_card = self.get_node(path)
	
	
	# disabling highlight while a card is picked
	for hand_card in $Container.cards_arr:
		hand_card.enabled_highlight = false

func _on_put_down_request(path, event):
	self.picked_card = null
	var card = self.get_node(path)
	
	# checking if the card is in the hand container bounds and putting it there in case it is
	var container_pos = $Container.rect_global_position
	if card.pos.x > container_pos[0] and card.pos.x < container_pos[0] + $Container.rect_size[0] \
			and card.pos.y > container_pos[1] and card.pos.y < container_pos[1] + $Container.rect_size[1]:
		self.remove_child(card)
		$Container.receive_card(card)
	
	
	# enabling highlight when the card is put down
	for hand_card in $Container.cards_arr:
			hand_card.enabled_highlight = true

func inform_hand_about_potential_card():
	if self.picked_card == null:  # the card might have been already placed
		return
	
	print("inform")
	var container_pos = $Container.rect_global_position
	if self.picked_card.pos.x > container_pos[0] and self.picked_card.pos.x < container_pos[0] + $Container.rect_size[0] \
			and self.picked_card.pos.y > container_pos[1] and self.picked_card.pos.y < container_pos[1] + $Container.rect_size[1]:
		$Container.add_potential_card(self.picked_card)
	
	self.timer.paused = true  # pausing the timer so that there wouldn't be excessive calls to the player's hand

func _process(delta):
	var container_pos = $Container.rect_global_position
	if self.picked_card != null:
		# checking if the card is in the hand container bounds and starting timer, after which picked card will be viewed as
		# potential card for hand
		if picked_card.pos.x > container_pos[0] and picked_card.pos.x < container_pos[0] + $Container.rect_size[0] \
				and picked_card.pos.y > container_pos[1] and picked_card.pos.y < container_pos[1] + $Container.rect_size[1]:
			if timer.is_stopped():
				timer.wait_time = 1
				timer.start()
				timer.connect("timeout", self, "inform_hand_about_potential_card")
	elif self.timer.paused:
		self.timer.paused = false
		self.timer.stop()
		self.timer.disconnect("timeout", self, "inform_hand_about_potential_card")
		$Container.remove_potential_card()