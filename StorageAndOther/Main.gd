extends Node

var SharpVision = preload("res://Cards/SharpVision.tscn")

signal card_highlight_off
signal card_highlight_on

func _ready():
	pass # Replace with function body.

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
	#self.remove_child(card)
	
	# handler for card in the Hand
	if card.get_parent() == $Container:
		# checking if this card isn't obstructed by other cards
		var overlapping_cards = card.get_overlapping_areas()
		for overlapping_card in overlapping_cards:
			if point_belongs_to_card(overlapping_card, overlapping_card.to_local(event.global_position)):
				if overlapping_card.z_index > card.z_index:
					card.picked_up = false
					return
		
		# removing card from the hand
		$Container.remove_card(card)
		
		# setting the card straight i.e. returning it's basis to a normal one
		card.transform.x = Vector2(1, 0)
		card.transform.y = Vector2(0, 1)
	
	# disabling highlight while a card is picked
	for hand_card in $Container.cards_arr:
		hand_card.enabled_highlight = false

func _on_put_down_request(path, event):
	
	# enabling highlight when the card is put down
	for hand_card in $Container.cards_arr:
			hand_card.enabled_highlight = true