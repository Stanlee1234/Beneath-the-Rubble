extends CharacterBody2D

@export var speed: float = 900.0 

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_direction: Vector2 = Vector2.DOWN 

# This array acts as our "stack" to remember the order of keys pressed
var input_stack: Array[String] = []

# _input runs exactly when a key is pressed or released
func _input(event: InputEvent) -> void:
	var actions = ["ui_left", "ui_right", "ui_up", "ui_down"]
	
	for action in actions:
		if event.is_action_pressed(action):
			# If pressed, add it to the end of the stack
			if not input_stack.has(action):
				input_stack.append(action)
		elif event.is_action_released(action):
			# If released, remove it from the stack
			input_stack.erase(action)

func _physics_process(_delta: float) -> void:
	var input_direction = Vector2.ZERO
	
	# If we are holding any keys, the active key is the last one we pressed
	if input_stack.size() > 0:
		var current_action = input_stack.back() # Gets the most recent key
		
		# Apply movement based on that single most recent key
		match current_action:
			"ui_left": input_direction.x = -1
			"ui_right": input_direction.x = 1
			"ui_up": input_direction.y = -1
			"ui_down": input_direction.y = 1
	
	# Update the direction we are facing for the idle animations
	if input_direction != Vector2.ZERO:
		last_direction = input_direction
	
	velocity = input_direction * speed
	move_and_slide()
	
	update_animation(input_direction)

func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		if abs(last_direction.x) > abs(last_direction.y):
			sprite.play("idleSide")
			sprite.flip_h = last_direction.x < 0
		else:
			if last_direction.y > 0:
				sprite.play("idleDown")
			else:
				sprite.play("idleUp")
		return

	if abs(direction.x) > abs(direction.y):
		sprite.play("walkSide")
		sprite.flip_h = direction.x < 0
	else:
		if direction.y > 0:
			sprite.play("walkDown")
		else:
			sprite.play("walkUp")
