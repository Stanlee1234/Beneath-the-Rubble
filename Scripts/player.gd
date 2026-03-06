extends CharacterBody2D

@export var speed: float = 200.0 

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# We add this to remember which way the player was facing when they stop moving
var last_direction: Vector2 = Vector2.DOWN 

func _physics_process(_delta: float) -> void:
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# If the player is pressing a movement key, update the last_direction
	if input_direction != Vector2.ZERO:
		last_direction = input_direction
	
	velocity = input_direction * speed
	move_and_slide()
	
	update_animation(input_direction)

func update_animation(direction: Vector2) -> void:
	# 1. IDLE STATE: Player is not moving
	if direction == Vector2.ZERO:
		# Use last_direction to figure out which idle animation to play
		if abs(last_direction.x) > abs(last_direction.y):
			sprite.play("idleSide")
			sprite.flip_h = last_direction.x < 0
		else:
			if last_direction.y > 0:
				sprite.play("idleDown")
			else:
				sprite.play("idleUp")
		return

	# 2. WALKING STATE: Player is moving
	if abs(direction.x) > abs(direction.y):
		sprite.play("walkSide")
		sprite.flip_h = direction.x < 0
	else:
		if direction.y > 0:
			sprite.play("walkDown")
		else:
			sprite.play("walkUp")
