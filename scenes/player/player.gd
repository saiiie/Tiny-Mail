extends CharacterBody2D

@export var speed: float = 220.0

var delivery_target: Area2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var movement_dust: GPUParticles2D = $MovementDust
var normal_sprite_scale: Vector2


func _ready() -> void:
	normal_sprite_scale = sprite.scale


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * speed

	move_and_slide()

	if Input.is_action_just_pressed("deliver") and delivery_target != null:
		if delivery_target.deliver():
			play_delivery_animation()


# Visuals also update after the level disables physics on completion.
func _process(_delta: float) -> void:
	var moving := is_physics_processing() and not velocity.is_zero_approx()
	var animation: StringName = &"idle"
	if moving:
		# Prefer vertical on equal diagonal input; otherwise use the dominant axis.
		if absf(velocity.y) >= absf(velocity.x):
			animation = &"move_down" if velocity.y > 0.0 else &"move_up"
		else:
			animation = &"move_right" if velocity.x > 0.0 else &"move_left"
	if animation_player.current_animation != animation:
		animation_player.play(animation)
	movement_dust.emitting = moving


func set_delivery_target(target: Area2D) -> void:
	delivery_target = target


func clear_delivery_target(target: Area2D) -> void:
	if delivery_target == target:
		delivery_target = null


func play_delivery_animation() -> void:
	var tween := create_tween()

	tween.tween_property(
		sprite,
		"scale",
		normal_sprite_scale * Vector2(1.15, 0.85),
		0.08
	)

	tween.tween_property(
		sprite,
		"scale",
		normal_sprite_scale * Vector2(0.90, 1.10),
		0.08
	)

	tween.tween_property(
		sprite,
		"scale",
		normal_sprite_scale,
		0.10
	)
