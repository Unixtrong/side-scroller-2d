class_name Stats
extends  Node


signal health_changed

# 最大生命值
@export var max_health: int = 3

@onready var health: int = max_health:
	set(v):
		v = clampi(v, 0, max_health)
		if health == v:
			return
		health = v
		health_changed.emit()
