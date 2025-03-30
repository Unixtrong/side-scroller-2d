class_name Player
extends CharacterBody2D

enum Direction {
	LEFT = -1,
	RIGHT = 1,
}

enum State {
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING,
	WALL_SLIDING,
	WALL_JUMP,
	ATTACK,
	HURT,
	DYING
}

const GROUND_STATES := [
	State.IDLE, State.RUNNING, State.LANDING,
	State.ATTACK, State.HURT, State.DYING
]
const RUN_SPEED := 200.0
# 地面加速度，0.2 秒加到满速
const FLOOR_ACCELERATION := RUN_SPEED / 0.2
# 空中加速度，0.1 秒加到满速
const AIR_ACCELERATION := RUN_SPEED / 0.1
# 起跳速度
const JUMP_VELOCITY := -360.0
# 蹬墙跳速度向量
const WALL_JUMP_VELOCITY := Vector2(500.0, -240.0)
# 击退速度
const KNOCKBACK_AMOUNT := 384.0

@export var direction := Direction.RIGHT:
	set(v):
		direction = v
		if not is_node_ready():
			await ready
		graphics.scale.x = direction

# 缺省重力加速度
var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float
# 是否当前状态第一帧
var is_first_tick := true
# 待处理伤害
var pending_damage: Damage
# 交互对象组
var interacting_with: Array[Interactable]

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var invincible_timer: Timer = $InvincibleTimer
@onready var reset_world_timer: Timer = $ResetWorldTimer
@onready var hammer_checker: RayCast2D = $Graphics/HammerChecker
@onready var foot_checker: RayCast2D = $Graphics/FootChecker
@onready var state_machine: StateMachine = $StateMachine
@onready var stats: Stats = Game.player_stats
@onready var interaction_icon: AnimatedSprite2D = $InteractionIcon



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	if event.is_action_released("jump"):
		jump_request_timer.stop()
		if velocity.y < JUMP_VELOCITY / 2:
			velocity.y = JUMP_VELOCITY / 2
	if event.is_action_pressed("interact") and not interacting_with.is_empty():
		interacting_with.back().interact()


func tick_physics(state: State, delta: float) -> void:
	interaction_icon.visible = not interacting_with.is_empty()

	if invincible_timer.time_left > 0:
		@warning_ignore("integer_division")
		graphics.modulate.a = sin(Time.get_ticks_msec() / 50) * 0.5 + 0.5
	else:
		graphics.modulate.a = 1

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

		State.HURT, State.DYING:
			stand(default_gravity, delta)

	is_first_tick = false


func move(gravity: float, delta: float) -> void:
	#print("move, gravity: ", gravity, ", delta: ", delta)
	var movement = Input.get_axis("move_left", "move_right")
	var acceleration = FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, movement * RUN_SPEED, acceleration * delta)
	velocity.y += gravity * delta

	if not is_zero_approx(movement):
		direction = Direction.LEFT if movement < 0 else Direction.RIGHT

	move_and_slide()


func stand(gravity: float, delta: float) -> void:
	var acceleration = FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.y += gravity * delta

	move_and_slide()


func register_interactable(v: Interactable) -> void:
	if state_machine.current_state == State.DYING:
		return
	if v in interacting_with:
		return
	interacting_with.append(v)


func unregister_interactable(v: Interactable) -> void:
	interacting_with.erase(v)


func can_wall_slide(direction: float) -> bool:
	return is_on_wall() and not is_zero_approx(direction) and hammer_checker.is_colliding() and foot_checker.is_colliding()

func get_next_state(state: State) -> State:
	if stats.health == 0:
		return State.DYING
	
	if pending_damage:
		return State.HURT

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

		State.HURT:
			if not animation_player.is_playing():
				return State.RUNNING

	return state


# 状态改变时调用
func transition_state(from: State, to: State) -> void:
	print("[%s] %s -> %s" % [
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "<START>",
		State.keys()[to]
	])
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

		State.HURT:
			animation_player.play("hurt")
			# 掉血
			stats.health -= pending_damage.amount
			# 计算击退方向
			var dir := pending_damage.source.global_position.direction_to(global_position)
			print("Player, knockback dir: %s" % [dir])
			# 速度 = 击退方向 x 击退速度常亮
			velocity = dir * KNOCKBACK_AMOUNT
			#velocity.y = 0.0
			invincible_timer.start()

			pending_damage = null

		State.DYING:
			animation_player.play("die")
			invincible_timer.stop()
			interacting_with.clear()
	
	is_first_tick = true


func die() -> void:
	pass


func count_donw_reset_world() -> void:
	reset_world_timer.start()


func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	if invincible_timer.time_left > 0:
		return

	pending_damage = Damage.new()
	pending_damage.amount = 1
	pending_damage.source = hitbox.owner


func _on_reset_world_timer_timeout() -> void:
	Game.player_stats.health = Game.player_stats.max_health
	get_tree().reload_current_scene()
