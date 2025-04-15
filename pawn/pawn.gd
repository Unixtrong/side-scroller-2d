class_name Pawn
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
@onready var hit_check_box: HitCheckBox = $Graphics/HitCheckBox
@onready var hitbox: Hitbox = $Graphics/Hitbox
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine
@onready var stats: Stats = $Stats


func move(speed: float, delta: float) -> void:
    velocity.x = move_toward(velocity.x, speed * direction, acceleration * delta)
    velocity.y += default_gravity * delta

    move_and_slide()
