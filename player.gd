extends CharacterBody2D

const RUN_SPEED = 200.0
const ACCELERATION = RUN_SPEED / 0.2
const JUMP_VELOCITY = -360.0

var gravity = ProjectSettings.get("physics/2d/default_gravity") as float

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("jump"):
		jump_request_timer.start()


func _physics_process(delta: float) -> void:
	var direction = Input.get_axis("move_left", "move_right")
	velocity.x = move_toward(velocity.x, direction * RUN_SPEED, ACCELERATION * delta)
	velocity.y += gravity * delta

	var can_jump = is_on_floor() or coyote_timer.time_left > 0
	var should_jump = can_jump and jump_request_timer.time_left > 0
	if should_jump:
		velocity.y = JUMP_VELOCITY
		coyote_timer.stop()
		jump_request_timer.stop()

	if is_on_floor():
		if is_zero_approx(direction) and is_zero_approx(velocity.x):
			animation_player.play("idle")
		else:
			animation_player.play("run")
	else:
		animation_player.play("jump")

	if not is_zero_approx(direction):
		graphics.scale.x = -1 if direction < 0 else 1

	var was_on_floor = is_on_floor()
	move_and_slide()
	if is_on_floor() != was_on_floor:
		if was_on_floor and not should_jump:
			coyote_timer.start()
