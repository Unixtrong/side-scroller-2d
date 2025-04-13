class_name HitCheckBox
extends Area2D

var is_ready_hit := false


func _init() -> void:
    area_entered.connect(_on_area_entered)
    area_exited.connect(_on_area_exit)


# 攻击检测盒和受击盒交叠
func _on_area_entered(hurtbox: Hurtbox) -> void:
    is_ready_hit = true


# 攻击检测盒和受击盒不相交
func _on_area_exit(hurtbox: Hurtbox) -> void:
    is_ready_hit = false
