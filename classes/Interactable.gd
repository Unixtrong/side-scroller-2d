class_name Interactable
extends Area2D


signal interacted

func _init() -> void:
	set_collision_mask_value(2, true)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func interact() -> void:
	print("[Interact] %s" % name)
	interacted.emit()


# 当玩家进入交互范围
func _on_body_entered(player: Player) -> void:
	player.register_interactable(self)


# 当玩家离开交互范围
func _on_body_exited(player: Player) -> void:
	player.unregister_interactable(self)
