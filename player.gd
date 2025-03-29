extends CharacterBody2D

const RUN_SPEED = 200.0
const ACCELERATION = RUN_SPEED / 0.2
const JUMP_VELOCITY = -360.0

var gravity = ProjectSettings.get("physics/2d/default_gravity") as float

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _physics_process(delta: float) -> void:
	var direction = Input.get_axis("move_left", "move_right")
	velocity.x = move_toward(velocity.x, direction * RUN_SPEED, ACCELERATION * delta)
	velocity.y += gravity * delta

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	if is_on_floor():
		if is_zero_approx(direction) and is_zero_approx(velocity.x):
			animation_player.play("idle")
		else:
			animation_player.play("run")
	else:
		animation_player.play("jump")

	if not is_zero_approx(direction):
		graphics.scale.x = -1 if direction < 0 else 1

	move_and_slide()
