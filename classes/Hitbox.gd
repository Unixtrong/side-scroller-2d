class_name Hitbox
extends Area2D

signal hit(hurtbox)


func _init() -> void:
    area_entered.connect(_on_area_entered)


# 攻击盒和受击盒交叠
func _on_area_entered(hurtbox: Hurtbox) -> void:
    print("[Hit] %s => %s" % [owner.name, hurtbox.owner.name])
    hit.emit(hurtbox)
    hurtbox.hurt.emit(self)
