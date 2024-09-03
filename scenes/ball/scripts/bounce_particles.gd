extends GPUParticles2D

@onready var timer: Timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.start(lifetime + 1.0)
	emitting = true

func _on_timer_timeout() -> void:
	queue_free()
