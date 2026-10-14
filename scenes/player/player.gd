extends CharacterBody2D

@export var speed: float = 220.0

var delivery_target: Area2D = null

@onready var sprite: Sprite2D = $Sprite2D
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
