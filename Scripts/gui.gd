extends Control

@export var resources : Label
@export var flavourtext : Label
@export var generate_timer : Timer
@export var cutscene_timer : Timer
@export var sacrifice_button : Button
@export var host_battle_button : Button
@export var restart_button : Button

@onready var particles = get_parent().get_node("Particles")

#resources
var battle_pressed : bool = false
var boons : float = 0.00
const boons_per_tick : int = 9
var boon_mult : int = 1
var n00bs : int = 7999999999
var n00b_cost : float = 10.0
const n00b_cost_base : float = 10.0
const n00b_cost_mult : float = 1.618
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

#todo maybe add boon breakpoints for later texts - nah
const flavourtext_text = [
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
const ticks : float = 0.01
var tick_speed : float = 0.0
const flavour_timer : int = 10
var speed_mult : float = 1.0


#Function Section

func _ready():
	update_label_text()
	generate_timer.start(ticks)
	print(particles)
	particles.get_node("Ascend").hide()
	particles.get_node("Descend").hide()

#Buttons

#Solo Battle-Button
func _on_battle_button_down() -> void:
	battle_pressed = true
func _on_battle_button_up() -> void:
	battle_pressed = false

#Buy n00b-Button
func _on_n00b_pressed() -> void:
	make_n00bs()
	if (n00bs + boon_mult) >= 8000000000:
		finishable = true
	update_label_text()

#todo add buy n00bs for boons text


#sacrifice n00b-Button
func _on_sacrifice_n00bs_button_up():
	sacrifice_n00bs()
	update_label_text()
	sacrifice_button.remove_theme_font_size_override("font_size")
	sacrifice_button.text = "sacrifice %s n00bs" %(boon_mult*2)
#text
func _on_sacrifice_n_00_bs_mouse_entered():
	if !sacrificed and n00bs >= 2:
		sacrifice_button.add_theme_color_override("font_hover_color", Color.RED)
		sacrifice_button.add_theme_font_size_override("font_size", 24)
		sacrifice_button.text = "Are You Sure?"
		
func _on_sacrifice_n_00_bs_mouse_exited():
	sacrifice_button.remove_theme_font_size_override("font_size")
	sacrifice_button.text = "sacrifice %s n00bs" %(boon_mult*2)
#end sacrifice n00b_button

#host bat0l
func _on_host_battle_pressed():
	host_xhb()

func _on_restart_pressed():
	restart_game()


#Buttons End

#General Text
func update_label_text() -> void:
	if !n00bs:
		resources.text = "%.2f boons" %boons
	else:
		resources.text = "%.2f boons & " %boons + "%s n00bs " %n00bs


func update_flavourtext_text() -> void:
	if sacrificed:
		flavourtext.text = flavourtext_text[randf_range(-8, -1)]
	else:
		flavourtext.text = flavourtext_text[randf_range(progression, 5 + progression)]


#timers


func _on_timer_timeout() -> void:
	win_game()
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


#this fucking destroys my pc at multiple millions - "fixed"
func make_n00bs() -> void:
	while boons >= boon_mult * n00b_cost:
		#this method is quite inaccurate, but it works lol
		n00bs += boon_mult
		boons -= boon_mult * n00b_cost
		n00b_cost = ceil(calculate_n00b_cost())


func sacrifice_n00bs() -> void:
	if n00bs >= sacrifice_cost:
		n00bs -= sacrifice_cost
		sacrifice_cost *= 2
		boon_mult *= 2
		n00b_cost = ceil(calculate_n00b_cost()) #oh well
		if !sacrificed:
			host_battle_button.hide()
			sacrifice_button.add_theme_color_override("font_color", Color.RED)
			update_flavourtext_text()
			sacrificed = true


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

#todo
func win_game() -> void:
	if finishable and !sacrificed:
		#good end
		hide_all()
		particles.get_node("Ascend").show()
		$TrueEnd.play()
		restart_fadein()
		
		finishable = false
		
	elif finishable and sacrificed:
		#bad end
		hide_all()
		particles.get_node("Descend").show()
		$End.play()
		restart_fadein()
		
		finishable = false

func restart_fadein() -> void:
	restart_button.modulate.a = 0.0
	restart_button.show()
	var tween : Tween = create_tween()
	tween.tween_interval(13.0)
	tween.tween_property(restart_button, "modulate:a", 1.0, 5.0)
	
	

#hides all hideable children
func hide_all() -> void:
	for node in $".".get_children():
		if node is CanvasItem:
			node.hide()
#shows all hideable children
func show_all() -> void:
	for node in $".".get_children():
		if node is CanvasItem:
			node.show()


func restart_game() -> void: #resets all relevant variables
	boons = 0.00
	boon_mult = 1
	n00bs = 0
	n00b_cost = 10.0
	entries = 0
	sacrifice_cost = 2
	sacrificed = false
	progression = 0
	finishable = false
	tick_speed = 0.0
	speed_mult = 1.0
	
	$End.stop()
	$TrueEnd.stop()
	
	particles.get_node("Descend").hide()
	particles.get_node("Ascend").hide()
	
	show_all()
	restart_button.hide()
