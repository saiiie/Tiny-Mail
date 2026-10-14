extends Area2D

signal stepped_in(body: Node2D)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("week3_player"):
		stepped_in.emit(body)
