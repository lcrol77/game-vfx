extends Node2D

@export var lava_splash: PackedScene = preload("res://scenes/game/lava_splash_particles.tscn")
@export var ultimate_ready_scene: PackedScene = preload("res://scenes/ui/ultimate/ultimate_ready.tscn")
@export var game_over_scene: PackedScene = preload("res://scenes/ui/game_over/game_over.tscn")
@export var stage_clear_scene: PackedScene = preload("res://scenes/ui/stage_clear/stage_clear.tscn")
@export var brick_scene: PackedScene = preload("res://scenes/brick/brick.tscn")
@export var block_energy: int = 10
@export var energy_block_energy: int = 100

var health: int = 3
var energy: float = 0.0
var score_brick_destroyed: int = 200
var score_brick_touched: int = 50
var score: int = 0
var combo: int = 0
var bricks: Array
var bricks_to_destroy: Array
var time: float = 0
var started: bool = false

var combo_tween: Tween
var camera_tween: Tween

@onready var paddle: CharacterBody2D = $Paddle
@onready var ball: CharacterBody2D = $Ball
@onready var energy_bar: Control = $HUDCanvasLayer/EnergyBar
@onready var health_bar: Control = $HUDCanvasLayer/HealthBar
@onready var score_ui = $HUDCanvasLayer/Score
@onready var spawn_pos_container: Node = $SpawnPos
@onready var brick_container: Node = $Bricks
@onready var combo_timer: Timer = $ComboTimer
@onready var combo_lbl = $Combo
@onready var camera = $Camera2D
@onready var hud_canvas_layer = $HUDCanvasLayer
@onready var ui_canvas_layer = $UICanvasLayer
@onready var pattern = $Pattern
@onready var bw = $EffectCanvasLayer/BW

func _ready() -> void:
	randomize()
	
	hide_combo()
	
	Globals.camera = camera
	Globals.camera.objects = [ball]
	Globals.pattern = pattern
	
	ball.attached_to = paddle.launch_point
	paddle.ball_attached = ball
	paddle.ball = ball
	
	combo_lbl.scale = Vector2.ZERO
	
	for brick in get_tree().get_nodes_in_group("Bricks"):
		brick.energy_brick_destroyed.connect(on_energy_brick_destroyed)
		
	# Remove for testing with predefined bricks
	remove_all_bricks()
	layout_bricks()
	
func _process(delta) -> void:
	if not started: return
	time += delta
		
func layout_bricks() -> void:
	var bricks_tween: Tween = create_tween()
	var max_bricks: int = spawn_pos_container.get_child_count()
	for i in range(max_bricks):
		# 90% chance of having a block
		if randf() < 0.1: continue
		bricks_tween.tween_callback(add_brick.bind(brick_container, spawn_pos_container.get_child(i).global_position))
		bricks_tween.tween_interval(0.1)
	bricks_tween.tween_property(paddle, "can_move", true, 0.1)
#		add_brick(brick_container, spawn_pos_container.get_child(i).global_position)
	
func add_brick(parent: Node, pos: Vector2) -> void:
	var instance = brick_scene.instantiate()
	parent.add_child(instance)
	instance.energy_brick_destroyed.connect(on_energy_brick_destroyed)
	instance.destroyed.connect(on_brick_destroyed)
	instance.global_position = pos
	bricks.append(instance)
	if instance.type != instance.TYPE.EXPLOSIVE and instance.type != instance.TYPE.ENERGY:
		bricks_to_destroy.append(instance)
	
func remove_all_bricks() -> void:
	bricks.clear()
	bricks_to_destroy.clear()
	for brick in brick_container.get_children():
		brick.queue_free()
	
func reset_and_attach_ball() -> void:
	ball.dead = false
	ball.can_move = true
	ball.velocity = Vector2.ZERO
	ball.attached_to = paddle.launch_point
	ball.appear()
	paddle.ball_attached = ball
	paddle.game_over = false
	paddle.stage_clear = false
	paddle.can_move = true
	
func add_energy(value: float) -> void:
	if energy < 100 and energy + value >= 100:
		spawn_ultimate_ready()
	energy += value
	energy = clamp(energy, 0, 100)
	energy_bar.set_energy(energy)
	
func remove_energy(value: float) -> void:
	energy -= value
	energy = clamp(energy, 0, 100)
	energy_bar.set_energy(energy)

func reset_energy() -> void:
	energy = 0
	energy_bar.set_energy(energy)
	
func reset_health() -> void:
	health = 3
	health_bar.set_health(health)
	
func reset_score() -> void:
	score = 0
	score_ui.set_score(score)
	
func show_combo(combo: int) -> void:
	combo_timer.start()
	combo_lbl.text = "COMBO " + str(combo)
	combo_lbl.material.set_shader_parameter("fill_v", 0.0)
	
	if combo_tween and combo_tween.is_running():
		combo_tween.kill()
	combo_tween = create_tween()
	combo_tween.tween_property(combo_lbl, "scale", Vector2.ONE, 0.25) \
								.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	combo_tween.tween_property(combo_lbl.material, "shader_parameter/fill_v", 0.28, \
								combo_timer.wait_time).set_trans(Tween.TRANS_LINEAR)

