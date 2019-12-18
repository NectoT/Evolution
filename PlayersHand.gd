extends "res://Hand/Scripts/Hand.gd"

var fake_card = Card.instance()
var potential_card = null

func _ready():
	self.fake_card.visible = false  # so that you couldn't see it and interact with it
	self.add_child(self.fake_card)
	#._ready()  # apparently it's already called, and it's really weird if you ask me

func receive_card(card, append=false):
	self.remove_fake_card()
	self.potential_card = null
	.receive_card(card, append)

# same thing as receive_card except instead of the card it inserts invisible card
func receive_fake_card(index):  # used for showing where the potential card will be placed
	self.remove_fake_card()
	cards_arr.insert(index, self.fake_card)
	self.set_view()

func remove_fake_card():
	self.cards_arr.erase(self.fake_card)

func add_potential_card(card):
	self.potential_card = card

func remove_potential_card():
	self.potential_card = null

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