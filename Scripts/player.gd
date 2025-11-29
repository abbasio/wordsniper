class_name Player
extends Area2D

@export var input_text: RichTextLabel
@export var animated_sprite: AnimatedSprite2D

func _ready() -> void:
	animated_sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	body.queue_free()