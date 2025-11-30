extends Node

@export var enemy_scene: PackedScene
@export var enemy_spawn_timer: Timer
@export var enemy_spawn_location: PathFollow2D
@export var player: Player
@export var score_label: RichTextLabel
@export var arrow: Sprite2D
@export var sfx_key_click: AudioStreamPlayer2D
@export var sfx_letter_hit: AudioStreamPlayer2D

var dictionary: Dictionary = {}
var typed_word: String = ""
var score: int = 0
var active_letters: Array[Enemy] = []

func _ready() -> void:
	SignalBus.player_hit.connect(clear)
	# Load words from text file
	var file = FileAccess.open("res://Assets/words_alpha.txt", FileAccess.READ)
	var content := file.get_as_text().replace("\r", "").split("\n", false)
	for word in content:
		dictionary[word] = 1

	enemy_spawn_timer.wait_time = 2.0
	enemy_spawn_timer.timeout.connect(spawn_enemy)
	enemy_spawn_timer.start()

func _process(_delta):
	player.input_text.text = typed_word
	if Input.is_action_just_pressed("backspace"):
		clear()
	if Input.is_action_just_pressed("submit_word"):
		var is_word_valid = typed_word in dictionary 
		if typed_word.length() <= 2:
			print('need longer word')
			clear()
		elif is_word_valid:
			snipe()
		else: 
			print("Word is invalid.")
			clear()
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
			var closest_valid_enemy = null
			for enemy in enemies:
				if enemy.letter_label == lc_letter and !enemy.active:
					if !closest_valid_enemy:
						closest_valid_enemy = enemy
					else:
						if (enemy.global_position.distance_to(player.global_position) <= 
						closest_valid_enemy.global_position.distance_to(player.global_position)):
							closest_valid_enemy = enemy
			
			if closest_valid_enemy:
				closest_valid_enemy.active = true
				active_letters.append(closest_valid_enemy)
				typed_word += lc_letter
				sfx_key_click.play()
			else:
				print("invalid letter")

func get_enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group(Alphabet.enemies)

func clear() -> void:
	typed_word = ""
	active_letters = []
	var enemies = get_enemies()
	for enemy in enemies:
		enemy.active = false

func set_pitch(sfx: AudioStreamPlayer2D, index: int):
	var modifier = clamp(0.8 + index * .1, 0, 1.2)
	sfx.pitch_scale = modifier

func snipe() -> void:
	var tween = create_tween()
	for i in range (active_letters.size()):
		tween.tween_callback(arrow.look_at.bind(active_letters[i].global_position))
		tween.tween_property(arrow, "global_position", active_letters[i].global_position, 0.15)
		tween.tween_callback(set_pitch.bind(sfx_letter_hit, i))
		tween.tween_callback(sfx_letter_hit.play)
		tween.tween_callback(active_letters[i].queue_free)
	
	tween.tween_callback(arrow.look_at.bind(player.global_position))
	tween.tween_property(arrow, "global_position", player.global_position, 0.15)
	await tween.finished
	arrow.rotation = deg_to_rad(-36)
	print('tween finished')		
	score += 10 * typed_word.length()
	clear()	

# when a valid word is submitted, we should fire a projectile to the first letter of that word
# the projectile should then bounce to all the following letters, in order
# at each bounce, a sound effect should play, and the score multiplier should go up
# once the word is fully completed, the score updates