func hide_combo() -> void:
	if combo_tween and combo_tween.is_running():
		combo_tween.kill()
	combo_tween = create_tween()
	combo_tween.tween_property(combo_lbl, "scale", Vector2.ZERO, 0.3) \
								.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func spawn_laval_splash(pos: Vector2) -> void:
	var instance = lava_splash.instantiate()
	add_child(instance)
	instance.global_position = pos

func spawn_ultimate_ready() -> void:
	var instance = ultimate_ready_scene.instantiate()
	hud_canvas_layer.add_child(instance)
	
func clear_level_camera_sequence() -> void:
	if camera_tween != null and camera_tween.is_running():
		camera_tween.kill()
	camera.dynamic_enabled = false
	camera.target = ball
	
	Globals.camera.shake(0.5, 25, 25)
	Input.start_joy_vibration(0, 0.5, 0.25, 0.5)
	
	camera_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(Engine, "time_scale", 0.1, 0.25)
	camera_tween.parallel().tween_property(camera, "global_position", ball.global_position, 0.3)
	camera_tween.parallel().tween_property(camera, "zoom", Vector2(1.5, 1.5), 0.25)
	camera_tween.tween_interval(0.25)
	camera_tween.tween_property(Engine, "time_scale", 1.0, 0.25)
	camera_tween.parallel().tween_property(camera, "global_position", get_viewport_rect().size/2.0, 0.35)
	camera_tween.parallel().tween_property(camera, "zoom", Vector2.ONE, 0.35)
	camera_tween.tween_callback(Callable(self, "level_clear_camera_sequence_done"))

func level_clear_camera_sequence_done() -> void:
	camera.target = null
	camera.dynamic_enabled = true
	ball.can_move = false
	show_stage_clear()

func death_camera_sequence() -> void:
	if camera_tween != null and camera_tween.is_running():
		camera_tween.kill()
	camera.dynamic_enabled = false
	camera.target = ball
	
	Input.start_joy_vibration(0, 0.5, 0.25, 0.5)
	
	camera_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(Engine, "time_scale", 0.1, 0.25)
	camera_tween.parallel().tween_property(camera, "global_position", ball.global_position, 0.3)
	camera_tween.parallel().tween_property(camera, "zoom", Vector2(1.5, 1.5), 0.25)
	camera_tween.parallel().tween_property(camera, "rotation_degrees", randf_range(-10, 10), 0.3)
	camera_tween.parallel().tween_property(bw.material, "shader_parameter/mix_val", 1.0, 0.5)
	camera_tween.tween_interval(0.25)
	camera_tween.tween_property(Engine, "time_scale", 1.0, 0.25)
	camera_tween.parallel().tween_property(camera, "global_position", get_viewport_rect().size/2.0, 0.35)
	camera_tween.parallel().tween_property(camera, "zoom", Vector2.ONE, 0.35)
	camera_tween.parallel().tween_property(camera, "rotation_degrees", 0.0, 0.35)
	camera_tween.parallel().tween_property(bw.material, "shader_parameter/mix_val", 0.0, 0.35)
	camera_tween.tween_callback(func(): camera.target = null; camera.dynamic_enabled = true)
	camera_tween.tween_callback(Callable(self, "show_game_over"))
	
######### SIGNALS ###########
func on_brick_destroyed(which) -> void:
	bricks.erase(which)
	bricks_to_destroy.erase(which)
	
	combo += 1
	show_combo(combo)
	score += score_brick_destroyed * combo
	Globals.stats["score"] = score
	score_ui.set_score(score)
	
	if bricks_to_destroy.is_empty():
		started = false
		paddle.stage_clear = true
		Globals.stats["time"] = time
		clear_level_camera_sequence()

func _on_DeathArea_body_entered(body: Node) -> void:
	if not body.is_in_group("Ball"): return
	health -= 1
	health = int(clamp(health, 0, 3))
	
	health_bar.set_health(health)
	
	spawn_laval_splash(body.global_position + Vector2(0, 20))
	body.die()
	paddle.can_move = false
	
	if health == 0:
		paddle.game_over = true
		death_camera_sequence()
		return
		
	reset_and_attach_ball()
	
func show_game_over() -> void:
	var instance = game_over_scene.instantiate()
	ui_canvas_layer.add_child(instance)
	instance.retry.connect(on_game_over_retry)
	
func show_stage_clear() -> void:
	var instance = stage_clear_scene.instantiate()
	ui_canvas_layer.add_child(instance)
	instance.next.connect(on_stage_clear_next)

func _on_ball_hit_block(block) -> void:
	add_energy(block_energy)
	if block._destroyed: return
	combo += 1
	show_combo(combo)
	combo_timer.start()
	score += score_brick_touched * combo
	Globals.stats["score"] = score
	score_ui.set_score(score)

func on_energy_brick_destroyed() -> void:
	add_energy(energy_block_energy)
	
func on_game_over_retry() -> void:
	reset_and_attach_ball()
	reset_health()
	reset_energy()
	reset_score()
	time = 0.0
	Globals.reset_stats()
	remove_all_bricks()
	layout_bricks()

func on_stage_clear_next() -> void:
	reset_and_attach_ball()
	reset_health()
	reset_energy()
	reset_score()
	time = 0.0
	Globals.reset_stats()
	remove_all_bricks()
	layout_bricks()

func _on_combo_timer_timeout():
	combo = 0
	hide_combo()

func _on_paddle_start():
	started = true
