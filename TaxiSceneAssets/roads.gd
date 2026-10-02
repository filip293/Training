extends Node3D

var speed : float = 100.0 
var chunk_length : float = 228.0 

func _process(delta):
	for road in get_children():
		road.position.z -= speed * delta
		
		# Multiply by 1.5 so the chunk travels much further behind the car before teleporting
		if road.position.z < -chunk_length * 1.5:
			# Multiply by 3 because we are now cycling three chunks instead of two
			road.position.z += chunk_length * 3
