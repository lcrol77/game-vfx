extends GPUParticles2D

func _ready():
	emitting = true
	$BrickExplodeParticles2.emitting = true
	$Timer.start(lifetime + 1.0)

func _on_timer_timeout():
	queue_free()
