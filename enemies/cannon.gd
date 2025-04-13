extends Enemy


enum State {
    IDLE,
    SHOOT,
}


var player: Player


@onready var cannon_ball := preload("res://enemies/cannon_ball.tscn")
@onready var shoot_cd_timer: Timer = $ShootCdTimer
@onready var shoot_position: Marker2D = $ShootPosition


func _ready() -> void:
    player = get_tree().get_nodes_in_group("player")[0] as Player


func tick_physics(state: State, delta: float) -> void:
    pass


func get_next_state(state: State) -> State:
    match state:
        State.IDLE:
            if _should_shoot():
                return State.SHOOT
        State.SHOOT:
            if not animation_player.is_playing():
                return State.IDLE
    return StateMachine.KEEP_CURRENT


func transition_state(from: State, to: State) -> void:
    print("[%s][cannon@%s] %s -> %s" % [
        Engine.get_physics_frames(),
        name,
        State.keys()[from] if from != -1 else "<START>",
        State.keys()[to]
    ])
    match to:
        State.IDLE:
            animation_player.play("idle")
        State.SHOOT:
            animation_player.play("shoot")
            _shoot()
            shoot_cd_timer.start()


func _should_shoot() -> bool:
    return (
        global_position.x - player.global_position.x < 200 and 
        global_position.x - player.global_position.x > 0
    ) and shoot_cd_timer.is_stopped()


func _shoot() -> void:
    var ball := cannon_ball.instantiate() as CannonBall
    ball.global_position = shoot_position.global_position
    ball.direction = -1

    print("[cannon] shoot, position: %s, dir: %s" % [ball.position, ball.direction])
    get_tree().root.add_child(ball)
