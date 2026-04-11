extends Control

#it might have been easier to spread the code to multiple nodes and/or to use a single scene, but of well

@export var resources : Label
@export var flavourtext : Label
@export var ending_text : Label
@export var boonsave_label : Label
@export var entries_text : Label
@export var results_text : Label
@export var generate_timer : Timer
@export var tally_timer : Timer
@export var cutscene_timer : Timer
@export var boongain_timer : Timer
@export var sacrifice_button : Button
@export var host_battle_button : Button
@export var restart_button : Button
@export var buy_n00bs : Button

const slug_scene = preload("res://Scenes/Slugs.tscn")

@onready var particles = get_parent().get_node("Particles")
@onready var slugs = get_parent().get_node("Slugs")

#resources
var battle_pressed : bool = false
var boons : float = 0.00
const boons_per_tick : int = 9
var boon_mult : int = 1
var result_mult : float = 1.1
var n00bs : int = 0
var n00b_cost : float = 10.0
const n00b_cost_base : float = 10.0
const n00b_cost_mult : float = 1.618
const n00b_cost_reduction : float = 0.9
var entries : int = 0
var total_entries : int = 0
var sacrifice_cost : int = 2
var last_xhb : int = 0
var tempboons : float = 0.0

const cutscene_area_center : Vector3 = Vector3(0, 0, 0)

const XHB_cost = {
	"OHB": 725,
	"2HB": 2000,
	"4HB": 5656,
	"MAJOR": 56560,
	"DD2": 5656560, #might be fine, actually
}

#progression, ending
var sacrificed : bool = false #ending related
#var progression : int = 0 # ditched
var finishable : bool = false

