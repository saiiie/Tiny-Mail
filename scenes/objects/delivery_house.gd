extends Area2D

var delivered: bool = false

@onready var prompt_label: Label = $Label
@onready var house_sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("set_delivery_target"):
		body.set_delivery_target(self)

		if not delivered:
			prompt_label.text = "Press E to Deliver"
			prompt_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("clear_delivery_target"):
		body.clear_delivery_target(self)

	if not delivered:
		prompt_label.visible = false


func deliver() -> bool:
	if delivered:
		return false

	delivered = true

	prompt_label.text = "Delivered!"
	prompt_label.visible = true

	house_sprite.modulate = Color(0.65, 1.0, 0.65)

	return true
