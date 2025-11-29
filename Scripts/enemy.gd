class_name Enemy
extends CharacterBody2D

@export var sprite: AnimatedSprite2D
@export var player: Area2D

var speed = 15.0
var current_letter: Alphabet.letters
var letter_label: String
var active: bool = false

func _ready() -> void:
	current_letter = randi_range(0, 25) as Alphabet.letters
	sprite.frame = current_letter
	letter_label = Alphabet.map_enum_to_letter[current_letter]
	var letter_string = Alphabet.map_enum_to_letter[current_letter]
	Alphabet.active_enemies[letter_string].append(self)

func _physics_process(_delta: float) -> void:
	if active:
		sprite.modulate = Color(0, 0, 1, 1)
	else:
		sprite.modulate = Color(0, 0, 1, 0.25)
	if player:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed
		move_and_slide()