#maybe add boon breakpoints for later texts - nah
const flavourtext_text = [
	"welcome, n00b",
	"boonless chicken",
	"batol",
	"batol is good",
	"We must gather more boons",
	"yea",
	"number go up",
	"more boons?",
	"more boons.",
	"MORE BOONS",
	"Your n00bs love you",
	"Host a battle!",
	"!xhb",
	"go on",
	"keep going",
	"The slugs love you too!",
	"yippee",
	
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
var iterations : int = 0
var tick_speed : float = 1.0
const flavour_timer : int = 10
var speed_mult : float = 1.0

#todo ambience audio
var playsound : bool = true
var slug_audio : bool = false
var slug_audio_iteration : int = 0
var results_audio : bool = false
var major9 : Array = [0, 4, 7, 11, 14]
var major9_iterator : int = 0
var major9_direction : int = 1
var results_audio_iteration : int = 0
var bleep: Array = []

#Function Section

func _ready():
	update_label_text()
	generate_timer.start(ticks)
	print(particles)
	particles.get_node("Ascend").hide()
	particles.get_node("Descend").hide()
	
	#setup multiple players to play multiple notes lol
	for i in range(10):
		var player = AudioStreamPlayer.new()
		player.stream = $Ambience.stream
		add_child(player)
		bleep.append(player)

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
	buy_n00bs.text = "buy n00b for %.2f boons" %n00b_cost
	


func update_flavourtext_text() -> void:
	if sacrificed:
		flavourtext.text = flavourtext_text[randi_range(-8, -1)]
	else:
		#flavourtext.text = flavourtext_text[randi_range(progression, 5 + progression)]
		flavourtext.text = flavourtext_text[randi_range(0, 16)]

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
	play_sfx()
	iterations += 1
	if battle_pressed: make_boons()
	generate_boons()
	timer_iterations += 1
	if timer_iterations >= (flavour_timer/ticks):
		update_flavourtext_text()
		timer_iterations = 0
	generate_timer.start(ticks)







func _on_tally_timer_timeout():
	entries_text.hide()
	boonsave_label.hide()
	cutscene_timer.start()
	play_cutscene()

func _on_cutscene_timer_timeout():
	#remove slugs
	for slug in get_tree().get_nodes_in_group("slugs"):
		slug.queue_free()
	slug_audio = false
	slug_audio_iteration = 0
	boongain_timer.start()
	resluts()

func _on_boongain_timeout():
	#remove labels
	for label in get_tree().get_nodes_in_group("results_labels"):
		label.queue_free()
	results_audio = false
	entries = 0
	tempboons = 0
	show_all()
	update_label_text()
	restart_button.hide()
	ending_text.hide()
	sacrifice_button.hide()
	boonsave_label.hide()
	entries_text.hide()
	results_text.hide()
	playsound = true
	if last_xhb >= XHB_cost["DD2"]:
		finishable = true







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
		return n00b_cost * n00b_cost_mult



#audio
#D A C# E F# G# A B C#+1 D+2
#longboi
#sounds a bit weird somehow, but should be correct, hmm. also obviously too slow.
func play_sfx() -> void:
	if playsound == true:
		if !sacrificed:
			if iterations % 50 == 0:
				if battle_pressed or n00bs > 4:
					bleep[0].pitch_scale = semitones_to_pitch(-7) #D
					bleep[0].play()
			if iterations % 100 == 0:
				if n00bs > 0:
					bleep[1].pitch_scale = semitones_to_pitch(0) #A
					bleep[1].play()
			if iterations % 150 == 0:
				if n00bs > 3:
					bleep[2].pitch_scale = semitones_to_pitch(4) #C#
					bleep[2].play()
			if iterations % 200 == 0:
				if n00bs > 7:
					bleep[3].pitch_scale = semitones_to_pitch(7) #E
					bleep[3].play()
			if iterations % 250 == 0:
				if n00bs > 8:
					bleep[4].pitch_scale = semitones_to_pitch(9) #F#
					bleep[4].play()
			if iterations % 65 == 0:
				if n00bs > 10:
					bleep[5].pitch_scale = semitones_to_pitch(10) #G#
					bleep[5].play()
			if iterations % 75 == 0:
				if n00bs > 25:
					bleep[6].pitch_scale = semitones_to_pitch(12) #A+1
					bleep[6].play()
			if iterations % 85 == 0:
				if n00bs > 35:
					bleep[7].pitch_scale = semitones_to_pitch(14) #B+1
					bleep[7].play()
			if iterations % 105 == 0:
				if n00bs > 200:
					bleep[8].pitch_scale = semitones_to_pitch(16) #C#+1
					bleep[8].play()
			if iterations % 155 == 0:
				if n00bs > 999:
					bleep[9].pitch_scale = semitones_to_pitch(17) #D+2
					bleep[9].play()
		#if sacrificed
		else:
			if iterations % 33 == 0:
				bleep[0].pitch_scale = semitones_to_pitch(randi_range(-12, 12))
				bleep[0].play()
	if slug_audio == true:
		if iterations % 4 == 0:
			bleep[0].pitch_scale = semitones_to_pitch(slug_audio_iteration)
			bleep[0].play()
			slug_audio_iteration += 2 #whole tone is nice
			slug_audio_iteration %= 26
	if results_audio == true:
		if iterations % 6 == 0:
			bleep[0].pitch_scale = semitones_to_pitch(major9[major9_iterator])
			bleep[0].play()
			major9_iterator += major9_direction
			if major9_iterator >= major9.size() - 1 or major9_iterator <= 0:
				major9_direction *= -1
			
			
		pass
	
func semitones_to_pitch(semitones: float) -> float:
	#A = 0, A# = 1, B = 2, etc.
	return pow(2.0, semitones / 12.0)



func tally_points() -> void:
	if last_xhb >= XHB_cost["DD2"]: entries = randi_range (n00bs, n00bs * 3)
	else: entries = randi_range (1, n00bs + 1)
	
	if last_xhb >= XHB_cost["MAJOR"]:
		entries = min(n00bs, n00bs * 5)
		n00bs *= 2
	if last_xhb >= XHB_cost["4HB"]:
		result_mult *= 1.1
	tempboons = entries * 10 * result_mult

	if (entries >= 3 and (last_xhb == XHB_cost["OHB"]))\
	or (entries >= 5 and (last_xhb == XHB_cost["2HB"]))\
	or (entries >= 7 and (last_xhb == XHB_cost["4HB"]))\
	or (entries >= 10 and (last_xhb == XHB_cost["MAJOR"])):
		#shows up too early, might not fix
		boonsave_label.show()
		tempboons += last_xhb * result_mult
	
	#count entries up
	var tween : Tween = create_tween()
	entries_text.show()
	tween.tween_method(func(i):
		entries_text.text = "%s emptries!" %i,
		0,
		entries,
		tally_timer.wait_time)
	
	
	var audio_tween : Tween = create_tween()
	#just tween everything
	for i in entries:
		audio_tween.tween_interval(tally_timer.wait_time/entries)
		audio_tween.tween_callback(func():
			$Ambience.pitch_scale = semitones_to_pitch(i)
			$Ambience.play()
		)
		
	boons += tempboons
	n00b_cost *= pow(n00b_cost_reduction, entries)
	n00b_cost = ceil(n00b_cost)

#todo sfx
func play_cutscene() -> void:
	var slug_amount = min(entries, 560)
	slug_audio = true
	for i in slug_amount:
		randomize()
		var slug = slug_scene.instantiate()
		slug.add_to_group("slugs")
		get_tree().current_scene.add_child(slug)
		slug.global_position = cutscene_area_center + Vector3(
			randf_range(-4.0, 4.0),
			randf_range(-3.0, 3.0),
			randf_range(-10.0, 10.0))
		slug.rotation.y = randf_range(0, TAU)
		
		var animations: AnimationPlayer = slug.get_node("AnimationPlayer")
		var animation = animations.get_animation_list()
		animations.play(animation[randi() % animation.size()])
		animations.set_speed_scale(randf_range(0.5 * tick_speed, 2 * tick_speed))

func resluts() -> void:
	results_text.text = "+%.2f boons!" %tempboons
	results_text.show()
	results_audio = true
	#make text instances in for-loop with various sizes and colors
	var label_amount : int = 10
	for i in label_amount:
		var label = results_text.duplicate()
		label.z_index = -i
		label.add_to_group("results_labels")
		results_text.get_parent().add_child(label)
		#label.show()
		label.add_theme_font_size_override("font_size", 28 + i * 8)
		var middle_y = get_viewport().size.y / 2.0 - label.size.y /2.0 #subtract half of label size to make swaying uniform
		var offset = randi()
		var tween = label.create_tween().set_loops()
		tween.tween_method(
			func(j: float):
				label.position.y = middle_y + sin(j + i + offset) * 200 #swaying
				label.add_theme_color_override("font_color", Color.from_hsv(fmod(j / TAU + i * 0.5, 1.0), 0.5, 0.5)), #color shift
				#end func
			0.0,
			TAU,
			float(i+1)/2
		)







#todo values
func host_xhb() -> void:
	if boons >= XHB_cost["OHB"] and boons < XHB_cost["2HB"]:
		hide_all()
		playsound = false
		#cutscene_timer.wait_time = 5
		tally_timer.start()
		boons -= XHB_cost["OHB"]
		last_xhb = XHB_cost["OHB"]
		tally_points()

	if boons >= XHB_cost["2HB"] and boons < XHB_cost["4HB"]:
		hide_all()
		playsound = false
		#cutscene_timer.wait_time = 10
		tally_timer.start()
		boons -= XHB_cost["2HB"]
		last_xhb = XHB_cost["2HB"]
		tally_points()

	if boons >= XHB_cost["4HB"] and boons < XHB_cost["MAJOR"]:
		hide_all()
		playsound = false
		#cutscene_timer.wait_time = 20
		tick_speed *= 1.1
		tally_timer.start()
		boons -= XHB_cost["4HB"]
		last_xhb = XHB_cost["4HB"]
		tally_points()
		
	#MAJOR can have more entries than n00bs
	if boons >= XHB_cost["MAJOR"] and boons < XHB_cost["DD2"]:
		hide_all()
		playsound = false
		#cutscene_timer.wait_time = 30
		tick_speed *= 1.1
		tally_timer.start()
		boons -= XHB_cost["MAJOR"]
		last_xhb = XHB_cost["MAJOR"]
		tally_points()
		
	#similar to major
	if boons >= XHB_cost["DD2"]:
		hide_all()
		playsound = false
		#cutscene_timer.wait_time = 120
		#cutscene_timer.wait_time = 120
		#cutscene_timer.wait_time = 120
		tally_timer.start()
		boons -= XHB_cost["DD2"]
		last_xhb = XHB_cost["DD2"]
		tally_points()
		#win game maybe

func win_game() -> void:
	if finishable and !sacrificed:
		#good end
		playsound = false
		hide_all()
		particles.get_node("Ascend").show()
		$TrueEnd.play()
		show_ending_text()
		restart_fadein()
		
		finishable = false
		
	elif finishable and sacrificed:
		#bad end
		playsound = false
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
	iterations = 0
	finishable = false
	playsound = true
	tick_speed = 1.0
	speed_mult = 1.0
	last_xhb = 0
	
	$End.stop()
	$TrueEnd.stop()
	
	particles.get_node("Descend").hide()
	particles.get_node("Ascend").hide()
	update_label_text()
	show_all()
	ending_text.hide()
	boonsave_label.hide()
	restart_button.hide()
	entries_text.hide()
	results_text.hide()
