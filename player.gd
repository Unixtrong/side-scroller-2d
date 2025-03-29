extends CharacterBody2D

enum State {
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING,
	WALL_SLIDING,
	WALL_JUMP,
	ATTACK
}

const GROUND_STATES := [
	State.IDLE, State.RUNNING, State.LANDING, State.ATTACK,
]
const RUN_SPEED := 200.0
const FLOOR_ACCELERATION := RUN_SPEED / 0.2
const AIR_ACCELERATION := RUN_SPEED / 0.1
const JUMP_VELOCITY := -360.0
const WALL_JUMP_VELOCITY := Vector2(500.0, -240.0)

var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float
var is_first_tick := true

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var hammer_checker: RayCast2D = $Graphics/HammerChecker
@onready var foot_checker: RayCast2D = $Graphics/FootChecker
@onready var state_machine: StateMachine = $StateMachine


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	if event.is_action_released("jump"):
		jump_request_timer.stop()
		if velocity.y < JUMP_VELOCITY / 2:
			velocity.y = JUMP_VELOCITY / 2


func tick_physics(state: State, delta: float) -> void:
	match state:
		State.IDLE:
			move(default_gravity, delta)

		State.RUNNING:
			move(default_gravity, delta)

		State.JUMP:
			move(0.0 if is_first_tick else default_gravity, delta)

		State.FALL:
			move(default_gravity, delta)

		State.LANDING:
			pass

		State.WALL_SLIDING: # 滑墙的时候缓慢下降
			move(default_gravity * 0.2, delta)

		State.WALL_JUMP:
			if state_machine.state_time < 0.1:
				stand(0.0 if is_first_tick else default_gravity, delta)
			else:
				move(default_gravity, delta)

		State.ATTACK:
				stand(default_gravity, delta)

	is_first_tick = false


func move(gravity: float, delta: float) -> void:
	#print("move, gravity: ", gravity, ", delta: ", delta)
	var direction = Input.get_axis("move_left", "move_right")
	var acceleration = FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * delta)
	velocity.y += gravity * delta

	if not is_zero_approx(direction):
		graphics.scale.x = -1 if direction < 0 else 1

	move_and_slide()


func stand(gravity: float, delta: float) -> void:
	var acceleration = FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.y += gravity * delta

	move_and_slide()

func can_wall_slide(direction: float) -> bool:
	return is_on_wall() and not is_zero_approx(direction) and hammer_checker.is_colliding() and foot_checker.is_colliding()

func get_next_state(state: State) -> State:
	var can_jump = is_on_floor() or coyote_timer.time_left > 0
	var should_jump = can_jump and jump_request_timer.time_left > 0
	if should_jump:
		return State.JUMP

	if state in GROUND_STATES and not is_on_floor():
		return State.FALL

	var direction = Input.get_axis("move_left", "move_right")
	# 是否站立不动
	var is_still := is_zero_approx(direction) and is_zero_approx(velocity.x)

	match state:
		State.IDLE:
			if Input.is_action_just_pressed("attack"):
				return State.ATTACK
			if not is_still: # 空闲时，没有站立，进入跑步状态
				return State.RUNNING

		State.RUNNING:
			if Input.is_action_just_pressed("attack"):
				return State.ATTACK
			if is_still: # 跑步时，站立，进入空闲状态
				return State.IDLE

		State.JUMP:
			if velocity.y >= 0: # 跳跃时，速度向下，进入坠落状态
				return State.FALL

		State.FALL:
			if is_on_floor():
				return State.LANDING if is_still else State.RUNNING
			if can_wall_slide(direction):
				return State.WALL_SLIDING

		State.LANDING:
			if not animation_player.is_playing():
				return State.IDLE

		State.WALL_SLIDING:
			if jump_request_timer.time_left > 0:
				return State.WALL_JUMP
			if is_on_floor():
				return State.IDLE
			if not is_on_wall() or is_zero_approx(direction):
				return State.FALL

		State.WALL_JUMP:
			if can_wall_slide(direction) and not is_first_tick:
				return State.WALL_SLIDING
			if velocity.y >= 0: # 跳跃时，速度向下，进入坠落状态
				return State.FALL

		State.ATTACK:
			if not animation_player.is_playing():
				return State.IDLE

	return state


# 状态改变时调用
func transition_state(from: State, to: State) -> void:
	#print("[%s] %s -> %s" % [
		#Engine.get_physics_frames(),
		#State.keys()[from] if from != -1 else "<START>",
		#State.keys()[to]
	#])
	if from not in GROUND_STATES and to in GROUND_STATES:
		coyote_timer.stop()

	match to:
		State.IDLE:
			animation_player.play("idle")

		State.RUNNING:
			animation_player.play("running")

		State.JUMP:
			animation_player.play("jump")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
			jump_request_timer.stop()

		State.FALL:
			animation_player.play("fall")
			if from in GROUND_STATES:
				coyote_timer.start()

		State.LANDING:
			animation_player.play("landing")

		State.WALL_SLIDING:
			velocity.y = 0
			animation_player.play("wall_sliding")

		State.WALL_JUMP:
			animation_player.play("jump")
			velocity = WALL_JUMP_VELOCITY
			velocity.x *= get_wall_normal().x
			jump_request_timer.stop()

		State.ATTACK:
			animation_player.play("attack")
	
	is_first_tick = true
