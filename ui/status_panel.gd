extends HBoxContainer

@export var stats: Stats

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var eased_health_bar: TextureProgressBar = $HealthBar/EasedHealthBar


func _ready() -> void:
	if not stats:
		stats = Game.player_stats
	stats.health_changed.connect(update_health)
	update_health(true)
	
	# 旧版本需要在退出场景树时解除此类检测
	tree_exited.connect(func ():
		stats.health_changed.disconnect(update_health)
	)


func update_health(skip_animation := false) -> void:
	var percentage := stats.health / float(stats.max_health)
	health_bar.value = percentage
	if skip_animation:
		eased_health_bar.value = percentage
	else:
		create_tween().tween_property(eased_health_bar, "value", percentage, 0.6)
