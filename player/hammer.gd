class_name Hammer
extends Projectile


enum State {
    THROWING,
    RETURNING,
    CATCH,
}


var player: Player
var ghost_timer := 0.0
var ghost_interval := 0.05  # 每 0.05 秒生成一次拖影


@onready var audio_hit: AudioStreamPlayer = $AudioHit
@onready var throw_timer: Timer = $ThrowTimer
@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D


func _ready() -> void:
    player = get_tree().get_nodes_in_group("player")[0] as Player


func tick_physics(state: State, delta: float) -> void:
    if not is_instance_valid(player):
        queue_free()
        return

    ghost_timer += delta
    if ghost_timer >= ghost_interval:
        _spawn_ghost()
        ghost_timer = 0.0

    rotation += 90 * delta

    match state:
        State.THROWING:
            throwing()
        State.RETURNING:
            chase_player(player.global_position, delta)


func get_next_state(state: State) -> State:
    match state:
        State.THROWING:
            if throw_timer.is_stopped():
                return State.RETURNING
        State.RETURNING:
            if _can_catch():
                return State.CATCH
    return StateMachine.KEEP_CURRENT


func transition_state(from: State, to: State) -> void:
    print("[%s][hammer@%s] %s -> %s" % [
        Engine.get_physics_frames(),
        name,
        State.keys()[from] if from != -1 else "<START>",
        State.keys()[to]
    ])

    match to:
        State.THROWING:
            throw_timer.start()
        State.CATCH:
            player.catch_hammer.emit()
            queue_free()
        #State.RETURNING:


func chase_player(player_position, delta) -> void:
    # 面向玩家
    if player_position.x > position.x:
        direction = Direction.RIGHT  # 面向右
    else:
        direction = Direction.LEFT  # 面向左

    var hand_pos := player.hand_mark.global_position
    var dir = (hand_pos - global_position).normalized()
    velocity = dir * max_speed
    move_and_slide()


func throwing() -> void:
    velocity.x = direction * max_speed
    velocity.y = 0
    move_and_slide()


func _can_catch() -> bool:
    return hit_check_box.is_ready_hit


func _spawn_ghost():
    var ghost := Sprite2D.new()
    ghost.texture = sprite_2d.texture
    ghost.global_position = global_position
    ghost.rotation = rotation
    ghost.scale = scale
    ghost.modulate = Color(1, 1, 1, 0.4)  # 半透明

    get_tree().current_scene.add_child(ghost)

    var tween = ghost.create_tween()
    tween.tween_property(ghost, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_LINEAR)
    tween.tween_callback(Callable(ghost, "queue_free"))
