extends CharacterBody2D

signal player_touched(body: Node2D)

# The enemy always has exactly one of these two simple behaviors.
enum State { PATROL, CHASE }
@export var patrol_point_a: Node2D
@export var patrol_point_b: Node2D
@export var patrol_speed := 70.0
@export var chase_speed := 140.0

var state: State = State.PATROL
var patrol_index := 1
var chase_target: Node2D = null
var spawn_position: Vector2
var chase_update_remaining := 0.0

@onready var agent: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	spawn_position = global_position
	$DetectionArea.body_entered.connect(_on_detection_entered)
	$DetectionArea.body_exited.connect(_on_detection_exited)
	$ContactArea.body_entered.connect(_on_contact)
	_set_state(State.PATROL)

func _physics_process(delta: float) -> void:
	# Navigation maps synchronize after the scene enters the physics world.
	if NavigationServer2D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		return
	if patrol_point_a == null or patrol_point_b == null:
		velocity = Vector2.ZERO
		return
	var speed := patrol_speed
	if state == State.CHASE:
		if not is_instance_valid(chase_target):
			_set_state(State.PATROL)
		else:
			speed = chase_speed
			# Refresh a moving target every 0.15 seconds, rather than repathing every frame.
			chase_update_remaining -= delta
			if chase_update_remaining <= 0.0:
				agent.target_position = chase_target.global_position
				chase_update_remaining = 0.15
	if state == State.PATROL:
		# Follow A -> B -> A, switching only when the current marker is reached.
		var target := patrol_point_a if patrol_index == 0 else patrol_point_b
		if global_position.distance_to(target.global_position) <= 8.0:
			patrol_index = 1 - patrol_index
			target = patrol_point_a if patrol_index == 0 else patrol_point_b
		if agent.target_position != target.global_position:
			agent.target_position = target.global_position
	# This direction is toward the NEXT PATH POINT, never straight through a hedge.
	var next_position := agent.get_next_path_position()
	velocity = Vector2.ZERO
	if not agent.is_navigation_finished():
		velocity = global_position.direction_to(next_position) * speed
	move_and_slide()
	for index in range(get_slide_collision_count()):
		var body := get_slide_collision(index).get_collider()
		if body is Node2D and body.is_in_group("week3_player"):
			_on_contact(body)

func _set_state(next_state: State) -> void:
	state = next_state
	chase_update_remaining = 0.0
	$StateLabel.text = "CHASE" if state == State.CHASE else "PATROL"

func _on_detection_entered(body: Node2D) -> void:
	# Only the Player triggers pursuit; tile collisions and other bodies are ignored.
	if is_physics_processing() and body.is_in_group("week3_player"):
		chase_target = body
		_set_state(State.CHASE)

func _on_detection_exited(body: Node2D) -> void:
	if body == chase_target:
		chase_target = null
		_set_state(State.PATROL)

func _on_contact(body: Node2D) -> void:
	if is_physics_processing() and body.is_in_group("week3_player"):
		player_touched.emit(body)

func reset_patrol() -> void:
	# Reset with the rabbit so the enemy cannot camp at the safe START point.
	global_position = spawn_position
	velocity = Vector2.ZERO
	chase_target = null
	patrol_index = 1
	_set_state(State.PATROL)
	if patrol_point_b != null:
		agent.target_position = patrol_point_b.global_position

func stop() -> void:
	velocity = Vector2.ZERO
	chase_target = null
	_set_state(State.PATROL)
	set_physics_process(false)
	$DetectionArea.set_deferred("monitoring", false)
	$ContactArea.set_deferred("monitoring", false)
