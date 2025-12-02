extends Node

@export var letter_scene: PackedScene
@export var letter_spawn_timer: Timer
@export var letter_spawn_location: PathFollow2D
@export var difficulty_timer: Timer
@export var reminder_text_timer: Timer

@export var player: Player
@export var camera: Camera2D
@export var score_label: RichTextLabel
@export var reminder_label: RichTextLabel
@export var arrow: Sprite2D
@export var sfx_key_click: AudioStreamPlayer2D
@export var sfx_letter_hit: AudioStreamPlayer2D
@export var sfx_player_hit: AudioStreamPlayer2D
@export var game_over_screen: Control

var dictionary: Dictionary = {}
var typed_word: String = ""
var score: int = 0
var active_letters: Array[Letter] = []
var letter_speed: float = 10.0
var max_shake: float = 10.0
var camera_shake_fade: float = 10.0

var _shake_strength: float = 0.0

func _ready() -> void:
	SignalBus.player_hit.connect(on_player_hit)
	SignalBus.player_died.connect(game_over)
	# Load words from text file
	var file = FileAccess.open("res://Assets/words_alpha.txt", FileAccess.READ)
	var content := file.get_as_text().replace("\r", "").split("\n", false)
	for word in content:
		dictionary[word] = 1

	letter_spawn_timer.wait_time = 1.6
	letter_spawn_timer.timeout.connect(spawn_letter)
	letter_spawn_timer.start()

	reminder_text_timer.wait_time = 2.0
	reminder_text_timer.one_shot = true
	reminder_text_timer.timeout.connect(func(): reminder_label.text = "")

	difficulty_timer.wait_time = 30.0
	difficulty_timer.timeout.connect(increase_difficulty)
	difficulty_timer.start()

func _process(_delta):
	if (_shake_strength > 0):
		_shake_strength = lerp(_shake_strength, 0.0, camera_shake_fade * _delta)
		camera.offset = Vector2(randf_range(-_shake_strength, _shake_strength), randf_range(-_shake_strength, _shake_strength))
	if player:
		player.input_text.text = typed_word
	if Input.is_action_just_pressed("backspace"):
		if (active_letters.size()):
			backspace()
	if Input.is_action_just_pressed("submit_word"):
		var is_word_valid = typed_word in dictionary 
		if typed_word.length() <= 2:
			shake_camera()
			reminder_label.text = "Words must be 3 or more letters!"
			sfx_player_hit.play()
			reminder_text_timer.start()
			clear()
		elif is_word_valid:
			snipe()
		else: 
			shake_camera()
			reminder_label.text = typed_word + " is an invalid word!"
			sfx_player_hit.play()
			reminder_text_timer.start()
			clear()
	score_label.text = str(score)	

func shake_camera():
	_shake_strength = max_shake

func spawn_letter():
	var letter = letter_scene.instantiate()
	letter_spawn_location.progress_ratio = randf()
	letter.position = letter_spawn_location.position 
	letter.player = player
	letter.speed = letter_speed
	add_child(letter)

func increase_difficulty():
	letter_spawn_timer.wait_time = clamp(0.8, letter_spawn_timer.wait_time - 0.1, letter_spawn_timer.wait_time)
	letter_speed = clamp (letter_speed, letter_speed + 5.0, 50)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.is_pressed():
		var key_label = event.as_text_physical_keycode()
		if key_label.length() == 1:
			var lc_letter = key_label.to_lower()
			var letters = get_letters()
			var closest_valid_letter = null
			for letter in letters:
				if (!player): break
				if letter.letter_label == lc_letter and !letter.active:
					if !closest_valid_letter:
						closest_valid_letter = letter
					else:
						if (letter.global_position.distance_to(player.global_position) <= 
						closest_valid_letter.global_position.distance_to(player.global_position)):
							closest_valid_letter = letter
			
			if closest_valid_letter:
				closest_valid_letter.active = true
				active_letters.append(closest_valid_letter)
				typed_word += lc_letter
				sfx_key_click.play()
				
func get_letters() -> Array[Node]:
	return get_tree().get_nodes_in_group(Alphabet.letter_group_name)

func clear() -> void:
	typed_word = ""
	active_letters = []
	var letters = get_letters()
	for letter in letters:
		letter.active = false

func set_pitch(sfx: AudioStreamPlayer2D, index: int):
	var modifier = clamp(0.5 + index * .1, 0, 1.0)
	sfx.pitch_scale = modifier

func increase_score(combo: int):
	set_pitch(sfx_letter_hit, combo)
	score += 10 * combo

func snipe() -> void:
	var tween = create_tween()
	for i in range (active_letters.size()):
		tween.tween_callback(arrow.look_at.bind(active_letters[i].global_position))
		tween.tween_property(arrow, "global_position", active_letters[i].global_position, 0.15)
		tween.tween_callback(increase_score.bind(i))
		tween.tween_callback(sfx_letter_hit.play)
		tween.tween_callback(active_letters[i].queue_free)
	
	tween.tween_callback(arrow.look_at.bind(player.global_position))
	tween.tween_property(arrow, "global_position", player.global_position, 0.15)
	await tween.finished
	if (arrow): arrow.rotation = deg_to_rad(-36)
	score += 10 * typed_word.length()
	clear()	

func on_player_hit() -> void:
	shake_camera()
	clear()
	sfx_player_hit.play()

func game_over() -> void:
	reminder_label.push_color(Color.WHITE)
	reminder_label.text = "FINAL SCORE: " + str(score)
	game_over_screen.visible = true
	shake_camera()
	clear()
	letter_spawn_timer.stop()
	difficulty_timer.stop()
	score_label.visible = false

func backspace() -> void:
	var last_letter = active_letters.pop_back()
	last_letter.active = false
	typed_word = typed_word.left(typed_word.length() - 1)

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
