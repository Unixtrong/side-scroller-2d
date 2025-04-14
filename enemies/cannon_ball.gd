class_name CannonBall
extends Enemy


enum State {
    IN_AIR,
    EXPLODE,
}


func tick_physics(state: State, delta: float) -> void:
    match state:
        State.IN_AIR:
            move(max_speed, delta)
        State.EXPLODE:
            move(0.0, delta)
    print("[cannon_ball] velocity: %s" % [velocity])


func move(speed: float, delta: float) -> void:
    velocity.x = -speed
    velocity.y += default_gravity * delta

    move_and_slide()


func get_next_state(state: State) -> State:
    match state:
        State.IN_AIR:
            if is_on_floor():
                return State.EXPLODE
    return StateMachine.KEEP_CURRENT


func transition_state(from: State, to: State) -> void:
    print("[%s][cannon_ball@%s] %s -> %s" % [
        Engine.get_physics_frames(),
        name,
        State.keys()[from] if from != -1 else "<START>",
        State.keys()[to]
    ])
    
    match to:
        State.IN_AIR:
            animation_player.play("in_air")
        State.EXPLODE:
            audio_hit.play()
            animation_player.play("explode")
            await animation_player.animation_finished
            queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
    queue_free()
