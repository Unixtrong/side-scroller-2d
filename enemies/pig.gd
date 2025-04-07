extends Enemy

enum State {
	IDLE,
	ATTENTION,
	WALK,
	RUNNING,
	HURT,
	DYING,
}

signal pig_free

const KNOCKBACK_AMOUNT := 384.0

var pending_damage: Damage

@onready var wall_checker: RayCast2D = $Graphics/WallChecker
@onready var player_checker: RayCast2D = $Graphics/PlayerChecker
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker
@onready var calm_down_timer: Timer = $CalmDownTimer
@onready var attention_anim: AnimatedSprite2D = $AttentionAnimation
@onready var audio_die: AudioStreamPlayer = $AudioDie


func tick_physics(state: State, delta: float) -> void:
	match state:
		State.IDLE, State.ATTENTION, State.HURT, State.DYING:
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
	if stats.health == 0:
		return StateMachine.KEEP_CURRENT if state == State.DYING else State.DYING
	
	if pending_damage:
		return State.HURT
	
	match state:
		State.IDLE:
			if player_checker.is_colliding():
				return State.ATTENTION
			if state_machine.state_time > 2:
				return State.WALK
		State.ATTENTION:
			if not attention_anim.is_playing():
				return State.RUNNING
		State.WALK:
			if player_checker.is_colliding():
				return State.ATTENTION
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				return State.IDLE
		State.RUNNING:
			if not player_checker.is_colliding() and calm_down_timer.is_stopped():
				return State.IDLE
		State.HURT:
			if not animation_player.is_playing():
				return State.RUNNING
	
	return StateMachine.KEEP_CURRENT


# 状态改变时调用d
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

		State.ATTENTION:
			animation_player.speed_scale = 1.0
			animation_player.play("idle")
			attention_anim.show()
			attention_anim.play("default")
			await attention_anim.animation_finished
			attention_anim.hide()

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

		State.HURT:
			animation_player.speed_scale = 1.0
			animation_player.play("hit")
			audio_hit.play()
			# 掉血
			stats.health -= pending_damage.amount
			# 计算击退方向
			var dir := pending_damage.source.global_position.direction_to(global_position)
			print("knockback dir: %s" % [dir])
			# 速度 = 击退方向 x 击退速度常亮
			velocity = dir * KNOCKBACK_AMOUNT
			velocity.y = 0.0
			# 如果向右击退，则转向左侧；反之，右侧
			if dir.x > 0:
				direction = Direction.LEFT
			else:
				direction = Direction.RIGHT

			pending_damage = null

		State.DYING:
			animation_player.speed_scale = 1.0
			animation_player.play("die")
			audio_die.play()


func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	pending_damage = Damage.new()
	pending_damage.amount = 1
	pending_damage.source = hitbox.owner


func _on_free_timer_timeout() -> void:
	pig_free.emit()
	super()
