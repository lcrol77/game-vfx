extends GPUParticles2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	emitting = true
	$Explosion.emitting = true
	$Timer.start(lifetime + 1.0)

func _on_timer_timeout() -> void:
	queue_free()
