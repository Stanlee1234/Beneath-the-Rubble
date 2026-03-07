extends CharacterBody2D

@export var speed: float = 900.0 
@export var hitbox_reach: float = 24.0 
@export var invincibility_duration: float = 0.4 # How long you are invincible after a hit

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var action_hitbox: Area2D = $ActionHitbox
@onready var hitbox_shape: CollisionShape2D = $ActionHitbox/CollisionShape2D

var last_direction: Vector2 = Vector2.DOWN 
var input_stack: Array[String] = []

var is_busy: bool = false 
var is_knocked_back: bool = false 
var is_invincible: bool = false # The new i-frame toggle!

func _ready() -> void:
	hitbox_shape.disabled = true

func _input(event: InputEvent) -> void:
	if is_knocked_back:
		return 

	# 1. Handle Action (.)
	if event.is_action_pressed("attack") and not is_busy:
		perform_action()
		return

	# 2. Handle Movement Stack
	var actions = ["ui_left", "ui_right", "ui_up", "ui_down"]
	for action in actions:
		if event.is_action_pressed(action):
			if not input_stack.has(action):
				input_stack.append(action)
		elif event.is_action_released(action):
			input_stack.erase(action)

func _physics_process(delta: float) -> void:
	# --- 1. Knockback State ---
	if is_knocked_back:
		velocity = velocity.move_toward(Vector2.ZERO, 5000 * delta)
		move_and_slide()
		return

	# --- 2. Action/Swinging State ---
	if is_busy:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# --- 3. Normal Movement State ---
	var input_direction = Vector2.ZERO
	
	if input_stack.size() > 0:
		var current_action = input_stack.back() 
		match current_action:
			"ui_left": input_direction.x = -1
			"ui_right": input_direction.x = 1
			"ui_up": input_direction.y = -1
			"ui_down": input_direction.y = 1
	
	if input_direction != Vector2.ZERO:
		last_direction = input_direction
	
	velocity = input_direction * speed
	move_and_slide()
	
	update_animation(input_direction)

# --- ACTION SYSTEM ---
func perform_action() -> void:
	is_busy = true
	var anim_name = ""
	
	if abs(last_direction.x) > abs(last_direction.y):
		anim_name = "swingSide"
		sprite.flip_h = last_direction.x < 0
		var direction_sign = -1 if last_direction.x < 0 else 1
		action_hitbox.position = Vector2(direction_sign * hitbox_reach, 0)
	else:
		if last_direction.y > 0:
			anim_name = "swingDown"
			action_hitbox.position = Vector2(0, hitbox_reach)
		else:
			anim_name = "swingUp"
			action_hitbox.position = Vector2(0, -hitbox_reach)
			
	hitbox_shape.disabled = false
	sprite.play(anim_name)
	
	await sprite.animation_finished
	
	hitbox_shape.disabled = true
	is_busy = false

# --- ANIMATION UPDATES ---
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

# --- OFFENSIVE COLLISION (Hitting Rocks) ---
func _on_action_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(10)

# --- DEFENSIVE COLLISION (Taking Damage) ---
func take_damage(amount: int, hazard_position: Vector2) -> void:
	# If we are already invincible, completely ignore the fire!
	if is_invincible:
		return
		
	is_invincible = true
	is_knocked_back = true
	is_busy = false 
	hitbox_shape.disabled = true 
	
	print("Player took ", amount, " damage!")
	
	# 1. Figure out current input direction to knock them the opposite way
	var current_input = Vector2.ZERO
	if input_stack.size() > 0:
		match input_stack.back():
			"ui_left": current_input.x = -1
			"ui_right": current_input.x = 1
			"ui_up": current_input.y = -1
			"ui_down": current_input.y = 1
			
	var knockback_direction = Vector2.ZERO
	if current_input != Vector2.ZERO:
		# Knock them exactly opposite of the key they are pressing
		knockback_direction = -current_input
	else:
		# Fallback: If they aren't holding any keys, knock them opposite of the way they are facing
		knockback_direction = -last_direction
		
	# Clear the inputs AFTER checking them
	input_stack.clear() 

	# 2. Red Flash & Apply Knockback
	var flash_tween = create_tween()
	flash_tween.tween_property(sprite, "modulate", Color.RED, 0.05)
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	
	velocity = knockback_direction * 1300.0 
	
	# 3. Wait out the knockback slide (0.2 seconds)
	await get_tree().create_timer(0.2).timeout
	
	# 4. Give movement control back, but KEEP i-frames active
	is_knocked_back = false
	
	# 5. Start the blinking effect to show i-frames are active
	# We loop it so they flash partially transparent and back to solid
	var blink_tween = create_tween().set_loops() 
	blink_tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
	blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	
	# 6. Wait for the remainder of the invincibility duration
	await get_tree().create_timer(invincibility_duration - 0.2).timeout
	
	# 7. Turn off i-frames and stop the blinking
	is_invincible = false
	blink_tween.kill() # Stop the looping animation
	sprite.modulate.a = 1.0 # Make sure they are fully visible again
