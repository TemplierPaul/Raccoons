extends Control

var left_team
var right_team 
var cards = []
var selected_card=null

var queue
var turn_char

var keep_going = true

# Called when the node enters the scene tree for the first time.
func _ready():
	left_team = add_team('robots', true)
	right_team = add_team('porcupines', false)
	left_team.set_enemy(right_team)
	right_team.set_enemy(left_team)
	
	queue = $Queue
	queue.init(left_team.characters, right_team.characters)
	print(queue.index)
	next_turn(true)

func add_team(type='robots', left_side=true, player_side=null):
	if player_side == null:
		player_side = left_side
	var team = load("res://Formation/formation.tscn").instance()
	team.populate(type)
	add_child(team)
	team.set('margin_top', 168)
	team.set_arrow(left_side)
	
	# Position
	if left_side:
		team.set('margin_left', 136)
	else:
		team.set('margin_left', 1256)
	
	# Win condition
	if player_side:
		team.connect('all_dead', self, "end_game", ['lose'])
	else:
		team.connect('all_dead', self, "end_game", ['win'])
	return team

func add_cards(_cards):
	for c in _cards:
		var new_node = c.frame
		new_node.update()
		new_node.connect('clicked', self, "card_click", [new_node])
		new_node.connect('focused', $"Central display", "show_node", [new_node, true])
		new_node.connect('unfocused', $"Central display", "show_node", [new_node, false])
		get_node("Cards").add_child(new_node)
		

func cast_card(card, source, target, show_time=0):
	print('Casting card ', card.name, " from ", source.name, ' on ', target.name)
	if card.cost <= turn_char.mana:
		turn_char.mana = turn_char.mana - card.cost
		turn_char.frame.update()
		
		if show_time >0:
			card.frame.emit_signal('focused')
			target.frame.show_arrow(true)
			yield(get_tree().create_timer(show_time), "timeout")
			target.frame.show_arrow(false)
			card.frame.emit_signal('unfocused')
		
		card.effect(source, target)
		if card.frame != null:
			card.frame.free()
		update_lists()
	selected_card = null
	print("Casting completed")
	
func update_lists():
	cards=[]
	for c in $Cards.get_children():
		cards.append(c.card)
	

func end_game(result):
	keep_going = false
	var res
	if result == "win":
		res = load("res://End/Win.tscn").instance()
	else:
		res = load("res://End/Lose.tscn").instance()
	add_child(res)
	$"Close game".raise()
	queue.end_game()

# Interactions

func card_click(card_frame):
		#print(card_frame.card.name, selected_card)
		if selected_card != null:
			selected_card.unselect()
		if selected_card != card_frame and card_frame.card.cost <= turn_char.mana:
			selected_card = card_frame
			selected_card.select()
		else:
			selected_card = null
	
func _close():
	get_tree().quit()

func next_turn(prev_freed=false):
	if left_team.are_all_dead() or right_team.are_all_dead():
		return 0
	if !prev_freed:
		turn_char.end_turn()
	print("\n> New Turn")
	for c in $Cards.get_children():
		c.free()
	turn_char = queue.get_next()
	print(turn_char.name, " AI: ", turn_char.AI)
	
	if turn_char.AI ==null:
		$Cards.visible = true
		$"End turn".visible = true
	else:
		$Cards.visible = false
		$"End turn".visible = false
		turn_char.AI.connect('next_turn', self, "next_turn")
	add_cards(turn_char.get_cards())
	yield(turn_char.start_turn(self), "completed")

	
