extends Node

@export var enemy_scene: PackedScene
@export var enemy_spawn_timer: Timer
@export var enemy_spawn_location: PathFollow2D
@export var player: Player
@export var score_label: RichTextLabel

var dictionary: Dictionary = {}
var typed_word: String = ""
var score: int = 0
var first_letter: Enemy

func _ready() -> void:
	# Load words from text file
	var file = FileAccess.open("res://Assets/words_alpha.txt", FileAccess.READ)
	var content := file.get_as_text().replace("\r", "").split("\n", false)
	for word in content:
		dictionary[word] = 1

	enemy_spawn_timer.wait_time = 1.4
	enemy_spawn_timer.timeout.connect(spawn_enemy)
	enemy_spawn_timer.start()

func _process(_delta):
	player.input_text.text = typed_word
	if Input.is_action_just_pressed("backspace"):
		typed_word = ""
		var enemies = get_enemies()
		for enemy in enemies:
			enemy.active = false
	if Input.is_action_just_pressed("submit_word"):
		var is_word_valid = typed_word in dictionary 
		var enemies = get_enemies()
		if typed_word.length() <= 1:
			print('need longer word')
		elif is_word_valid:
			print("Word is valid!")
			score += 10 * typed_word.length()
			for enemy in enemies:
				if enemy.active: 
					enemy.queue_free()
		else: 
			print("Word is invalid.")
		typed_word = ""
		for enemy in enemies:
			enemy.active = false
	score_label.text = str(score)	

func spawn_enemy():
	var enemy: Enemy = enemy_scene.instantiate()

	enemy_spawn_location.progress_ratio = randf()

	enemy.position = enemy_spawn_location.position 
	enemy.player = player
	add_child(enemy)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.is_pressed():
		var key_label = event.as_text_physical_keycode()
		if key_label.length() == 1:
			var lc_letter = key_label.to_lower()
			var enemies = get_enemies()
			var activated = false
			for enemy in enemies:
				if enemy.letter_label == lc_letter and !enemy.active:
					enemy.active = true
					activated = true
					if typed_word.is_empty():
						first_letter = enemy
					break
			
			if activated:
				typed_word += lc_letter
			else:
				print("invalid letter")

func get_enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group(Alphabet.enemies)

# when a letter is spawned, we add it to a global list of existing letters
# when a letter is typed, we check against that global list
# if the letter doesn't exist, we error/screenshake/don't type anything
# if the letter does exist, we need to highlight that letter and type it in to the player's input
# if there are multiple instances of that letter, we should select the one that is closest to the player
# once the word is 'submitted', if it is valid, we destroy all of the letters that made up that word
# if it is not valid, we error/screenshake/reset the player's input
