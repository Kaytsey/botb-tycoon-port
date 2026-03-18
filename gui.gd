extends Control

@export var debug : Label


@export var resources : Label
@export var current_mult : Label
@export var flavourtext : Label
@export var generate_timer : Timer
@export var cutscene_timer : Timer

#resources
var battle_pressed : bool = false
var boons : float = 0.00
var boons_per_tick : int = 9
var boon_mult : int = 1
var n00bs : int = 0
var n00b_cost : float = 10.0
const n00b_cost_base : float = 10.0
var n00b_cost_mult : float = 1.618
var n00bs_purchasable : int = 0
var entries : int = 0
var sacrifice_cost : int = 2

#maybe use enum instead, maybe it doesn't matter lol
const XHB_cost = {
	"OHB": 725,
	"2HB": 2000,
	"4HB": 5656,
	"MAJOR": 56560,
}

#progression, ending
var sacrificed : bool = false #ending related
var progression : int = 0
var finishable : bool = false
#todo add boon breakpoints for later texts
var flavourtext_text = [
	"welcome, n00b",
	"boonless chicken",
	"batol",
	"batol is good",
	"We must gather more boons",
	"boonsave!",
	"number go up",
	"more boons?",
	"more boons.",
	"MORE BOONS",
	"Your n00bs love you",
	"Host a battle!",
	"!xhb",
	"we need more",
	"go on",
	"keep going",
	"The slugs love you too!",
	"yes",
	"almost",
	
	#sacrifice state
	"Why",
	"Whatever",
	"Your fate is sealed",
	"You will go to Hell, you know?",
	"Why did you do it?",
	"Despicable",
	"You fucked up",
	"Hell is a real place",]

#timestuff
var timer_iterations : int
var ticks : float = 0.01
var tick_speed : float = 0.0
var flavour_timer : int = 10
var speed_mult : float = 1.0





#Function Section

func _ready():
	update_label_text()
	generate_timer.start(ticks)

#TESTING
func _on_win_button_down():
	#win_game()
		hide()
		#play_cutscene() #spawn particle system
		$TrueEnd.play()
		show()
		#$TrueEnd.stop()

func _on_lose_button_down():
	#win_game()
		hide()
		$End.play()
		show()


#Battle-Button
func _on_battle_button_down() -> void:
	battle_pressed = true
func _on_battle_button_up() -> void:
	battle_pressed = false

#Buy n00b-Button
func _on_n00b_pressed() -> void:
	make_n00bs()
	update_label_text()

#sacrifice n00b-Button
func _on_sacrifice_n00bs_button_up():
	sacrifice_n00bs()
	update_label_text()

#host bat0l
func _on_host_battle_pressed():
	host_xhb()


#General Text
func update_label_text() -> void:
	if !n00bs:
		resources.text = "%.2f boons" %boons
	else:
		#resources.text = "%s boons & " %boons + "%s n00bs" %n00bs
		resources.text = "%.2f boons & " %boons + "%s n00bs" %n00bs
	current_mult.text = "Current Multiplier: %s" %boon_mult
	
	#debug
	debug.text = "n00b_cost: %s\n" %n00b_cost + "you can buy %s n00bs" %n00bs_purchasable


func update_flavourtext_text() -> void:
	if sacrificed:
		flavourtext.text = flavourtext_text[randf_range(-8, -1)]
	else:
		flavourtext.text = flavourtext_text[randf_range(progression, 5 + progression)]


#time
func _on_timer_timeout() -> void:
	
	#testing
	calculate_purchasable_n00bs()
	
	if battle_pressed: make_boons()
	generate_boons()
	timer_iterations += 1
	if timer_iterations >= (flavour_timer/ticks):
		update_flavourtext_text()
		timer_iterations = 0
	generate_timer.start(ticks)


#resources
func make_boons() -> void:
	boons += ticks * boon_mult * 5
	update_label_text()

func generate_boons() -> void:
	boons += ticks * boons_per_tick * n00bs * boon_mult
	update_label_text()


#todo this fucking destroys my pc at multiple millions
func make_n00bs() -> void:
	while boons >= n00b_cost:
		n00bs += 1
		boons -= n00b_cost
		n00b_cost = ceil(calculate_n00b_cost())
		#TODO convert to 1k, 1m, 1b


#testing
func calculate_purchasable_n00bs() -> int:
	n00bs_purchasable = floor(((boons / n00b_cost_base) / n00b_cost_mult) - n00bs)
	return n00bs_purchasable



func sacrifice_n00bs() -> void:
	if n00bs >= sacrifice_cost:
		n00bs -= sacrifice_cost
		sacrifice_cost *= 2
		boon_mult *= 2
		n00b_cost = ceil(calculate_n00b_cost()) #oh well
		sacrificed = true
		update_flavourtext_text()


func calculate_n00b_cost() -> float:
	if sacrificed:
		return n00b_cost_base * (n00b_cost_mult * n00bs)
	else:
		return n00b_cost_base * pow(n00b_cost_mult, n00bs)

#todo
#i will not write an audio engine for this, sorry
func play_sfx() -> void:
	
	pass


#todo
#maybe have an actual return value
#maybe make node outside of this
func play_cutscene() -> void:
	pass


#todo
func host_xhb() -> void:
	if boons >= XHB_cost["OHB"] and boons < XHB_cost["2HB"]:
		hide()
		play_cutscene()
		show()
		pass
	if boons >= XHB_cost["2HB"] and boons < XHB_cost["4HB"]:
		hide()
		play_cutscene()
		show()
		pass
	if boons >= XHB_cost["4HB"] and boons < XHB_cost["MAJOR"]:
		hide()
		play_cutscene()
		show()
		pass
	
	#MAJOR can have more entries than n00bs
	if boons >= XHB_cost["MAJOR"]:
		hide()
		play_cutscene()
		show()
		pass
	#pass



#todo
func win_game() -> void:
	if finishable and !sacrificed:
		#good end
		hide()
		play_cutscene() #spawn particle system
		show()
		pass
		
	elif finishable and sacrificed:
		#bad end
		hide()
		play_cutscene() #spawn particle system
		show()
		pass
	pass
