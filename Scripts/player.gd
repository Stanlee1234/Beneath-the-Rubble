extends CharacterBody2D

# 1. Speed cranked up to 900!
@export var speed: float = 900.0 

@export var equipped_tool: Texture2D 

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var weapon_sprite: Sprite2D = $WeaponPivot/WeaponSprite

var last_direction: Vector2 = Vector2.DOWN 
var input_stack: Array[String] = []
var is_busy: bool = false 

func _input(event: InputEvent) -> void:
	# 1. Handle the Attack Action (Only allow starting an attack if we aren't already busy)
	if event.is_action_pressed("attack") and not is_busy:
		perform_action()
		return

	# 2. Always update the Movement Stack! 
	# Even if we are swinging (is_busy), we want to remember what keys you press or release.
	var actions = ["ui_left", "ui_right", "ui_up", "ui_down"]
	for action in actions:
		if event.is_action_pressed(action):
			if not input_stack.has(action):
				input_stack.append(action)
		elif event.is_action_released(action):
			input_stack.erase(action)

func _physics_process(_delta: float) -> void:
	# If busy, stop moving, but DON'T clear the stack. 
	# When is_busy becomes false, the code below will instantly resume using your held keys.
	if is_busy:
		velocity = Vector2.ZERO
		move_and_slide()
		return

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

# --- UNIFIED ACTION SYSTEM ---
func perform_action() -> void:
	is_busy = true
	# Notice we removed input_stack.clear() from here!
	
	weapon_sprite.texture = equipped_tool
	weapon_sprite.visible = true
	
	var anim_name = ""
	
	if abs(last_direction.x) > abs(last_direction.y):
		anim_name = "swingSide"
		sprite.flip_h = last_direction.x < 0
		weapon_pivot.rotation_degrees = 180 if last_direction.x < 0 else 0
	else:
		if last_direction.y > 0:
			anim_name = "swingDown"
			weapon_pivot.rotation_degrees = 90
		else:
			anim_name = "swingUp"
			weapon_pivot.rotation_degrees = -90
			
	sprite.play(anim_name)
	
	var swing_tween = create_tween()
	swing_tween.tween_property(weapon_sprite, "rotation_degrees", 90.0, 0.2).as_relative()
	
	await sprite.animation_finished
	
	weapon_sprite.rotation_degrees = 0
	weapon_sprite.visible = false
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
