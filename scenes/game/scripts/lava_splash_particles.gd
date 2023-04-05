extends GPUParticles2D

func _ready():
	emitting = true
	$GPUParticles2D2.emitting = true
	$Timer.start(lifetime + $GPUParticles2D2.lifetime + 1.0)

func _on_timer_timeout():
	queue_free()
