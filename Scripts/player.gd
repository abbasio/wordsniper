class_name Player
extends Area2D

@export var input_text: RichTextLabel
@export var animated_sprite: AnimatedSprite2D
@export var health_bar: ProgressBar

var health: int = 10

func _ready() -> void:
	health_bar.value = health
	animated_sprite.play("idle")

func _process(_delta: float) -> void:
	health_bar.value = health
	if health == 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	health -= 1
	body.queue_free()