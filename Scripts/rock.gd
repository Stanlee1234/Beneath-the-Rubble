extends StaticBody2D

# 4 strikes * 10 damage = 40 health
@export var health: int = 40 

@onready var sprite: Sprite2D = $Sprite2D

func take_damage(amount: int) -> void:
	health -= amount
	
	# Create a quick visual flash so you know you hit it!
	var flash_tween = create_tween()
	flash_tween.tween_property(sprite, "modulate", Color(0.276, 0.276, 0.276, 1.0), 0.05)
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		break_rock()

func break_rock() -> void:
	# This safely deletes the rock from the game
	queue_free()
