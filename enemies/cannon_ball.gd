class_name CannonBall
extends CharacterBody2D


@export var max_speed := 500.0
@export var acceleration := max_speed / 0.2

var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float


var direction = -1.0

func _process(delta: float) -> void:
    move(max_speed, delta)
    _integrate_forces()


func move(speed: float, delta: float) -> void:
    velocity.x = speed * direction
    velocity.y += default_gravity * 2 * delta

    move_and_slide()


func _integrate_forces():
    if is_on_floor():
        queue_free()  # 命中即销毁，可加粒子爆炸


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
    queue_free()
