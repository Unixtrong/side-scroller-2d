extends Enemy

enum State {
    IDLE,
    ATTENTION,
    ATTACK,
    WALK,
    CHASE,
    RETREAT,
    HURT,
    DYING,
}

signal pig_free

const KNOCKBACK_AMOUNT := 250.0

var pending_damage: Damage
var running_speed_scale := 1.0

var player: Player

@onready var wall_checker: RayCast2D = $Graphics/WallChecker
@onready var player_checker: RayCast2D = $Graphics/PlayerChecker
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker
@onready var hit_check_box: Area2D = $Graphics/HitCheckBox
@onready var calm_down_timer: Timer = $CalmDownTimer
@onready var attack_cd_timer: Timer = $AttackCdTimer
@onready var attention_anim: AnimatedSprite2D = $AttentionAnimation
@onready var audio_die: AudioStreamPlayer = $AudioDie


func _ready() -> void:
    player = get_tree().get_nodes_in_group("player")[0] as Player


func tick_physics(state: State, delta: float) -> void:
    match state:
        State.IDLE, State.ATTENTION, State.ATTACK, State.HURT, State.DYING:
            move(0.0, delta)
        State.WALK:
            move(max_speed * running_speed_scale, delta)
        State.CHASE, State.RETREAT:
            if player:
                chase_player(player.global_position, delta)


func chase_player(player_position, delta):
    # 面向玩家
    if player_position.x > position.x:
        direction = Direction.RIGHT  # 面向右
    else:
        direction = Direction.LEFT  # 面向左

    move(max_speed * running_speed_scale, delta)

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
            # attention 动画结束
            if not attention_anim.is_playing():
                # 如果在攻击范围内，且攻击 CD 结束，进入攻击状态，否则开始追击
                if hit_check_box.is_ready_hit and attack_cd_timer.is_stopped():
                    return State.ATTACK
                else:
                    return State.CHASE
        State.ATTACK:
            if not animation_player.is_playing():
                return State.CHASE
        State.WALK:
            if player_checker.is_colliding():
                return State.ATTENTION
            if wall_checker.is_colliding() or not floor_checker.is_colliding():
                return State.IDLE
        State.CHASE:
            if not player_checker.is_colliding() and calm_down_timer.is_stopped():
                return State.IDLE
            elif hit_check_box.is_ready_hit:
                if attack_cd_timer.is_stopped():
                    # 如果在攻击范围内，且攻击 CD 结束，进入攻击状态
                    return State.ATTACK
                else:
                    # 如果离玩家太近，进入后退状态
                    return State.RETREAT
        State.RETREAT:
            # 如果在攻击范围内，且攻击 CD 结束，进入攻击状态
            if not player_checker.is_colliding() and calm_down_timer.is_stopped():
                return State.IDLE
            elif attack_cd_timer.is_stopped():
                return State.CHASE
        State.HURT:
            if not animation_player.is_playing():
                return State.CHASE
    
    return StateMachine.KEEP_CURRENT


# 状态改变时调用
func transition_state(from: State, to: State) -> void:
    print("[%s][pig] %s -> %s" % [
        Engine.get_physics_frames(),
        State.keys()[from] if from != -1 else "<START>",
        State.keys()[to]
    ])
    
    running_speed_scale = 1.0
    
    match to:
        State.IDLE:
            animation_player.play("idle")
            # 看见墙，转身
            if wall_checker.is_colliding():
                direction *= -1
    
        State.ATTENTION:
            animation_player.play("idle")
            attention_anim.show()
            attention_anim.play("default")
            await attention_anim.animation_finished
            attention_anim.hide()
        
        State.ATTACK:
            animation_player.play("attack")
            attack_cd_timer.start()
        
        State.WALK:
            animation_player.play("running")
            running_speed_scale = 0.5
            # 前面没路，转身
            if not floor_checker.is_colliding():
                direction *= -1
                # is_colliding 在每次每帧开始检测，所以转身后，需要强制再次检测
                floor_checker.force_raycast_update()
        
        State.CHASE:
            animation_player.play("running")
        
        State.RETREAT:
            animation_player.play("running")
            running_speed_scale = -0.6
        
        State.HURT:
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
            animation_player.play("die")
            audio_die.play()
        
    animation_player.speed_scale = running_speed_scale


func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
    pending_damage = Damage.new()
    pending_damage.amount = 1
    pending_damage.source = hitbox.owner


func _on_free_timer_timeout() -> void:
    pig_free.emit()
    super()
