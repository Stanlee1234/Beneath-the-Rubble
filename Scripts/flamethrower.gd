extends Node2D # Or Area2D, depending on your root node type

# Make sure this signal is connected from your Hitbox node!
func _on_hitbox_body_entered(body: Node2D) -> void:
	# Check if the object that entered the fire has the take_damage function
	if body.has_method("take_damage"):
		# Send the damage amount AND the flamethrower's exact global position
		# (We send the position so the player knows which way to fly backward)
		body.take_damage(10, global_position)
