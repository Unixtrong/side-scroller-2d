extends Enemy

enum State {
	IDLE,
	WALK,
	RUNNING,
}

@onready var wall_checker: RayCast2D = $Graphics/WallChecker
@onready var player_checker: RayCast2D = $Graphics/PlayerChecker
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker
@onready var calm_down_timer: Timer = $CalmDownTimer


func tick_physics(state: State, delta: float) -> void:
	match state:
		State.IDLE:
			move(0.0, delta)
		State.WALK:
			move(max_speed * 0.5, delta)
		State.RUNNING:
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				direction *= -1
				velocity.x = 0
			move(max_speed, delta)
			if player_checker.is_colliding():
				calm_down_timer.start()

func get_next_state(state: State) -> State:
	if player_checker.is_colliding():
		return State.RUNNING
	
	match state:
		State.IDLE:
			if state_machine.state_time > 2:
				return State.WALK
		State.WALK:
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				return State.IDLE
		State.RUNNING:
			if calm_down_timer.is_stopped():
				return State.IDLE
	
	return state


# 状态改变时调用
func transition_state(from: State, to: State) -> void:
	print("[%s] %s -> %s" % [
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "<START>",
		State.keys()[to]
	])

	match to:
		State.IDLE:
			animation_player.speed_scale = 1.0
			animation_player.play("idle")
			# 看见墙，转身
			if wall_checker.is_colliding():
				direction *= -1

		State.WALK:
			animation_player.speed_scale = 0.3
			animation_player.play("running")
			# 前面没路，转身
			if not floor_checker.is_colliding():
				direction *= -1
				# is_colliding 在每次每帧开始检测，所以转身后，需要强制再次检测
				floor_checker.force_raycast_update()

		State.RUNNING:
			animation_player.speed_scale = 1.0
			animation_player.play("running")
