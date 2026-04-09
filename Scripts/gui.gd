extends Control

#it might have been easier to spread the code to multiple nodes and/or to use a single scene, but of well

@export var resources : Label
@export var flavourtext : Label
@export var ending_text : Label
@export var generate_timer : Timer
@export var cutscene_timer : Timer
@export var sacrifice_button : Button
@export var host_battle_button : Button
@export var restart_button : Button
@export var buy_n00bs : Button

@export var test_cutscene : Button

const slug_scene = preload("res://Scenes/Slugs.tscn")

@onready var particles = get_parent().get_node("Particles")
@onready var slugs = get_parent().get_node("Slugs")

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
var total_entries : int = 0
var sacrifice_cost : int = 2

const cutscene_area_center : Vector3 = Vector3(0, 0, 0)

#maybe use enum instead, maybe it doesn't matter lol
const XHB_cost = {
	"OHB": 725,
	"2HB": 2000,
	"4HB": 5656,
	"MAJOR": 56560,
	"DD2": 5656560, #make number bigger, it's 10 years, man
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
var tick_speed : float = 1.0
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
	update_label_text()


#sacrifice n00b-Button
func _on_sacrifice_n00bs_button_up():
	sacrifice_n00bs()
	update_label_text()
	sacrifice_button.remove_theme_font_size_override("font_size")
	sacrifice_button.text = "sacrifice %s n00bs" %(boon_mult*2)
	if boon_mult >= 8000000000:
		finishable = true
		
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

func _on_test_cutscene_pressed():
	play_cutscene()
	cutscene_timer.start()

#Buttons End

#General Text
func update_label_text() -> void:
	#OHB hosting
	#this is messy lol
	if boons <= XHB_cost["OHB"]:
		host_battle_button.text = "Hosting OHB costs %s" %XHB_cost["OHB"] + " boons"
	if boons >= XHB_cost["OHB"] and boons < XHB_cost["2HB"]:
		host_battle_button.text = "Host OHB for %s" %XHB_cost["OHB"] + " boons"
	if boons >= XHB_cost["2HB"] and boons < XHB_cost["4HB"]:
		host_battle_button.text = "Host 2HB for %s" %XHB_cost["2HB"] + " boons"
	if boons >= XHB_cost["4HB"] and boons < XHB_cost["MAJOR"]:
		host_battle_button.text = "Host 4HB for %s" %XHB_cost["4HB"] + " boons"
	if boons >= XHB_cost["MAJOR"] and boons < XHB_cost["DD2"]:
		host_battle_button.text = "Host MAJOR for %s" %XHB_cost["MAJOR"] + " boons"
	if boons >= XHB_cost["DD2"]:
		host_battle_button.text = "Host DD2 for %s" %XHB_cost["DD2"] + " boons"
	
	#General boons
	if !n00bs:
		resources.text = "%.2f boons" %boons
	if n00bs:
		resources.text = "%.2f boons & " %boons + "%s n00bs " %n00bs
	buy_n00bs.text = "buy n00b for %s boons" %n00b_cost
	


func update_flavourtext_text() -> void:
	if sacrificed:
		flavourtext.text = flavourtext_text[randi_range(-8, -1)]
	else:
		flavourtext.text = flavourtext_text[randi_range(progression, 5 + progression)]

func show_ending_text() -> void:
	#make text appear gradual
	ending_text.visible_ratio = 0
	if sacrificed:
		ending_text.text = "Your greed doomed all of humanity.
			Everyone has been sacrificed and nobody remains to listen.
			You made Hell a real place."
	
	else:
		ending_text.text = "You succeeded in building a comfy community!
			Everyone rejoices in harmony!
			Praise be upon you!"
	ending_text.show()
	
	#make text appear gradual
	var tween : Tween = create_tween()
	tween.tween_property(ending_text, "visible_ratio", 1, 5)
	


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

func _on_cutscene_timer_timeout():
	if boons >= XHB_cost["DD2"]:
		finishable = true
		for slug in get_tree().get_nodes_in_group("slugs"):
			slug.queue_free()
		return
		
	show_all()
	restart_button.hide()
	ending_text.hide()
	#remove slugs
	for slug in get_tree().get_nodes_in_group("slugs"):
		slug.queue_free()

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

#TODO
#i will not write an audio engine for this, sorry
func play_sfx() -> void:
	
	pass

#todo
func play_cutscene() -> void:
	tally_points()
	#after x seconds go back
	var slug_amount = randi_range(1, min(n00bs, 560))
	for i in slug_amount:
		var slug = slug_scene.instantiate()
		slug.add_to_group("slugs")
		get_tree().current_scene.add_child(slug)
		slug.global_position = cutscene_area_center + Vector3(
			randf_range(-4.0, 4.0),
			randf_range(-3.0, 3.0),
			randf_range(-10.0, 10.0))
		slug.rotation.y = randf_range(0, 360)
		
		var animations: AnimationPlayer = slug.get_node("AnimationPlayer")
		var animation = animations.get_animation_list()
		animations.play(animation[randi() % animation.size()])
		#random animation speed TODO add general speedup at breakpoints
		animations.set_speed_scale(randf_range(0.5 * tick_speed, 2 * tick_speed))
		

func tally_points() -> void:
	#
	
	pass


#todo
func host_xhb() -> void:
	if boons >= XHB_cost["OHB"] and boons < XHB_cost["2HB"]:
		hide_all()
		cutscene_timer.wait_time = 5
		cutscene_timer.start()
		play_cutscene()

	if boons >= XHB_cost["2HB"] and boons < XHB_cost["4HB"]:
		hide_all()
		cutscene_timer.wait_time = 10
		cutscene_timer.start()
		play_cutscene()

	if boons >= XHB_cost["4HB"] and boons < XHB_cost["MAJOR"]:
		hide_all()
		#cutscene_timer.wait_time = 20
		cutscene_timer.start()
		play_cutscene()
	
	#MAJOR can have more entries than n00bs
	if boons >= XHB_cost["MAJOR"] and boons < XHB_cost["DD2"]:
		hide_all()
		#cutscene_timer.wait_time = 30
		cutscene_timer.start()
		play_cutscene()
		tick_speed *= 1.1
		
	#similar to major
	if boons >= XHB_cost["DD2"]:
		hide_all()
		#cutscene_timer.wait_time = 120
		cutscene_timer.start()
		play_cutscene()
		#win game maybe

#todo
func win_game() -> void:
	if finishable and !sacrificed:
		#good end
		hide_all()
		particles.get_node("Ascend").show()
		$TrueEnd.play()
		show_ending_text()
		restart_fadein()
		
		finishable = false
		
	elif finishable and sacrificed:
		#bad end
		hide_all()
		particles.get_node("Descend").show()
		$End.play()
		show_ending_text()
		restart_fadein()
		
		finishable = false

func restart_fadein() -> void:
	restart_button.modulate.a = 0.0 #alpha to 0
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
	tick_speed = 1.0
	speed_mult = 1.0
	
	$End.stop()
	$TrueEnd.stop()
	
	particles.get_node("Descend").hide()
	particles.get_node("Ascend").hide()
	
	show_all()
	ending_text.hide()
	restart_button.hide()
