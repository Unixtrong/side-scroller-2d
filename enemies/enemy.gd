class_name Enemy
extends CharacterBody2D


enum Direction {
    LEFT = -1,
    RIGHT = 1,
}

@export var direction := Direction.LEFT:
    set(v):
        direction = v
        if not is_node_ready():
            await ready
        graphics.scale.x = -direction

@export var max_speed := 50.0
@export var acceleration := max_speed / 0.2

var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var free_timer: Timer = $FreeTimer
@onready var state_machine: StateMachine = $StateMachine
@onready var stats: Stats = $Stats
@onready var audio_hit: AudioStreamPlayer = $AudioHit

func _process(delta: float) -> void:
    if global_position.y > World.WORLD_BOTTOM:
        print("[Enemy] screen exited, name: %s" % [name])
        queue_free()  # 如果 pig 已经掉出屏幕，清除它


func move(speed: float, delta: float) -> void:
    velocity.x = move_toward(velocity.x, speed * direction, acceleration * delta)
    velocity.y += default_gravity * delta

    move_and_slide()


func count_down_free() -> void:
    free_timer.start()


func _on_free_timer_timeout() -> void:
    queue_free()
