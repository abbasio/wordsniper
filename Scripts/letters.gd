class_name Letter
extends CharacterBody2D

@export var sprite: AnimatedSprite2D
@export var player: Area2D

var speed = 15.0
var letter_index: int
var letter_label: String
var active: bool = false

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	# use letters weights from scrabble lol
	var weights = PackedFloat32Array([9, 2, 2, 4, 12, 2, 3, 2, 9, 1, 1, 4, 2, 6, 8, 2, 1, 6, 4, 6, 4, 2, 2, 1, 2, 1])
	letter_index = rng.rand_weighted(weights)
	letter_label = Alphabet.letters[letter_index]
	sprite.frame = letter_index

func _physics_process(_delta: float) -> void:
	if active:
		sprite.modulate = Color(0, 0, 1, 1)
	else:
		sprite.modulate = Color(0, 0, 1, 0.25)
	if player:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
